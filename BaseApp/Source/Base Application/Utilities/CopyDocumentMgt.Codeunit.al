// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
#if not CLEAN24
using Microsoft.Service.Contract;
#endif
using System.IO;
using System.Utilities;

codeunit 6620 "Copy Document Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Please enter a Document No.';
        Text001: Label '%1 %2 cannot be copied onto itself.';
        DeleteLinesQst: Label 'The existing lines for %1 %2 will be deleted.\\Do you want to continue?', Comment = '%1=Document type, e.g. Invoice. %2=Document No., e.g. 001';
        Text006: Label 'NOTE: A Payment Discount was Granted by %1 %2.';
        Currency: Record Currency;
        Item: Record Item;
        AsmHeader: Record "Assembly Header";
        PostedAsmHeader: Record "Posted Assembly Header";
        TempAsmHeader: Record "Assembly Header" temporary;
        TempAsmLine: Record "Assembly Line" temporary;
        TempSalesInvLine: Record "Sales Invoice Line" temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        GLSetup: Record "General Ledger Setup";
        TranslationHelper: Codeunit "Translation Helper";
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        ErrorMessageMgt: Codeunit "Error Message Management";
        Window: Dialog;
        HideProcessWindow: Boolean;
        WindowUpdateDateTime: DateTime;
        InsertCancellationLine: Boolean;
        QtyToAsmToOrder: Decimal;
        QtyToAsmToOrderBase: Decimal;
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;
        MoveNegLines: Boolean;
        Text008: Label 'There are no negative sales lines to move.';
        Text009: Label 'NOTE: A Payment Discount was Received by %1 %2.';
        Text010: Label 'There are no negative purchase lines to move.';
        CreateToHeader: Boolean;
        Text011: Label 'Please enter a Vendor No.';
        HideDialog: Boolean;
        Text012: Label 'There are no sales lines to copy.';
        Text013: Label 'Shipment No.,Invoice No.,Return Receipt No.,Credit Memo No.';
        Text014: Label 'Receipt No.,Invoice No.,Return Shipment No.,Credit Memo No.';
        Text015: Label '%1 %2:';
        Text016: Label 'Inv. No. ,Shpt. No. ,Cr. Memo No. ,Rtrn. Rcpt. No. ';
        Text017: Label 'Inv. No. ,Rcpt. No. ,Cr. Memo No. ,Rtrn. Shpt. No. ';
        Text018: Label '%1 - %2:';
        Text019: Label 'Exact Cost Reversing Link has not been created for all copied document lines.';
        Text022: Label 'Copying document lines...\';
        Text023: Label 'Processing source lines      #1######\';
        Text024: Label 'Creating new lines           #2######';
        ExactCostRevMandatory: Boolean;
        ApplyFully: Boolean;
        AskApply: Boolean;
        ReappDone: Boolean;
        Text025: Label 'For one or more return document lines, you chose to return the original quantity, which is already fully applied. Therefore, when you post the return document, the program will reapply relevant entries. Beware that this may change the cost of existing entries. To avoid this, you must delete the affected return document lines before posting.';
        SkippedLine: Boolean;
        Text029: Label 'One or more return document lines were not inserted or they contain only the remaining quantity of the original document line. This is because quantities on the posted document line are already fully or partially applied. If you want to reverse the full quantity, you must select Return Original Quantity before getting the posted document lines.';
        Text030: Label 'One or more return document lines were not copied. This is because quantities on the posted document line are already fully or partially applied, so the Exact Cost Reversing link could not be created.';
        Text031: Label 'Return document line contains only the original document line quantity, that is not already manually applied.';
        SomeAreFixed: Boolean;
        AsmHdrExistsForFromDocLine: Boolean;
        Text032: Label 'The posted sales invoice %1 covers more than one shipment of linked assembly orders that potentially have different assembly components. Select Posted Shipment as document type, and then select a specific shipment of assembled items.';
        FromDocOccurrenceNo: Integer;
        FromDocVersionNo: Integer;
        SkipCopyFromDescription: Boolean;
        SkipTestCreditLimit: Boolean;
        WarningDone: Boolean;
        DiffPostDateOrderQst: Label 'The Posting Date of the copied document is different from the Posting Date of the original document. The original document already has a Posting No. based on a number series with date order. When you post the copied document, you may have the wrong date order in the posted documents.\Do you want to continue?';
        CopyPostedDeferral: Boolean;
        CrMemoCancellationMsg: Label 'Cancellation of credit memo %1.', Comment = '%1 = Document No.';
        CopyExtText: Boolean;
        CopyJobData: Boolean;
        SkipWarningNotification: Boolean;
        SkipOldInvoiceDesc: Boolean;
        IsBlockedErr: Label '%1 %2 is blocked.', Comment = '%1 - type of entity, e.g. Item; %2 - entity''s No.';
        IsSalesBlockedItemErr: Label 'You cannot sell %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Entity Code, %3 - Field Caption';
        IsPurchBlockedItemErr: Label 'You cannot purchase %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (item/variant), %2 - Entity Code, %3 - Field Caption';
        FAIsInactiveErr: Label 'Fixed asset %1 is inactive.', Comment = '%1 - fixed asset no.';
        DirectPostingErr: Label 'G/L account %1 does not allow direct posting.', Comment = '%1 - g/l account no.';
        SalesErrorContextMsg: Label 'Copying sales document %1', Comment = '%1 - document no.';
        PurchErrorContextMsg: Label 'Copying purchase document %1', Comment = '%1 - document no.';

    procedure SetProperties(NewIncludeHeader: Boolean; NewRecalculateLines: Boolean; NewMoveNegLines: Boolean; NewCreateToHeader: Boolean; NewHideDialog: Boolean; NewExactCostRevMandatory: Boolean; NewApplyFully: Boolean)
    begin
        IncludeHeader := NewIncludeHeader;
        RecalculateLines := NewRecalculateLines;
        MoveNegLines := NewMoveNegLines;
        CreateToHeader := NewCreateToHeader;
        HideDialog := NewHideDialog;
        ExactCostRevMandatory := NewExactCostRevMandatory;
        ApplyFully := NewApplyFully;
        AskApply := false;
        ReappDone := false;
        SkippedLine := false;
        SomeAreFixed := false;
        SkipCopyFromDescription := false;
        SkipTestCreditLimit := false;

        OnAfterSetProperties(IncludeHeader, RecalculateLines, MoveNegLines, CreateToHeader, HideDialog, ExactCostRevMandatory, ApplyFully);
    end;

    procedure SetPropertiesForCreditMemoCorrection()
    begin
        SetProperties(true, false, false, false, true, true, false);
    end;

    procedure SetPropertiesForInvoiceCorrection(NewSkipCopyFromDescription: Boolean)
    begin
        SetProperties(true, false, false, false, true, false, false);
        SkipTestCreditLimit := true;
        SkipCopyFromDescription := NewSkipCopyFromDescription;
    end;

    procedure GetSalesDocumentType(FromDocType: Enum "Sales Document Type From") ToDocType: Enum "Sales Document Type"
    begin
        case FromDocType of
            FromDocType::Quote:
                exit("Sales Document Type"::Quote);
            FromDocType::"Blanket Order":
                exit("Sales Document Type"::"Blanket Order");
            FromDocType::Order:
                exit("Sales Document Type"::Order);
            FromDocType::Invoice:
                exit("Sales Document Type"::Invoice);
            FromDocType::"Return Order":
                exit("Sales Document Type"::"Return Order");
            FromDocType::"Credit Memo":
                exit("Sales Document Type"::"Credit Memo");
            FromDocType::"Arch. Quote":
                exit("Sales Document Type"::Quote);
            FromDocType::"Arch. Order":
                exit("Sales Document Type"::Order);
            FromDocType::"Arch. Blanket Order":
                exit("Sales Document Type"::"Blanket Order");
            FromDocType::"Arch. Return Order":
                exit("Sales Document Type"::"Return Order");
            else
                OnGetSalesDocumentTypeCaseElse(FromDocType, ToDocType);
        end;
    end;

    procedure GetPurchaseDocumentType(FromDocType: Enum "Purchase Document Type From") ToDocType: Enum "Purchase Document Type"
    begin
        case FromDocType of
            FromDocType::Quote:
                exit("Purchase Document Type"::Quote);
            FromDocType::"Blanket Order":
                exit("Purchase Document Type"::"Blanket Order");
            FromDocType::Order:
                exit("Purchase Document Type"::Order);
            FromDocType::Invoice:
                exit("Purchase Document Type"::Invoice);
            FromDocType::"Return Order":
                exit("Purchase Document Type"::"Return Order");
            FromDocType::"Credit Memo":
                exit("Purchase Document Type"::"Credit Memo");
            FromDocType::"Arch. Quote":
                exit("Purchase Document Type"::Quote);
            FromDocType::"Arch. Order":
                exit("Purchase Document Type"::Order);
            FromDocType::"Arch. Blanket Order":
                exit("Purchase Document Type"::"Blanket Order");
            FromDocType::"Arch. Return Order":
                exit("Purchase Document Type"::"Return Order");
            else
                OnGetPurchaseDocumentTypeCaseElse(FromDocType, ToDocType);
        end;
    end;

    procedure CopySalesDocForInvoiceCancelling(FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    begin
        CopyJobData := true;
        SkipWarningNotification := true;
        OnBeforeCopySalesDocForInvoiceCancelling(ToSalesHeader, FromDocNo);

        CopySalesDoc("Sales Document Type From"::"Posted Invoice", FromDocNo, ToSalesHeader);
        OnAfterCopySalesDocForInvoiceCancelling(FromDocNo, ToSalesHeader, IncludeHeader, RecalculateLines, MoveNegLines, CreateToHeader, HideDialog, ExactCostRevMandatory, ApplyFully, SkipTestCreditLimit, SkipCopyFromDescription);
    end;

    procedure CopySalesDocForCrMemoCancelling(FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    begin
        CopyJobData := true;
        SkipWarningNotification := true;
        InsertCancellationLine := true;
        OnBeforeCopySalesDocForCrMemoCancelling(ToSalesHeader, FromDocNo, CopyJobData);

        CopySalesDoc("Sales Document Type From"::"Posted Credit Memo", FromDocNo, ToSalesHeader);
        InsertCancellationLine := false;
        OnAfterCopySalesDocForCrMemoCancelling(FromDocNo, ToSalesHeader, IncludeHeader, RecalculateLines, MoveNegLines, CreateToHeader, HideDialog, ExactCostRevMandatory, ApplyFully, SkipTestCreditLimit, SkipCopyFromDescription);
    end;

    procedure CopySalesDoc(FromDocType: Enum "Sales Document Type From"; FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    var
        ToSalesLine: Record "Sales Line";
        FromSalesHeader: Record "Sales Header";
        FromSalesShptHeader: Record "Sales Shipment Header";
        FromSalesInvHeader: Record "Sales Invoice Header";
        FromReturnRcptHeader: Record "Return Receipt Header";
        FromSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FromSalesHeaderArchive: Record "Sales Header Archive";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        ConfirmManagement: Codeunit "Confirm Management";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        NextLineNo: Integer;
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
        ReleaseDocument: Boolean;
        IsHandled: Boolean;
    begin
        if not CreateToHeader then begin
            ToSalesHeader.TestField(Status, ToSalesHeader.Status::Open);
            if FromDocNo = '' then
                Error(Text000);
            ToSalesHeader.Find();
        end;

        IsHandled := false;
        OnBeforeCopySalesDocument(FromDocType.AsInteger(), FromDocNo, ToSalesHeader, IsHandled);
        if IsHandled then
            exit;

        TransferOldExtLines.ClearLineNumbers();

        if not InitAndCheckSalesDocuments(
             FromDocType.AsInteger(), FromDocNo, FromSalesHeader, ToSalesHeader, ToSalesLine,
             FromSalesShptHeader, FromSalesInvHeader, FromReturnRcptHeader, FromSalesCrMemoHeader,
             FromSalesHeaderArchive)
        then
            exit;

        ToSalesLine.LockTable();

        ToSalesLine.SetRange("Document Type", ToSalesHeader."Document Type");
        if CreateToHeader then begin
            OnCopySalesDocOnBeforeToSalesHeaderInsert(ToSalesHeader, FromSalesHeader, MoveNegLines);
            ToSalesHeader.Insert(true);
            ToSalesLine.SetRange("Document No.", ToSalesHeader."No.");
        end else begin
            ToSalesLine.SetRange("Document No.", ToSalesHeader."No.");
            if IncludeHeader then
                if not ToSalesLine.IsEmpty() then begin
                    Commit();
                    IsHandled := false;
                    OnCopySalesDocOnBeforeConfirmDeleteLines(ToSalesHeader, ToSalesLine, IsHandled);
                    if not IsHandled then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(DeleteLinesQst, ToSalesHeader."Document Type", ToSalesHeader."No."), true)
                        then
                            exit;
                    OnCopySalesDocOnBeforeToSalesLineDeleteAll(ToSalesLine);
                    ToSalesLine.DeleteAll(true);
                    OnCopySalesDocOnAfterToSalesLineDeleteAll(ToSalesLine);
                end;
        end;

        if ToSalesLine.FindLast() then
            NextLineNo := ToSalesLine."Line No."
        else
            NextLineNo := 0;

        if IncludeHeader then begin
            CopySalesDocUpdateHeader(
                FromDocType, FromDocNo, ToSalesHeader, FromSalesHeader,
                FromSalesShptHeader, FromSalesInvHeader, FromReturnRcptHeader, FromSalesCrMemoHeader, FromSalesHeaderArchive, ReleaseDocument);
            OnCopySalesDocOnAfterCopySalesDocUpdateHeader(ToSalesHeader, FromSalesInvHeader, FromDocType);
        end else
            OnCopySalesDocWithoutHeader(ToSalesHeader, FromDocType.AsInteger(), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo, FromSalesInvHeader, FromSalesCrMemoHeader);

        LinesNotCopied := 0;
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, ToSalesHeader.RecordId, 0, StrSubstNo(SalesErrorContextMsg, FromDocNo));

        IsHandled := false;
        OnCopySalesDocOnBeforeCopyLines(FromSalesHeader, ToSalesHeader, IsHandled, FromDocType);
        if not IsHandled then
            case FromDocType of
                "Sales Document Type From"::Quote,
                "Sales Document Type From"::"Blanket Order",
                "Sales Document Type From"::Order,
                "Sales Document Type From"::Invoice,
                "Sales Document Type From"::"Return Order",
                "Sales Document Type From"::"Credit Memo":
                    CopySalesDocSalesLine(FromSalesHeader, ToSalesHeader, LinesNotCopied, NextLineNo);
                "Sales Document Type From"::"Posted Shipment":
                    begin
                        FromSalesHeader.TransferFields(FromSalesShptHeader);
                        OnCopySalesDocOnBeforeCopySalesDocShptLine(FromSalesShptHeader, ToSalesHeader);
                        CopySalesDocShptLine(FromSalesShptHeader, ToSalesHeader, LinesNotCopied, MissingExCostRevLink);
                    end;
                "Sales Document Type From"::"Posted Invoice":
                    begin
                        FromSalesHeader.TransferFields(FromSalesInvHeader);
                        OnCopySalesDocOnBeforeCopySalesDocInvLine(FromSalesInvHeader, ToSalesHeader);
                        CopySalesDocInvLine(FromSalesInvHeader, ToSalesHeader, LinesNotCopied, MissingExCostRevLink);
                    end;
                "Sales Document Type From"::"Posted Return Receipt":
                    begin
                        FromSalesHeader.TransferFields(FromReturnRcptHeader);
                        OnCopySalesDocOnBeforeCopySalesDocReturnRcptLine(FromReturnRcptHeader, ToSalesHeader);
                        CopySalesDocReturnRcptLine(FromReturnRcptHeader, ToSalesHeader, LinesNotCopied, MissingExCostRevLink);
                    end;
                "Sales Document Type From"::"Posted Credit Memo":
                    begin
                        FromSalesHeader.TransferFields(FromSalesCrMemoHeader);
                        OnCopySalesDocOnBeforeCopySalesDocCrMemoLine(FromSalesCrMemoHeader, ToSalesHeader);
                        CopySalesDocCrMemoLine(FromSalesCrMemoHeader, ToSalesHeader, LinesNotCopied, MissingExCostRevLink);
                    end;
                "Sales Document Type From"::"Arch. Quote",
                "Sales Document Type From"::"Arch. Order",
                "Sales Document Type From"::"Arch. Blanket Order",
                "Sales Document Type From"::"Arch. Return Order":
                    CopySalesDocSalesLineArchive(FromSalesHeaderArchive, ToSalesHeader, LinesNotCopied, NextLineNo);
            end;

        OnCopySalesDocOnBeforeUpdateSalesInvoiceDiscountValue(
          ToSalesHeader, FromDocType.AsInteger(), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo, RecalculateLines);

        UpdateSalesInvoiceDiscountValue(ToSalesHeader);

        if MoveNegLines then begin
            OnBeforeDeleteNegSalesLines(FromDocType.AsInteger(), FromDocNo, ToSalesHeader);
            DeleteSalesLinesWithNegQty(FromSalesHeader, false);
            LinkJobPlanningLine(ToSalesHeader);
        end;

        OnCopySalesDocOnAfterCopySalesDocLines(
          FromDocType.AsInteger(), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo, FromSalesHeader, IncludeHeader, ToSalesHeader, HideDialog);

        if ReleaseDocument then begin
            ToSalesHeader.Status := ToSalesHeader.Status::Released;
            ReleaseSalesDocument.Reopen(ToSalesHeader);
        end else
            if (FromDocType in
                ["Sales Document Type From"::Quote,
                 "Sales Document Type From"::"Blanket Order",
                 "Sales Document Type From"::Order,
                 "Sales Document Type From"::Invoice,
                 "Sales Document Type From"::"Return Order",
                 "Sales Document Type From"::"Credit Memo"])
               and not IncludeHeader and not RecalculateLines
            then
                if FromSalesHeader.Status = FromSalesHeader.Status::Released then begin
                    ReleaseSalesDocument.SetSkipCheckReleaseRestrictions();
                    ReleaseSalesDocument.Run(ToSalesHeader);
                    ReleaseSalesDocument.Reopen(ToSalesHeader);
                end;

        if ShowWarningNotification(ToSalesHeader, MissingExCostRevLink) then begin
            ErrorMessageHandler.NotifyAboutErrors();
            ErrorMessageMgt.PopContext(ErrorContextElement);
        end;
        OnAfterCopySalesDocument(
          FromDocType.AsInteger(), FromDocNo, ToSalesHeader, FromDocOccurrenceNo, FromDocVersionNo, IncludeHeader, RecalculateLines, MoveNegLines);
    end;

    procedure CopySalesDocSalesLine(FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var LinesNotCopied: Integer; NextLineNo: Integer)
    var
        ToSalesLine: Record "Sales Line";
        FromSalesLine: Record "Sales Line";
        ItemChargeAssgntNextLineNo: Integer;
        ShouldRunIteration: Boolean;
    begin
        OnBeforeCopySalesDocSalesLine(FromSalesHeader, ToSalesHeader);
        ItemChargeAssgntNextLineNo := 0;

        FromSalesLine.Reset();
        FromSalesLine.SetRange("Document Type", FromSalesHeader."Document Type");
        FromSalesLine.SetRange("Document No.", FromSalesHeader."No.");
        if MoveNegLines then
            FromSalesLine.SetFilter(Quantity, '<=0');
        OnCopySalesDocSalesLineOnAfterSetFilters(FromSalesHeader, FromSalesLine, ToSalesHeader, RecalculateLines);
        if FromSalesLine.Find('-') then
            repeat
                ShouldRunIteration := not ExtTxtAttachedToPosSalesLine(FromSalesHeader, MoveNegLines, FromSalesLine);
                OnCopySalesDocSalesLineOnAfterCalcShouldRunIteration(FromSalesHeader, ToSalesHeader, FromSalesLine, ShouldRunIteration);
                if ShouldRunIteration then begin
                    InitAsmCopyHandling(true);
                    ToSalesLine."Document Type" := ToSalesHeader."Document Type";
                    AsmHdrExistsForFromDocLine := FromSalesLine.AsmToOrderExists(AsmHeader);
                    if AsmHdrExistsForFromDocLine then begin
                        case ToSalesLine."Document Type" of
                            ToSalesLine."Document Type"::Order:
                                begin
                                    QtyToAsmToOrder := FromSalesLine."Qty. to Assemble to Order";
                                    QtyToAsmToOrderBase := FromSalesLine."Qty. to Asm. to Order (Base)";
                                end;
                            ToSalesLine."Document Type"::Quote,
                            ToSalesLine."Document Type"::"Blanket Order":
                                begin
                                    QtyToAsmToOrder := FromSalesLine.Quantity;
                                    QtyToAsmToOrderBase := FromSalesLine."Quantity (Base)";
                                end;
                        end;
                        GenerateAsmDataFromNonPosted(AsmHeader);
                    end;
                    if CopySalesDocLine(
                         ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine,
                         NextLineNo, LinesNotCopied, false,
                         ConvertToSalesDocumentTypeFrom(FromSalesHeader."Document Type"),
                         CopyPostedDeferral, FromSalesLine."Line No.")
                    then begin
                        OnCopySalesDocSalesLineOnBeforeCopyFromSalesDocAssgntToLine(FromSalesLine, ToSalesLine, RecalculateLines, NextLineNo);
                        if FromSalesLine.Type = FromSalesLine.Type::"Charge (Item)" then
                            CopyFromSalesDocAssgntToLine(
                              ToSalesLine, FromSalesLine."Document Type", FromSalesLine."Document No.", FromSalesLine."Line No.",
                              ItemChargeAssgntNextLineNo);
                        OnAfterCopySalesLineFromSalesDocSalesLine(
                          ToSalesHeader, ToSalesLine, FromSalesLine, IncludeHeader, RecalculateLines);
                    end;
                end;
                OnCopySalesDocSalesLineOnBeforeFinishSalesDocSalesLine(FromSalesHeader, ToSalesHeader, ToSalesLine, FromSalesLine, RecalculateLines);
            until FromSalesLine.Next() = 0;

        OnAfterCopySalesDocSalesLine(ToSalesLine, TransferOldExtLines, FromSalesHeader, ToSalesHeader);
    end;

    local procedure ConvertToSalesDocumentTypeFrom(SalesDocType: Enum "Sales Document Type") SalesDocTypeFrom: Enum "Sales Document Type From"
    begin
        case SalesDocType of
            SalesDocType::Quote:
                exit(SalesDocTypeFrom::Quote);
            SalesDocType::Order:
                exit(SalesDocTypeFrom::Order);
            SalesDocType::Invoice:
                exit(SalesDocTypeFrom::Invoice);
            SalesDocType::"Credit Memo":
                exit(SalesDocTypeFrom::"Credit Memo");
            SalesDocType::"Blanket Order":
                exit(SalesDocTypeFrom::"Blanket Order");
            SalesDocType::"Return Order":
                exit(SalesDocTypeFrom::"Return Order");
        end;
    end;

    local procedure ConvertToPurchaseDocumentTypeFrom(PurchaseDocType: Enum "Purchase Document Type") PurchaseDocTypeFrom: Enum "Purchase Document Type From"
    begin
        case PurchaseDocType of
            PurchaseDocType::Quote:
                exit(PurchaseDocTypeFrom::Quote);
            PurchaseDocType::Order:
                exit(PurchaseDocTypeFrom::Order);
            PurchaseDocType::Invoice:
                exit(PurchaseDocTypeFrom::Invoice);
            PurchaseDocType::"Credit Memo":
                exit(PurchaseDocTypeFrom::"Credit Memo");
            PurchaseDocType::"Blanket Order":
                exit(PurchaseDocTypeFrom::"Blanket Order");
            PurchaseDocType::"Return Order":
                exit(PurchaseDocTypeFrom::"Return Order");
        end;
    end;

    local procedure CopySalesDocShptLine(FromSalesShptHeader: Record "Sales Shipment Header"; ToSalesHeader: Record "Sales Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromSalesShptLine: Record "Sales Shipment Line";
    begin
        FromSalesShptLine.Reset();
        FromSalesShptLine.SetRange("Document No.", FromSalesShptHeader."No.");
        if MoveNegLines then
            FromSalesShptLine.SetFilter(Quantity, '<=0');
        OnCopySalesDocShptLineOnAfterSetFilters(ToSalesHeader, FromSalesShptHeader, FromSalesShptLine, RecalculateLines);
        CopySalesShptLinesToDoc(ToSalesHeader, FromSalesShptLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopySalesDocInvLine(FromSalesInvHeader: Record "Sales Invoice Header"; ToSalesHeader: Record "Sales Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromSalesInvLine: Record "Sales Invoice Line";
    begin
        FromSalesInvLine.Reset();
        FromSalesInvLine.SetRange("Document No.", FromSalesInvHeader."No.");
        if MoveNegLines then
            FromSalesInvLine.SetFilter(Quantity, '<=0');
        OnCopySalesDocInvLineOnAfterSetFilters(ToSalesHeader, FromSalesInvHeader, FromSalesInvLine, RecalculateLines);
        CopySalesInvLinesToDoc(ToSalesHeader, FromSalesInvLine, LinesNotCopied, MissingExCostRevLink);
        OnAfterCopySalesDocInvLine(FromSalesInvHeader, ToSalesHeader, FromSalesInvLine);
    end;

    local procedure CopySalesDocCrMemoLine(FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; ToSalesHeader: Record "Sales Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        FromSalesCrMemoLine.Reset();
        FromSalesCrMemoLine.SetRange("Document No.", FromSalesCrMemoHeader."No.");
        if MoveNegLines then
            FromSalesCrMemoLine.SetFilter(Quantity, '<=0');
        OnCopySalesDocCrMemoLineOnAfterSetFilters(ToSalesHeader, FromSalesCrMemoHeader, FromSalesCrMemoLine, RecalculateLines);
        CopySalesCrMemoLinesToDoc(ToSalesHeader, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
        OnAfterCopySalesDocCrMemoLine(FromSalesCrMemoHeader, ToSalesHeader, FromSalesCrMemoLine);
    end;

    local procedure CopySalesDocReturnRcptLine(FromReturnRcptHeader: Record "Return Receipt Header"; ToSalesHeader: Record "Sales Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromReturnRcptLine: Record "Return Receipt Line";
    begin
        FromReturnRcptLine.Reset();
        FromReturnRcptLine.SetRange("Document No.", FromReturnRcptHeader."No.");
        if MoveNegLines then
            FromReturnRcptLine.SetFilter(Quantity, '<=0');
        OnCopySalesDocReturnRcptLineOnAfterSetFilters(ToSalesHeader, FromReturnRcptHeader, FromReturnRcptLine);
        CopySalesReturnRcptLinesToDoc(ToSalesHeader, FromReturnRcptLine, LinesNotCopied, MissingExCostRevLink);
    end;

    procedure CopySalesDocSalesLineArchive(FromSalesHeaderArchive: Record "Sales Header Archive"; var ToSalesHeader: Record "Sales Header"; var LinesNotCopied: Integer; NextLineNo: Integer)
    var
        ToSalesLine: Record "Sales Line";
        FromSalesLineArchive: Record "Sales Line Archive";
        ItemChargeAssgntNextLineNo: Integer;
    begin
        OnBeforeCopySalesDocSalesLineArchive(FromSalesHeaderArchive, ToSalesHeader);
        ItemChargeAssgntNextLineNo := 0;

        FromSalesLineArchive.Reset();
        FromSalesLineArchive.SetRange("Document Type", FromSalesHeaderArchive."Document Type");
        FromSalesLineArchive.SetRange("Document No.", FromSalesHeaderArchive."No.");
        FromSalesLineArchive.SetRange("Doc. No. Occurrence", FromSalesHeaderArchive."Doc. No. Occurrence");
        FromSalesLineArchive.SetRange("Version No.", FromSalesHeaderArchive."Version No.");
        if MoveNegLines then
            FromSalesLineArchive.SetFilter(Quantity, '<=0');
        OnCopySalesDocSalesLineArchiveOnAfterSetFilters(FromSalesHeaderArchive, FromSalesLineArchive, ToSalesHeader);
        if FromSalesLineArchive.Find('-') then
            repeat
                if CopyArchSalesLine(
                     ToSalesHeader, ToSalesLine, FromSalesHeaderArchive, FromSalesLineArchive, NextLineNo, LinesNotCopied, false)
                then begin
                    if ToSalesLine."Qty. to Assemble to Order" <> 0 then
                        ToSalesLine.AutoAsmToOrder();
                    CopyFromArchSalesDocDimToLine(ToSalesLine, FromSalesLineArchive);
                    if FromSalesLineArchive.Type = FromSalesLineArchive.Type::"Charge (Item)" then
                        CopyFromSalesDocAssgntToLine(
                          ToSalesLine, FromSalesLineArchive."Document Type", FromSalesLineArchive."Document No.", FromSalesLineArchive."Line No.",
                          ItemChargeAssgntNextLineNo);
                    OnAfterCopyArchSalesLine(ToSalesHeader, ToSalesLine, FromSalesLineArchive, IncludeHeader, RecalculateLines);
                end;
            until FromSalesLineArchive.Next() = 0;
        OnAfterCopySalesDocSalesLineArchive(FromSalesHeaderArchive, ToSalesHeader, ToSalesLine, TransferOldExtLines);
    end;

    procedure CopySalesDocUpdateHeader(FromDocType: Enum "Sales Document Type From"; FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; FromSalesShptHeader: Record "Sales Shipment Header"; FromSalesInvHeader: Record "Sales Invoice Header"; FromReturnRcptHeader: Record "Return Receipt Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; FromSalesHeaderArchive: Record "Sales Header Archive"; var ReleaseDocument: Boolean);
    var
        OldSalesHeader: Record "Sales Header";
        SavedDimSetId: Integer;
        IsHandled: Boolean;
        ShouldValidateDimensionsAndLocation: Boolean;
    begin
        CheckCustomer(FromSalesHeader, ToSalesHeader);
        OldSalesHeader := ToSalesHeader;
        OnBeforeCopySalesHeaderDone(ToSalesHeader, FromSalesHeader, FromDocType, OldSalesHeader, FromSalesShptHeader, FromSalesInvHeader, FromReturnRcptHeader, FromSalesCrMemoHeader, FromSalesHeaderArchive);
        case FromDocType of
            "Sales Document Type From"::Quote,
            "Sales Document Type From"::"Blanket Order",
            "Sales Document Type From"::Order,
            "Sales Document Type From"::Invoice,
            "Sales Document Type From"::"Return Order",
            "Sales Document Type From"::"Credit Memo":
                CopySalesHeaderFromSalesHeader(FromDocType, FromSalesHeader, OldSalesHeader, ToSalesHeader);
            "Sales Document Type From"::"Posted Shipment":
                CopySalesHeaderFromPostedShipment(FromSalesShptHeader, ToSalesHeader, OldSalesHeader);
            "Sales Document Type From"::"Posted Invoice":
                CopySalesHeaderFromPostedInvoice(FromSalesInvHeader, ToSalesHeader, OldSalesHeader);
            "Sales Document Type From"::"Posted Return Receipt":
                CopySalesHeaderFromPostedReturnReceipt(FromReturnRcptHeader, ToSalesHeader, OldSalesHeader);
            "Sales Document Type From"::"Posted Credit Memo":
                TransferFieldsFromCrMemoToInv(ToSalesHeader, FromSalesCrMemoHeader);
            "Sales Document Type From"::"Arch. Quote",
            "Sales Document Type From"::"Arch. Order",
            "Sales Document Type From"::"Arch. Blanket Order",
            "Sales Document Type From"::"Arch. Return Order":
                CopySalesHeaderFromSalesHeaderArchive(FromSalesHeaderArchive, ToSalesHeader, OldSalesHeader);
        end;
        OnAfterCopySalesHeaderDone(
            ToSalesHeader, OldSalesHeader, FromSalesHeader, FromSalesShptHeader, FromSalesInvHeader,
            FromReturnRcptHeader, FromSalesCrMemoHeader, FromSalesHeaderArchive, FromDocType);

        ClearInvoiceAndShip(ToSalesHeader);

        if ToSalesHeader.Status = ToSalesHeader.Status::Released then begin
            ToSalesHeader.Status := ToSalesHeader.Status::Open;
            ReleaseDocument := true;
        end;
        ShouldValidateDimensionsAndLocation := MoveNegLines or IncludeHeader;
        OnCopySalesDocUpdateHeaderOnAfterSetStatusOpen(ToSalesHeader, OldSalesHeader, ShouldValidateDimensionsAndLocation);
        IsHandled := false;
        OnCopySalesDocUpdateHeaderOnBeforeValidateLocationCode(ToSalesHeader, IsHandled);
        if not IsHandled then
            if ShouldValidateDimensionsAndLocation then begin
                SavedDimSetId := ToSalesHeader."Dimension Set ID";
                if not ToSalesHeader.IsCreditDocType() then
                    ToSalesHeader.Validate(ToSalesHeader."Location Code");
                ToSalesHeader.Validate(ToSalesHeader."Dimension Set ID", SavedDimSetId);
            end;
        CopyShiptoCodeFromInvToCrMemo(ToSalesHeader, FromSalesInvHeader, FromDocType);
        CopyFieldsFromOldSalesHeader(ToSalesHeader, OldSalesHeader);
        OnAfterCopyFieldsFromOldSalesHeader(ToSalesHeader, OldSalesHeader, MoveNegLines, IncludeHeader, FromDocType, RecalculateLines);
        if RecalculateLines then begin
            if IncludeHeader then
                SavedDimSetId := ToSalesHeader."Dimension Set ID";
            ToSalesHeader.CreateDimFromDefaultDim(0);
            if IncludeHeader then
                ToSalesHeader."Dimension Set ID" := SavedDimSetId;
        end;

        ToSalesHeader."No. Printed" := 0;
        ToSalesHeader."Applies-to Doc. Type" := ToSalesHeader."Applies-to Doc. Type"::" ";
        ToSalesHeader."Applies-to Doc. No." := '';
        ToSalesHeader."Applies-to ID" := '';
        ToSalesHeader."Opportunity No." := '';
        ToSalesHeader."Quote No." := '';
        OnCopySalesDocUpdateHeaderOnBeforeUpdateCustLedgerEntry(ToSalesHeader, FromDocType.AsInteger(), FromDocNo, OldSalesHeader);

        if ((FromDocType = "Sales Document Type From"::"Posted Invoice") and
            (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::"Return Order", ToSalesHeader."Document Type"::"Credit Memo"])) or
            ((FromDocType = "Sales Document Type From"::"Posted Credit Memo") and
            not (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::"Return Order", ToSalesHeader."Document Type"::"Credit Memo"]))
        then
            UpdateCustLedgerEntry(ToSalesHeader, FromDocType, FromDocNo);

        HandleZeroAmountPostedInvoices(FromSalesInvHeader, ToSalesHeader, FromDocType, FromDocNo);

        if ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::"Blanket Order", ToSalesHeader."Document Type"::Quote] then
            ToSalesHeader."Posting Date" := 0D;

        ToSalesHeader.Correction := false;
        if ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::"Return Order", ToSalesHeader."Document Type"::"Credit Memo"] then
            UpdateSalesCreditMemoHeader(ToSalesHeader);

        GLSetup.Get();
        if GLSetup."Journal Templ. Name Mandatory" then
            if ToSalesHeader.IsCreditDocType() <> IsCreditSalesFromDocType(FromDocType) then
                ToSalesHeader."Journal Templ. Name" := OldSalesHeader."Journal Templ. Name";

        OnBeforeModifySalesHeader(ToSalesHeader, FromDocType.AsInteger(), FromDocNo, IncludeHeader, FromDocOccurrenceNo, FromDocVersionNo, RecalculateLines,
            FromSalesHeader, FromSalesInvHeader, FromSalesCrMemoHeader, OldSalesHeader);

        if CreateToHeader then begin
            ToSalesHeader.Validate(ToSalesHeader."Payment Terms Code");
            ToSalesHeader.Modify(true);
        end else
            ToSalesHeader.Modify();
        OnCopySalesDocWithHeader(FromDocType.AsInteger(), FromDocNo, ToSalesHeader, FromDocOccurrenceNo, FromDocVersionNo, FromSalesHeader);
    end;

    local procedure IsCreditSalesFromDocType(FromDocType: Enum "Sales Document Type From"): Boolean
    begin
        exit(FromDocType in ["Sales Document Type From"::"Return Order", "Sales Document Type From"::"Credit Memo"]);
    end;

    local procedure ClearInvoiceAndShip(var ToSalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearInvoiceAndShip(ToSalesHeader, IsHandled);
        if IsHandled then
            exit;

        ToSalesHeader.Invoice := false;
        ToSalesHeader.Ship := false;
    end;

    local procedure CopySalesHeaderFromSalesHeader(FromDocType: Enum "Sales Document Type From"; FromSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header")
    begin
        FromSalesHeader.CalcFields("Work Description");
        ToSalesHeader.TransferFields(FromSalesHeader, false);
        UpdateSalesHeaderWhenCopyFromSalesHeader(ToSalesHeader, OldSalesHeader, FromDocType);
        SetReceivedFromCountryCode(FromDocType, ToSalesHeader);
        OnAfterCopySalesHeader(ToSalesHeader, OldSalesHeader, FromSalesHeader, FromDocType);
    end;

    local procedure CopySalesHeaderFromPostedShipment(FromSalesShptHeader: Record "Sales Shipment Header"; var ToSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header")
    begin
        FromSalesShptHeader.CalcFields("Work Description");
        ToSalesHeader.Validate("Sell-to Customer No.", FromSalesShptHeader."Sell-to Customer No.");
        OnCopySalesDocOnBeforeTransferPostedShipmentFields(ToSalesHeader, FromSalesShptHeader);
        ToSalesHeader.TransferFields(FromSalesShptHeader, false);
        UpdateShipToAddress(ToSalesHeader);
        SetReceivedFromCountryCode(FromSalesShptHeader, ToSalesHeader);
        OnAfterCopyPostedShipment(ToSalesHeader, OldSalesHeader, FromSalesShptHeader);
    end;

    local procedure CopySalesHeaderFromPostedInvoice(FromSalesInvHeader: Record "Sales Invoice Header"; var ToSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopySalesHeaderFromPostedInvoice(ToSalesHeader, FromSalesInvHeader, IsHandled);
        if not IsHandled then begin
            FromSalesInvHeader.CalcFields("Work Description");
            ToSalesHeader.Validate("Sell-to Customer No.", FromSalesInvHeader."Sell-to Customer No.");
            OnCopySalesDocOnBeforeTransferPostedInvoiceFields(ToSalesHeader, FromSalesInvHeader, CopyJobData);
            ToSalesHeader.TransferFields(FromSalesInvHeader, false);
            UpdateShipToAddress(ToSalesHeader);
            SetReceivedFromCountryCode(FromSalesInvHeader, ToSalesHeader);
            OnCopySalesDocOnAfterTransferPostedInvoiceFields(ToSalesHeader, FromSalesInvHeader, OldSalesHeader);
        end;
    end;

    local procedure CopySalesHeaderFromPostedReturnReceipt(FromReturnRcptHeader: Record "Return Receipt Header"; var ToSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header")
    begin
        ToSalesHeader.Validate("Sell-to Customer No.", FromReturnRcptHeader."Sell-to Customer No.");
        OnCopySalesDocOnBeforeTransferPostedReturnReceiptFields(ToSalesHeader, FromReturnRcptHeader);
        ToSalesHeader.TransferFields(FromReturnRcptHeader, false);
        SetReceivedFromCountryCode(ToSalesHeader);
        OnAfterCopyPostedReturnReceipt(ToSalesHeader, OldSalesHeader, FromReturnRcptHeader);
    end;

    local procedure CopySalesHeaderFromSalesHeaderArchive(FromSalesHeaderArchive: Record "Sales Header Archive"; var ToSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header")
    begin
        FromSalesHeaderArchive.CalcFields("Work Description");
        ToSalesHeader.Validate("Sell-to Customer No.", FromSalesHeaderArchive."Sell-to Customer No.");
        ToSalesHeader.TransferFields(FromSalesHeaderArchive, false);
        OnCopySalesDocOnAfterTransferArchSalesHeaderFields(ToSalesHeader, FromSalesHeaderArchive);
        UpdateSalesHeaderWhenCopyFromSalesHeaderArchive(ToSalesHeader);
        CopyFromArchSalesDocDimToHdr(ToSalesHeader, FromSalesHeaderArchive);
        SetReceivedFromCountryCode(FromSalesHeaderArchive, ToSalesHeader);
        OnAfterCopySalesHeaderArchive(ToSalesHeader, OldSalesHeader, FromSalesHeaderArchive)
    end;

    procedure CheckCustomer(var FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header")
    var
        Cust: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCustomer(FromSalesHeader, ToSalesHeader, IsHandled);
        if IsHandled then
            exit;

        if Cust.Get(FromSalesHeader."Sell-to Customer No.") then
            Cust.CheckBlockedCustOnDocs(Cust, ToSalesHeader."Document Type", false, false);
        if Cust.Get(FromSalesHeader."Bill-to Customer No.") then
            Cust.CheckBlockedCustOnDocs(Cust, ToSalesHeader."Document Type", false, false);
    end;

    local procedure CheckAsmHdrExistsForFromDocLine(ToSalesHeader: Record "Sales Header"; FromSalesLine2: Record "Sales Line"; var BufferCount: Integer; LineCountsEqual: Boolean)
    begin
        BufferCount += 1;
        AsmHdrExistsForFromDocLine := RetrieveSalesInvLine(FromSalesLine2, BufferCount, LineCountsEqual);
        InitAsmCopyHandling(true);
        if AsmHdrExistsForFromDocLine then begin
            AsmHdrExistsForFromDocLine := GetAsmDataFromSalesInvLine(ToSalesHeader."Document Type");
            if AsmHdrExistsForFromDocLine then begin
                QtyToAsmToOrder := TempSalesInvLine.Quantity;
                QtyToAsmToOrderBase := TempSalesInvLine.Quantity * TempSalesInvLine."Qty. per Unit of Measure";
            end;
        end;
    end;

    local procedure HandleZeroAmountPostedInvoices(var FromSalesInvHeader: Record "Sales Invoice Header"; var ToSalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From"; FromDocNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleZeroAmountPostedInvoices(FromSalesInvHeader, ToSalesHeader, FromDocType, FromDocNo, IsHandled);
        if IsHandled then
            exit;

        // Apply credit memo to invoice in case of Sales Invoices with total amount 0
        FromSalesInvHeader.CalcFields(Amount);
        if (ToSalesHeader."Applies-to Doc. Type" = ToSalesHeader."Applies-to Doc. Type"::" ") and (ToSalesHeader."Applies-to Doc. No." = '') and
               (FromDocType = "Sales Document Type From"::"Posted Invoice") and (FromSalesInvHeader.Amount = 0) and
               (ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::"Credit Memo")
            then begin
            ToSalesHeader."Applies-to Doc. Type" := ToSalesHeader."Applies-to Doc. Type"::Invoice;
            ToSalesHeader."Applies-to Doc. No." := FromDocNo;
        end;
    end;

    procedure CopyPurchaseDocForInvoiceCancelling(FromDocNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header")
    begin
        SkipWarningNotification := true;
        OnBeforeCopyPurchaseDocForInvoiceCancelling(ToPurchaseHeader, FromDocNo);

        CopyPurchDoc("Purchase Document Type From"::"Posted Invoice", FromDocNo, ToPurchaseHeader);
    end;

    procedure CopyPurchDocForCrMemoCancelling(FromDocNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header")
    begin
        SkipWarningNotification := true;
        InsertCancellationLine := true;
        OnBeforeCopyPurchaseDocForCrMemoCancelling(ToPurchaseHeader, FromDocNo);

        CopyPurchDoc("Sales Document Type From"::"Posted Credit Memo", FromDocNo, ToPurchaseHeader);
        InsertCancellationLine := false;
    end;

    procedure CopyPurchDoc(FromDocType: Enum "Purchase Document Type From"; FromDocNo: Code[20]; var ToPurchHeader: Record "Purchase Header")
    var
        ToPurchLine: Record "Purchase Line";
        FromPurchHeader: Record "Purchase Header";
        FromPurchRcptHeader: Record "Purch. Rcpt. Header";
        FromPurchInvHeader: Record "Purch. Inv. Header";
        FromReturnShptHeader: Record "Return Shipment Header";
        FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        FromPurchHeaderArchive: Record "Purchase Header Archive";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        ConfirmManagement: Codeunit "Confirm Management";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        NextLineNo: Integer;
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
        ReleaseDocument: Boolean;
        IsHandled: Boolean;
        DoExit: Boolean;
    begin
        if not CreateToHeader then begin
            ToPurchHeader.TestField(Status, ToPurchHeader.Status::Open);
            if FromDocNo = '' then
                Error(Text000);
            ToPurchHeader.Find();
        end;

        IsHandled := false;
        OnBeforeCopyPurchaseDocument(FromDocType.AsInteger(), FromDocNo, ToPurchHeader, IsHandled);
        if IsHandled then
            exit;

        TransferOldExtLines.ClearLineNumbers();

        if not InitAndCheckPurchaseDocuments(
             FromDocType.AsInteger(), FromDocNo, FromPurchHeader, ToPurchHeader,
             FromPurchRcptHeader, FromPurchInvHeader, FromReturnShptHeader, FromPurchCrMemoHeader,
             FromPurchHeaderArchive)
        then
            exit;

        ToPurchLine.LockTable();

        IsHandled := false;
        OnCopyPurchDocOnBeforeCreateOrIncludeHeader(ToPurchHeader, ToPurchLine, CreateToHeader, IncludeHeader, DoExit, IsHandled);
        if IsHandled then
            if DoExit then
                exit;
        if not IsHandled then
            if CreateToHeader then begin
                OnCopyPurchDocOnBeforeToPurchHeaderInsert(ToPurchHeader, FromPurchHeader, MoveNegLines);
                ToPurchHeader.Insert(true);
                ToPurchLine.SetRange("Document Type", ToPurchHeader."Document Type");
                ToPurchLine.SetRange("Document No.", ToPurchHeader."No.");
            end else begin
                ToPurchLine.SetRange("Document Type", ToPurchHeader."Document Type");
                ToPurchLine.SetRange("Document No.", ToPurchHeader."No.");
                if IncludeHeader then
                    if ToPurchLine.FindFirst() then begin
                        Commit();
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(DeleteLinesQst, ToPurchHeader."Document Type", ToPurchHeader."No."), true)
                        then
                            exit;
                        ToPurchLine.DeleteAll(true);
                    end;
            end;

        if ToPurchLine.FindLast() then
            NextLineNo := ToPurchLine."Line No."
        else
            NextLineNo := 0;

        if IncludeHeader then begin
            CopyPurchDocUpdateHeader(
                FromDocType, FromDocNo, ToPurchHeader, FromPurchHeader,
                FromPurchRcptHeader, FromPurchInvHeader, FromReturnShptHeader, FromPurchCrMemoHeader, FromPurchHeaderArchive, ReleaseDocument)
        end else
            OnCopyPurchDocWithoutHeader(ToPurchHeader, FromDocType.AsInteger(), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo, FromPurchInvHeader, FromPurchCrMemoHeader);

        LinesNotCopied := 0;
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, ToPurchHeader.RecordId, 0, StrSubstNo(PurchErrorContextMsg, FromDocNo));
        case FromDocType of
            "Purchase Document Type From"::Quote,
            "Purchase Document Type From"::"Blanket Order",
            "Purchase Document Type From"::Order,
            "Purchase Document Type From"::Invoice,
            "Purchase Document Type From"::"Return Order",
            "Purchase Document Type From"::"Credit Memo":
                CopyPurchDocPurchLine(FromPurchHeader, ToPurchHeader, LinesNotCopied, NextLineNo);
            "Purchase Document Type From"::"Posted Receipt":
                begin
                    FromPurchHeader.TransferFields(FromPurchRcptHeader);
                    OnCopyPurchDocOnBeforeCopyPurchDocRcptLine(FromPurchRcptHeader, ToPurchHeader);
                    CopyPurchDocRcptLine(FromPurchRcptHeader, ToPurchHeader, LinesNotCopied, MissingExCostRevLink);
                end;
            "Purchase Document Type From"::"Posted Invoice":
                begin
                    FromPurchHeader.TransferFields(FromPurchInvHeader);
                    OnCopyPurchDocOnBeforeCopyPurchDocInvLine(FromPurchInvHeader, ToPurchHeader);
                    CopyPurchDocInvLine(FromPurchInvHeader, ToPurchHeader, LinesNotCopied, MissingExCostRevLink);
                end;
            "Purchase Document Type From"::"Posted Return Shipment":
                begin
                    FromPurchHeader.TransferFields(FromReturnShptHeader);
                    OnCopyPurchDocOnBeforeCopyPurchDocReturnShptLine(FromReturnShptHeader, ToPurchHeader);
                    CopyPurchDocReturnShptLine(FromReturnShptHeader, ToPurchHeader, LinesNotCopied, MissingExCostRevLink);
                end;
            "Purchase Document Type From"::"Posted Credit Memo":
                begin
                    FromPurchHeader.TransferFields(FromPurchCrMemoHeader);
                    OnCopyPurchDocOnBeforeCopyPurchDocCrMemoLine(FromPurchCrMemoHeader, ToPurchHeader);
                    CopyPurchDocCrMemoLine(FromPurchCrMemoHeader, ToPurchHeader, LinesNotCopied, MissingExCostRevLink);
                end;
            "Purchase Document Type From"::"Arch. Order",
            "Purchase Document Type From"::"Arch. Quote",
            "Purchase Document Type From"::"Arch. Blanket Order",
            "Purchase Document Type From"::"Arch. Return Order":
                CopyPurchDocPurchLineArchive(FromPurchHeaderArchive, ToPurchHeader, LinesNotCopied, NextLineNo);
        end;

        OnCopyPurchDocOnBeforeUpdatePurchInvoiceDiscountValue(
          ToPurchHeader, FromDocType.AsInteger(), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo, RecalculateLines, FromPurchHeader, LinesNotCopied, NextLineNo, MissingExCostRevLink);

        UpdatePurchaseInvoiceDiscountValue(ToPurchHeader);

        if MoveNegLines then
            DeletePurchLinesWithNegQty(FromPurchHeader, false);

        OnCopyPurchDocOnAfterCopyPurchDocLines(FromDocType.AsInteger(), FromDocNo, FromPurchHeader, IncludeHeader, ToPurchHeader, MoveNegLines);

        if ReleaseDocument then begin
            ToPurchHeader.Status := ToPurchHeader.Status::Released;
            ReleasePurchaseDocument.Reopen(ToPurchHeader);
        end else
            if (FromDocType in
                ["Purchase Document Type From"::Quote,
                 "Purchase Document Type From"::"Blanket Order",
                 "Purchase Document Type From"::Order,
                 "Purchase Document Type From"::Invoice,
                 "Purchase Document Type From"::"Return Order",
                 "Purchase Document Type From"::"Credit Memo"])
               and not IncludeHeader and not RecalculateLines
            then
                if FromPurchHeader.Status = FromPurchHeader.Status::Released then begin
                    ReleasePurchaseDocument.SetSkipCheckReleaseRestrictions();
                    ReleasePurchaseDocument.Run(ToPurchHeader);
                    ReleasePurchaseDocument.Reopen(ToPurchHeader);
                end;

        if ShowWarningNotification(ToPurchHeader, MissingExCostRevLink) then begin
            ErrorMessageHandler.NotifyAboutErrors();
            ErrorMessageMgt.PopContext(ErrorContextElement);
        end;

        OnAfterCopyPurchaseDocument(
          FromDocType.AsInteger(), FromDocNo, ToPurchHeader, FromDocOccurrenceNo, FromDocVersionNo, IncludeHeader, RecalculateLines, MoveNegLines);
    end;

    procedure CopyPurchDocPurchLine(FromPurchHeader: Record "Purchase Header"; ToPurchHeader: Record "Purchase Header"; var LinesNotCopied: Integer; NextLineNo: Integer)
    var
        ToPurchLine: Record "Purchase Line";
        FromPurchLine: Record "Purchase Line";
        ItemChargeAssgntNextLineNo: Integer;
    begin
        ItemChargeAssgntNextLineNo := 0;

        FromPurchLine.Reset();
        FromPurchLine.SetRange("Document Type", FromPurchHeader."Document Type");
        FromPurchLine.SetRange("Document No.", FromPurchHeader."No.");
        if MoveNegLines then
            FromPurchLine.SetFilter(Quantity, '<=0');
        OnCopyPurchDocPurchLineOnAfterSetFilters(FromPurchHeader, FromPurchLine, ToPurchHeader, RecalculateLines);
        if FromPurchLine.Find('-') then
            repeat
                if not ExtTxtAttachedToPosPurchLine(FromPurchHeader, MoveNegLines, FromPurchLine) then
                    if CopyPurchDocLine(
                         ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, NextLineNo, LinesNotCopied, false,
                         ConvertToPurchaseDocumentTypeFrom(FromPurchHeader."Document Type"),
                         CopyPostedDeferral, FromPurchLine."Line No.")
                    then begin
                        if FromPurchLine.Type = FromPurchLine.Type::"Charge (Item)" then
                            CopyFromPurchDocAssgntToLine(
                                ToPurchLine, FromPurchLine."Document Type", FromPurchLine."Document No.", FromPurchLine."Line No.",
                                ItemChargeAssgntNextLineNo);
                        OnCopyPurchDocPurchLineOnAfterCopyPurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, IncludeHeader, RecalculateLines);
                    end;
                OnCopyPurchDocPurchLineOnAfterProcessFromPurchLineInLoop(ToPurchHeader, ToPurchLine, FromPurchLine, RecalculateLines);
            until FromPurchLine.Next() = 0;
    end;

    local procedure CopyPurchDocRcptLine(FromPurchRcptHeader: Record "Purch. Rcpt. Header"; ToPurchHeader: Record "Purchase Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        FromPurchRcptLine.Reset();
        FromPurchRcptLine.SetRange("Document No.", FromPurchRcptHeader."No.");
        if MoveNegLines then
            FromPurchRcptLine.SetFilter(Quantity, '<=0');
        OnCopyPurchDocRcptLineOnAfterSetFilters(ToPurchHeader, FromPurchRcptHeader, FromPurchRcptLine, RecalculateLines);
        CopyPurchRcptLinesToDoc(ToPurchHeader, FromPurchRcptLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopyPurchDocInvLine(FromPurchInvHeader: Record "Purch. Inv. Header"; ToPurchHeader: Record "Purchase Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromPurchInvLine: Record "Purch. Inv. Line";
    begin
        FromPurchInvLine.Reset();
        FromPurchInvLine.SetRange("Document No.", FromPurchInvHeader."No.");
        if MoveNegLines then
            FromPurchInvLine.SetFilter(Quantity, '<=0');
        OnCopyPurchDocInvLineOnAfterSetFilters(ToPurchHeader, FromPurchInvLine, LinesNotCopied, MissingExCostRevLink, RecalculateLines);
        CopyPurchInvLinesToDoc(ToPurchHeader, FromPurchInvLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopyPurchDocCrMemoLine(FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; ToPurchHeader: Record "Purchase Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        FromPurchCrMemoLine.Reset();
        FromPurchCrMemoLine.SetRange("Document No.", FromPurchCrMemoHeader."No.");
        if MoveNegLines then
            FromPurchCrMemoLine.SetFilter(Quantity, '<=0');
        OnCopyPurchDocCrMemoLineOnAfterSetFilters(ToPurchHeader, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink, RecalculateLines);
        CopyPurchCrMemoLinesToDoc(ToPurchHeader, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopyPurchDocReturnShptLine(FromReturnShptHeader: Record "Return Shipment Header"; ToPurchHeader: Record "Purchase Header"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        FromReturnShptLine: Record "Return Shipment Line";
    begin
        FromReturnShptLine.Reset();
        FromReturnShptLine.SetRange("Document No.", FromReturnShptHeader."No.");
        if MoveNegLines then
            FromReturnShptLine.SetFilter(Quantity, '<=0');
        OnCopyPurchDocReturnShptLineOnAfterSetFilters(ToPurchHeader, FromReturnShptLine, LinesNotCopied, MissingExCostRevLink);
        CopyPurchReturnShptLinesToDoc(ToPurchHeader, FromReturnShptLine, LinesNotCopied, MissingExCostRevLink);
    end;

    procedure CopyPurchDocPurchLineArchive(FromPurchHeaderArchive: Record "Purchase Header Archive"; var ToPurchHeader: Record "Purchase Header"; var LinesNotCopied: Integer; NextLineNo: Integer)
    var
        ToPurchLine: Record "Purchase Line";
        FromPurchLineArchive: Record "Purchase Line Archive";
        ItemChargeAssgntNextLineNo: Integer;
    begin
        ItemChargeAssgntNextLineNo := 0;

        FromPurchLineArchive.Reset();
        FromPurchLineArchive.SetRange("Document Type", FromPurchHeaderArchive."Document Type");
        FromPurchLineArchive.SetRange("Document No.", FromPurchHeaderArchive."No.");
        FromPurchLineArchive.SetRange("Doc. No. Occurrence", FromPurchHeaderArchive."Doc. No. Occurrence");
        FromPurchLineArchive.SetRange("Version No.", FromPurchHeaderArchive."Version No.");
        if MoveNegLines then
            FromPurchLineArchive.SetFilter(Quantity, '<=0');
        OnCopyPurchDocPurchLineArchiveOnAfterSetFilters(ToPurchHeader, ToPurchLine, FromPurchHeaderArchive, FromPurchLineArchive, NextLineNo, LinesNotCopied);
        if FromPurchLineArchive.Find('-') then
            repeat
                if CopyArchPurchLine(
                     ToPurchHeader, ToPurchLine, FromPurchHeaderArchive, FromPurchLineArchive, NextLineNo, LinesNotCopied, false)
                then begin
                    CopyFromArchPurchDocDimToLine(ToPurchLine, FromPurchLineArchive);
                    if FromPurchLineArchive.Type = FromPurchLineArchive.Type::"Charge (Item)" then
                        CopyFromPurchDocAssgntToLine(
                          ToPurchLine, FromPurchLineArchive."Document Type", FromPurchLineArchive."Document No.", FromPurchLineArchive."Line No.",
                          ItemChargeAssgntNextLineNo);
                    OnAfterCopyArchPurchLine(ToPurchHeader, ToPurchLine, FromPurchLineArchive, IncludeHeader, RecalculateLines);
                end;
            until FromPurchLineArchive.Next() = 0;
    end;

    local procedure CopyPurchDocUpdateHeader(FromDocType: Enum "Purchase Document Type From"; FromDocNo: Code[20]; var ToPurchHeader: Record "Purchase Header"; FromPurchHeader: Record "Purchase Header"; FromPurchRcptHeader: Record "Purch. Rcpt. Header"; FromPurchInvHeader: Record "Purch. Inv. Header"; FromReturnShptHeader: Record "Return Shipment Header"; FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; FromPurchHeaderArchive: Record "Purchase Header Archive"; var ReleaseDocument: Boolean)
    var
        Vend: Record Vendor;
        OldPurchHeader: Record "Purchase Header";
        SavedDimSetId: Integer;
    begin
        if Vend.Get(FromPurchHeader."Buy-from Vendor No.") then
            Vend.CheckBlockedVendOnDocs(Vend, false);
        if Vend.Get(FromPurchHeader."Pay-to Vendor No.") then
            Vend.CheckBlockedVendOnDocs(Vend, false);
        OldPurchHeader := ToPurchHeader;
        OnBeforeCopyPurchHeaderDone(ToPurchHeader, FromPurchHeader, FromDocType, OldPurchHeader, FromPurchRcptHeader, FromPurchInvHeader, FromReturnShptHeader, FromPurchCrMemoHeader, FromPurchHeaderArchive);
        case FromDocType of
            "Purchase Document Type From"::Quote,
            "Purchase Document Type From"::"Blanket Order",
            "Purchase Document Type From"::Order,
            "Purchase Document Type From"::Invoice,
            "Purchase Document Type From"::"Return Order",
            "Purchase Document Type From"::"Credit Memo":
                CopyPurchHeaderFromPurchHeader(FromDocType, FromPurchHeader, OldPurchHeader, ToPurchHeader);
            "Purchase Document Type From"::"Posted Receipt":
                CopyPurchHeaderFromPostedReceipt(FromPurchRcptHeader, ToPurchHeader, OldPurchHeader);
            "Purchase Document Type From"::"Posted Invoice":
                CopyPurchHeaderFromPostedInvoice(FromPurchInvHeader, ToPurchHeader, OldPurchHeader);
            "Purchase Document Type From"::"Posted Return Shipment":
                CopyPurchHeaderFromPostedReturnShipment(FromReturnShptHeader, ToPurchHeader, OldPurchHeader);
            "Purchase Document Type From"::"Posted Credit Memo":
                CopyPurchHeaderFromPostedCreditMemo(FromPurchCrMemoHeader, ToPurchHeader, OldPurchHeader);
            "Purchase Document Type From"::"Arch. Order",
            "Purchase Document Type From"::"Arch. Quote",
            "Purchase Document Type From"::"Arch. Blanket Order",
            "Purchase Document Type From"::"Arch. Return Order":
                CopyPurchHeaderFromPurchHeaderArchive(FromPurchHeaderArchive, ToPurchHeader, OldPurchHeader);
        end;
        OnAfterCopyPurchHeaderDone(
            ToPurchHeader, OldPurchHeader, FromPurchHeader, FromPurchRcptHeader, FromPurchInvHeader,
            FromReturnShptHeader, FromPurchCrMemoHeader, FromPurchHeaderArchive);

        ToPurchHeader.Invoice := false;
        ToPurchHeader.Receive := false;
        if ToPurchHeader.Status = ToPurchHeader.Status::Released then begin
            ToPurchHeader.Status := ToPurchHeader.Status::Open;
            ReleaseDocument := true;
        end;
        if MoveNegLines or IncludeHeader then begin
            SavedDimSetId := ToPurchHeader."Dimension Set ID";
            ToPurchHeader.Validate(ToPurchHeader."Location Code");
            ToPurchHeader.Validate(ToPurchHeader."Dimension Set ID", SavedDimSetId);
            CopyShippingInfoPurchOrder(ToPurchHeader, FromPurchHeader);
        end;
        if MoveNegLines then
            ToPurchHeader.Validate(ToPurchHeader."Order Address Code");

        CopyFieldsFromOldPurchHeader(ToPurchHeader, OldPurchHeader);
        OnAfterCopyFieldsFromOldPurchHeader(ToPurchHeader, OldPurchHeader, MoveNegLines, IncludeHeader);
        if RecalculateLines then begin
            if IncludeHeader then
                SavedDimSetId := ToPurchHeader."Dimension Set ID";
            ToPurchHeader.CreateDimFromDefaultDim(0);
            if IncludeHeader then
                ToPurchHeader."Dimension Set ID" := SavedDimSetId;
        end;
        ToPurchHeader."No. Printed" := 0;
        ToPurchHeader."Applies-to Doc. Type" := ToPurchHeader."Applies-to Doc. Type"::" ";
        ToPurchHeader."Applies-to Doc. No." := '';
        ToPurchHeader."Applies-to ID" := '';
        ToPurchHeader."Quote No." := '';
        OnCopyPurchDocUpdateHeaderOnBeforeUpdateVendLedgerEntry(ToPurchHeader, FromDocType.AsInteger(), FromDocNo);

        if ((FromDocType = "Purchase Document Type From"::"Posted Invoice") and
            (ToPurchHeader."Document Type" in [ToPurchHeader."Document Type"::"Return Order", ToPurchHeader."Document Type"::"Credit Memo"])) or
            ((FromDocType = "Purchase Document Type From"::"Posted Credit Memo") and
            not (ToPurchHeader."Document Type" in [ToPurchHeader."Document Type"::"Return Order", ToPurchHeader."Document Type"::"Credit Memo"]))
        then
            UpdateVendLedgEntry(ToPurchHeader, FromDocType, FromDocNo);

        if ToPurchHeader."Document Type" in [ToPurchHeader."Document Type"::"Blanket Order", ToPurchHeader."Document Type"::Quote] then
            ToPurchHeader."Posting Date" := 0D;

        ToPurchHeader.Correction := false;
        if ToPurchHeader."Document Type" in [ToPurchHeader."Document Type"::"Return Order", ToPurchHeader."Document Type"::"Credit Memo"] then
            UpdatePurchCreditMemoHeader(ToPurchHeader);

        GLSetup.Get();
        if GLSetup."Journal Templ. Name Mandatory" then
            if ToPurchHeader.IsCreditDocType() <> IsCreditPurchFromDocType(FromDocType) then
                ToPurchHeader."Journal Templ. Name" := OldPurchHeader."Journal Templ. Name";

        OnBeforeModifyPurchHeader(ToPurchHeader, FromDocType.AsInteger(), FromDocNo, IncludeHeader, FromDocOccurrenceNo, FromDocVersionNo, RecalculateLines,
            FromPurchHeader, FromPurchInvHeader, FromPurchCrMemoHeader, OldPurchHeader);

        if CreateToHeader then begin
            ToPurchHeader.Validate(ToPurchHeader."Payment Terms Code");
            ToPurchHeader.Modify(true);
        end else
            ToPurchHeader.Modify();

        OnCopyPurchDocWithHeader(FromDocType.AsInteger(), FromDocNo, ToPurchHeader, FromDocOccurrenceNo, FromDocVersionNo);
    end;

    local procedure IsCreditPurchFromDocType(FromDocType: Enum "Purchase Document Type From"): Boolean
    begin
        exit(FromDocType in ["Purchase Document Type From"::"Return Order", "Purchase Document Type From"::"Credit Memo"]);
    end;

    local procedure CopyPurchHeaderFromPurchHeader(FromDocType: Enum "Purchase Document Type From"; FromPurchHeader: Record "Purchase Header"; OldPurchHeader: Record "Purchase Header"; var ToPurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyPurchHeaderFromPurchHeader(FromDocType, FromPurchHeader, OldPurchHeader, ToPurchHeader, IsHandled);
        if IsHandled then
            exit;

        ToPurchHeader.TransferFields(FromPurchHeader, false);
        UpdatePurchHeaderWhenCopyFromPurchHeader(ToPurchHeader, OldPurchHeader, FromDocType);
        OnAfterCopyPurchaseHeader(ToPurchHeader, OldPurchHeader, FromPurchHeader);
    end;

    local procedure CopyPurchHeaderFromPostedReceipt(FromPurchRcptHeader: Record "Purch. Rcpt. Header"; var ToPurchHeader: Record "Purchase Header"; var OldPurchHeader: Record "Purchase Header")
    begin
        ToPurchHeader.Validate("Buy-from Vendor No.", FromPurchRcptHeader."Buy-from Vendor No.");
        OnCopyPurchHeaderFromPostedReceiptOnBeforeTransferFields(ToPurchHeader, OldPurchHeader, FromPurchRcptHeader);
        ToPurchHeader.TransferFields(FromPurchRcptHeader, false);
        OnAfterCopyPostedReceipt(ToPurchHeader, OldPurchHeader, FromPurchRcptHeader);
    end;

    local procedure CopyPurchHeaderFromPostedInvoice(FromPurchInvHeader: Record "Purch. Inv. Header"; var ToPurchHeader: Record "Purchase Header"; var OldPurchHeader: Record "Purchase Header")
    begin
        ToPurchHeader.Validate("Buy-from Vendor No.", FromPurchInvHeader."Buy-from Vendor No.");
        FromPurchInvHeader.CalcFields("Amount Including VAT", Amount);
        ToPurchHeader.Validate("Doc. Amount Incl. VAT", FromPurchInvHeader."Amount Including VAT");
        ToPurchHeader.Validate("Doc. Amount VAT", FromPurchInvHeader."Amount Including VAT" - FromPurchInvHeader.Amount);
        OnCopyPurchHeaderFromPostedInvoiceOnBeforeTransferFields(ToPurchHeader, OldPurchHeader, FromPurchInvHeader);
        ToPurchHeader.TransferFields(FromPurchInvHeader, false);
        OnAfterCopyPostedPurchInvoice(ToPurchHeader, OldPurchHeader, FromPurchInvHeader);
    end;

    local procedure CopyPurchHeaderFromPostedReturnShipment(FromReturnShptHeader: Record "Return Shipment Header"; var ToPurchHeader: Record "Purchase Header"; var OldPurchHeader: Record "Purchase Header")
    begin
        ToPurchHeader.Validate("Buy-from Vendor No.", FromReturnShptHeader."Buy-from Vendor No.");
        OnCopyPurchHeaderFromPostedReturnShipmentOnBeforeTransferFields(ToPurchHeader, OldPurchHeader, FromReturnShptHeader);
        ToPurchHeader.TransferFields(FromReturnShptHeader, false);
        OnAfterCopyPostedReturnShipment(ToPurchHeader, OldPurchHeader, FromReturnShptHeader);
    end;

    local procedure CopyPurchHeaderFromPostedCreditMemo(FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var ToPurchHeader: Record "Purchase Header"; var OldPurchHeader: Record "Purchase Header")
    begin
        ToPurchHeader.Validate("Buy-from Vendor No.", FromPurchCrMemoHeader."Buy-from Vendor No.");
        OnCopyPurchHeaderFromPostedCreditMemoOnBeforeTransferFields(ToPurchHeader, OldPurchHeader, FromPurchCrMemoHeader);
        ToPurchHeader.TransferFields(FromPurchCrMemoHeader, false);
        OnAfterCopyPurchHeaderFromPostedCreditMemo(ToPurchHeader, OldPurchHeader, FromPurchCrMemoHeader);
    end;

    local procedure CopyPurchHeaderFromPurchHeaderArchive(FromPurchHeaderArchive: Record "Purchase Header Archive"; var ToPurchHeader: Record "Purchase Header"; var OldPurchHeader: Record "Purchase Header")
    begin
        ToPurchHeader.Validate("Buy-from Vendor No.", FromPurchHeaderArchive."Buy-from Vendor No.");
        ToPurchHeader.TransferFields(FromPurchHeaderArchive, false);
        UpdatePurchHeaderWhenCopyFromPurchHeaderArchive(ToPurchHeader);
        CopyFromArchPurchDocDimToHdr(ToPurchHeader, FromPurchHeaderArchive);
        OnAfterCopyPurchHeaderArchive(ToPurchHeader, OldPurchHeader, FromPurchHeaderArchive)
    end;

    procedure ShowSalesDoc(ToSalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowSalesDoc(ToSalesHeader, IsHandled);
        if IsHandled then
            exit;

        case ToSalesHeader."Document Type" of
            ToSalesHeader."Document Type"::Order:
                PAGE.Run(PAGE::"Sales Order", ToSalesHeader);
            ToSalesHeader."Document Type"::Invoice:
                PAGE.Run(PAGE::"Sales Invoice", ToSalesHeader);
            ToSalesHeader."Document Type"::"Return Order":
                PAGE.Run(PAGE::"Sales Return Order", ToSalesHeader);
            ToSalesHeader."Document Type"::"Credit Memo":
                PAGE.Run(PAGE::"Sales Credit Memo", ToSalesHeader);
        end;
    end;

    procedure ShowPurchDoc(ToPurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowPurchDoc(ToPurchHeader, IsHandled);
        if IsHandled then
            exit;

        case ToPurchHeader."Document Type" of
            ToPurchHeader."Document Type"::Order:
                PAGE.Run(PAGE::"Purchase Order", ToPurchHeader);
            ToPurchHeader."Document Type"::Invoice:
                PAGE.Run(PAGE::"Purchase Invoice", ToPurchHeader);
            ToPurchHeader."Document Type"::"Return Order":
                PAGE.Run(PAGE::"Purchase Return Order", ToPurchHeader);
            ToPurchHeader."Document Type"::"Credit Memo":
                PAGE.Run(PAGE::"Purchase Credit Memo", ToPurchHeader);
        end;
    end;

    local procedure ShowWarningNotification(SourceVariant: Variant; MissingExCostRevLink: Boolean): Boolean
    var
        TempErrorMessage: Record "Error Message" temporary;
    begin
        if MissingExCostRevLink then
            ErrorMessageMgt.LogWarning(0, Text019, SourceVariant, 0, '');

        if ErrorMessageMgt.GetErrors(TempErrorMessage) then begin
            TempErrorMessage.SetRange("Message Type", TempErrorMessage."Message Type"::Error);
            if TempErrorMessage.FindFirst() then begin
                if SkipWarningNotification then
                    Error(TempErrorMessage."Message");
                exit(true);
            end;
            exit(not SkipWarningNotification);
        end;
    end;

    procedure CopyFromSalesToPurchDoc(VendorNo: Code[20]; FromSalesHeader: Record "Sales Header"; var ToPurchHeader: Record "Purchase Header")
    var
        FromSalesLine: Record "Sales Line";
        ToPurchLine: Record "Purchase Line";
        NextLineNo: Integer;
        ShouldCopyItemTracking: Boolean;
    begin
        if VendorNo = '' then
            Error(Text011);

        ToPurchLine.LockTable();
        OnCopyFromSalesToPurchDocOnBeforePurchaseHeaderInsert(ToPurchHeader, FromSalesHeader, VendorNo);
        ToPurchHeader.Insert(true);
        ToPurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        OnCopyFromSalesToPurchDocOnBeforeToPurchHeaderModify(ToPurchHeader, FromSalesHeader);
        ToPurchHeader.Modify(true);
        FromSalesLine.SetRange("Document Type", FromSalesHeader."Document Type");
        FromSalesLine.SetRange("Document No.", FromSalesHeader."No.");
        OnCopyFromSalesToPurchDocOnAfterSetFilters(FromSalesLine, FromSalesHeader);
        if not FromSalesLine.Find('-') then
            Error(Text012);
        repeat
            NextLineNo := NextLineNo + 10000;
            Clear(ToPurchLine);
            ToPurchLine.Init();
            ToPurchLine."Document Type" := ToPurchHeader."Document Type";
            ToPurchLine."Document No." := ToPurchHeader."No.";
            ToPurchLine."Line No." := NextLineNo;
            if FromSalesLine.Type = FromSalesLine.Type::" " then
                ToPurchLine.Description := FromSalesLine.Description
            else
                TransfldsFromSalesToPurchLine(FromSalesLine, ToPurchLine);
            OnBeforeCopySalesToPurchDoc(ToPurchLine, FromSalesLine);
            ToPurchLine.Insert(true);
            ShouldCopyItemTracking := (FromSalesLine.Type <> FromSalesLine.Type::" ") and (ToPurchLine.Type = ToPurchLine.Type::Item) and (ToPurchLine.Quantity <> 0);
            OnCopyFromSalesToPurchDocOnAfterCalcShouldCopyItemTracking(ToPurchLine, ShouldCopyItemTracking);
            if ShouldCopyItemTracking then
                CopyItemTrackingEntries(
                  FromSalesLine, ToPurchLine, FromSalesHeader."Prices Including VAT",
                  ToPurchHeader."Prices Including VAT");
            OnAfterCopySalesToPurchDoc(ToPurchLine, FromSalesLine);
        until FromSalesLine.Next() = 0;

        OnAfterCopyFromSalesToPurchDoc(FromSalesHeader, ToPurchHeader);
    end;

    procedure TransfldsFromSalesToPurchLine(var FromSalesLine: Record "Sales Line"; var ToPurchLine: Record "Purchase Line")
    var
        DimMgt: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransfldsFromSalesToPurchLine(FromSalesLine, ToPurchLine, IsHandled);
        if IsHandled then
            exit;

        ToPurchLine.Validate(ToPurchLine.Type, FromSalesLine.Type);
        ToPurchLine.Validate(ToPurchLine."No.", FromSalesLine."No.");
        ToPurchLine.Validate(ToPurchLine."Variant Code", FromSalesLine."Variant Code");
        ToPurchLine.Validate(ToPurchLine."Location Code", FromSalesLine."Location Code");
        ToPurchLine.Validate(ToPurchLine."Unit of Measure Code", FromSalesLine."Unit of Measure Code");
        if (ToPurchLine.Type = ToPurchLine.Type::Item) and (ToPurchLine."No." <> '') then
            ToPurchLine.UpdateUOMQtyPerStockQty();
        ToPurchLine."Expected Receipt Date" := FromSalesLine."Shipment Date";
        ToPurchLine."Bin Code" := FromSalesLine."Bin Code";
        OnTransfldsFromSalesToPurchLineOnBeforeValidateQuantity(FromSalesLine, ToPurchLine);
        if (FromSalesLine."Document Type" = FromSalesLine."Document Type"::"Return Order") and
           (ToPurchLine."Document Type" = ToPurchLine."Document Type"::"Return Order")
        then
            ToPurchLine.Validate(ToPurchLine.Quantity, FromSalesLine.Quantity)
        else
            ToPurchLine.Validate(ToPurchLine.Quantity, FromSalesLine."Outstanding Quantity");
        ToPurchLine.Validate(ToPurchLine."Return Reason Code", FromSalesLine."Return Reason Code");
        ToPurchLine.Validate(ToPurchLine."Direct Unit Cost");
        AssignDescriptionsFromSalesLine(ToPurchLine, FromSalesLine);
        if ToPurchLine."Dimension Set ID" <> FromSalesLine."Dimension Set ID" then begin
            DimensionSetIDArr[1] := ToPurchLine."Dimension Set ID";
            DimensionSetIDArr[2] := FromSalesLine."Dimension Set ID";
            ToPurchLine."Dimension Set ID" :=
              DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, ToPurchLine."Shortcut Dimension 1 Code", ToPurchLine."Shortcut Dimension 2 Code");
        end;

        OnAfterTransfldsFromSalesToPurchLine(FromSalesLine, ToPurchLine);
    end;

    local procedure AssignDescriptionsFromSalesLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
        OnBeforeAssignDescriptionsFromSalesLine(PurchaseLine, SalesLine);
        PurchaseLine.Description := SalesLine.Description;
        PurchaseLine."Description 2" := SalesLine."Description 2";
    end;

    local procedure DeleteSalesLinesWithNegQty(FromSalesHeader: Record "Sales Header"; OnlyTest: Boolean)
    var
        FromSalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteSalesLinesWithNegQty(FromSalesHeader, OnlyTest, IsHandled);
        if IsHandled then
            exit;

        FromSalesLine.SetRange("Document Type", FromSalesHeader."Document Type");
        FromSalesLine.SetRange("Document No.", FromSalesHeader."No.");
        FromSalesLine.SetFilter(FromSalesLine.Quantity, '<0');
        OnDeleteSalesLinesWithNegQtyOnAfterSetFilters(FromSalesLine, OnlyTest);
        if OnlyTest then begin
            if not FromSalesLine.Find('-') then
                Error(Text008);
            repeat
                FromSalesLine.TestField("Shipment No.", '');
                FromSalesLine.TestField("Return Receipt No.", '');
                FromSalesLine.TestField("Quantity Shipped", 0);
                FromSalesLine.TestField("Quantity Invoiced", 0);
            until FromSalesLine.Next() = 0;
        end else
            FromSalesLine.DeleteAll(true);
        OnAfterDeleteSalesLinesWithNegQty(FromSalesLine, OnlyTest);
    end;

    local procedure DeletePurchLinesWithNegQty(FromPurchHeader: Record "Purchase Header"; OnlyTest: Boolean)
    var
        FromPurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeletePurchLinesWithNegQty(FromPurchHeader, OnlyTest, IsHandled);
        if IsHandled then
            exit;

        FromPurchLine.SetRange("Document Type", FromPurchHeader."Document Type");
        FromPurchLine.SetRange("Document No.", FromPurchHeader."No.");
        FromPurchLine.SetFilter(Quantity, '<0');
        if OnlyTest then begin
            if not FromPurchLine.Find('-') then
                Error(Text010);
            repeat
                FromPurchLine.TestField("Receipt No.", '');
                FromPurchLine.TestField("Return Shipment No.", '');
                FromPurchLine.TestField("Quantity Received", 0);
                FromPurchLine.TestField("Quantity Invoiced", 0);
            until FromPurchLine.Next() = 0;
        end else
            FromPurchLine.DeleteAll(true);
    end;

    procedure CopySalesDocLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var NextLineNo: Integer; var LinesNotCopied: Integer; RecalculateAmount: Boolean; FromSalesDocType: Enum "Sales Document Type From"; var CopyPostedDeferral: Boolean; DocLineNo: Integer) Result: Boolean
    var
        RoundingLineInserted: Boolean;
        CopyThisLine: Boolean;
        InvDiscountAmount: Decimal;
        IsHandled: Boolean;
        ShouldValidateQuantityMoveNegLines: Boolean;
        ShouldInitToSalesLine: Boolean;
    begin
        CopyThisLine := true;
        IsHandled := false;
        OnBeforeCopySalesLine(ToSalesHeader, FromSalesHeader, FromSalesLine, RecalculateLines, CopyThisLine, MoveNegLines, Result, IsHandled, DocLineNo);
        if IsHandled then
            exit(Result);

        if not CopyThisLine then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        CheckSalesRounding(FromSalesLine, RoundingLineInserted);

        CopyThisLine := not (((ToSalesHeader."Language Code" <> FromSalesHeader."Language Code") or RecalculateLines) and
           FromSalesLine.IsExtendedText() or
           FromSalesLine."Prepayment Line" or RoundingLineInserted);
        OnCopySalesDocLineOnAfterCalcCopyThisLine(ToSalesHeader, FromSalesHeader, FromSalesLine, RoundingLineInserted, CopyThisLine, RecalculateLines);
        if not CopyThisLine then
            exit(false);

        if IsEntityBlocked(Database::"Sales Line", ToSalesHeader.IsCreditDocType(), FromSalesLine.Type.AsInteger(), FromSalesLine."No.", FromSalesLine."Variant Code") then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        OnCopySalesDocLineOnBeforeSetSalesHeader(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, NextLineNo);

        ToSalesLine.SetSalesHeader(ToSalesHeader);
        ShouldInitToSalesLine := RecalculateLines and not FromSalesLine."System-Created Entry";
        OnCopySalesDocLineOnBeforeInitToSalesLine(ToSalesLine, FromSalesLine, ShouldInitToSalesLine);
        if ShouldInitToSalesLine then begin
            ToSalesLine.Init();
            OnAfterInitToSalesLine(ToSalesLine);
        end else begin
            ToSalesLine := FromSalesLine;
            ToSalesLine."Returns Deferral Start Date" := 0D;
            OnCopySalesLineOnAfterTransferFieldsToSalesLine(ToSalesLine, FromSalesLine);
            if ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Quote, ToSalesHeader."Document Type"::"Blanket Order"] then
                ToSalesLine."Deferral Code" := '';
            if MoveNegLines and (ToSalesLine.Type <> ToSalesLine.Type::" ") then begin
                ToSalesLine.Amount := -ToSalesLine.Amount;
                ToSalesLine."Amount Including VAT" := -ToSalesLine."Amount Including VAT";
            end
        end;

        NextLineNo := NextLineNo + 10000;
        ToSalesLine."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine."Document No." := ToSalesHeader."No.";
        ToSalesLine."Line No." := NextLineNo;
        if not IncludeHeader then
            CheckSalesVATBusPostingGroup(ToSalesHeader, ToSalesLine);
        ToSalesLine."Copied From Posted Doc." := FromSalesLine."Copied From Posted Doc.";
        OnCopySalesDocLineOnAfterAssignCopiedFromPostedDoc(ToSalesLine, ToSalesHeader);
        if (ToSalesLine.Type <> ToSalesLine.Type::" ") and
           (ToSalesLine."Document Type" in [ToSalesLine."Document Type"::"Return Order", ToSalesLine."Document Type"::"Credit Memo"])
        then begin
            ToSalesLine."Job Contract Entry No." := 0;
            if (ToSalesLine.Amount = 0) or
               (ToSalesHeader."Prices Including VAT" <> FromSalesHeader."Prices Including VAT") or
               (ToSalesHeader."Currency Factor" <> FromSalesHeader."Currency Factor")
            then begin
                InvDiscountAmount := ToSalesLine."Inv. Discount Amount";
                IsHandled := false;
                OnCopySalesDocLineOnBeforeValidateLineDiscountPct(ToSalesLine, IsHandled);
                if not IsHandled then
                    ToSalesLine.Validate("Line Discount %");
                IsHandled := false;
                OnCopySalesDocLineOnBeforeValidateInvDiscountAmount(ToSalesLine, InvDiscountAmount, IsHandled);
                if not IsHandled then
                    ToSalesLine.Validate("Inv. Discount Amount", InvDiscountAmount);
            end;
        end;
        ToSalesLine.Validate("Currency Code", FromSalesHeader."Currency Code");

        UpdateSalesLine(
          ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine,
          CopyThisLine, RecalculateAmount, FromSalesDocType, CopyPostedDeferral);

        IsHandled := false;
        OnCopySalesDocLineOnBeforeCheckLocationOnWMS(ToSalesHeader, ToSalesLine, FromSalesLine, IsHandled, IncludeHeader, RecalculateLines);
        if not IsHandled then
            ToSalesLine.CheckLocationOnWMS();

        RecalculateAndApplySalesLine(ToSalesHeader, ToSalesLine, FromSalesLine, RecalculateAmount);

        ShouldValidateQuantityMoveNegLines := MoveNegLines and (ToSalesLine.Type <> ToSalesLine.Type::" ");
        OnCopySalesDocLineOnAfterCalcShouldValidateQuantityMoveNegLines(ToSalesLine, FromSalesLine, ShouldValidateQuantityMoveNegLines);
        if ShouldValidateQuantityMoveNegLines then begin
            ToSalesLine.Validate(Quantity, -FromSalesLine.Quantity);
            OnCopySalesDocLineOnAfterValidateQuantityMoveNegLines(ToSalesLine, FromSalesLine);
            ToSalesLine.Validate("Unit Price", FromSalesLine."Unit Price");
            ToSalesLine.Validate("Line Discount %", FromSalesLine."Line Discount %");
            ToSalesLine."Appl.-to Item Entry" := FromSalesLine."Appl.-to Item Entry";
            ToSalesLine."Appl.-from Item Entry" := FromSalesLine."Appl.-from Item Entry";
            ToSalesLine."Job No." := FromSalesLine."Job No.";
            ToSalesLine."Job Task No." := FromSalesLine."Job Task No.";
            ToSalesLine."Job Contract Entry No." := FromSalesLine."Job Contract Entry No.";
            OnCopySalesDocLineOnAfterMoveNegLines(ToSalesLine, FromSalesLine);
        end;

        OnCopySalesDocLineOnBeforeCopySalesJobFields(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, FromSalesDocType);
        if CopyJobData then
            CopySalesJobFields(ToSalesLine, ToSalesHeader, FromSalesLine);

        CopySalesLineExtText(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, DocLineNo, NextLineNo);

        if not RecalculateLines then begin
            ToSalesLine."Dimension Set ID" := FromSalesLine."Dimension Set ID";
            ToSalesLine."Shortcut Dimension 1 Code" := FromSalesLine."Shortcut Dimension 1 Code";
            ToSalesLine."Shortcut Dimension 2 Code" := FromSalesLine."Shortcut Dimension 2 Code";
            OnCopySalesLineOnAfterSetDimensions(ToSalesLine, FromSalesLine);
        end;

        IsHandled := false;
        OnCopySalesDocLineOnBeforeCopyThisLine(ToSalesHeader, ToSalesLine, FromSalesLine, FromSalesDocType, RecalculateLines, CopyThisLine, LinesNotCopied, Result, IsHandled, NextLineNo, DocLineNo, MoveNegLines);
        if IsHandled then
            exit(Result);
        if CopyThisLine then begin
            IsHandled := false;
            OnBeforeInsertToSalesLine(
              ToSalesLine, FromSalesLine, FromSalesDocType.AsInteger(), RecalculateLines, ToSalesHeader, DocLineNo, NextLineNo, RecalculateAmount, IsHandled);
            if not IsHandled then
                ToSalesLine.Insert();
            OnCopySalesDocLineOnAfterInsertToSalesLine(ToSalesLine, FromSalesLine, FromSalesDocType, MoveNegLines);
            HandleAsmAttachedToSalesLine(ToSalesLine);
            IsHandled := false;
            OnCopySalesDocLineOnBeforeAutoReserve(ToSalesHeader, ToSalesLine, IsHandled);
            if not IsHandled then
                if ToSalesLine.Reserve = ToSalesLine.Reserve::Always then
                    ToSalesLine.AutoReserve();
            OnAfterInsertToSalesLine(ToSalesLine, FromSalesLine, RecalculateLines, DocLineNo, FromSalesDocType, FromSalesHeader, NextLineNo, ToSalesHeader);
        end else
            LinesNotCopied := LinesNotCopied + 1;

        exit(CopyThisLine);
    end;

    local procedure RecalculateAndApplySalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line"; var RecalculateAmount: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalculateAndApplySalesLine(ToSalesHeader, ToSalesLine, FromSalesLine, Currency, ExactCostRevMandatory, RecalculateAmount, CreateToHeader, MoveNegLines, IsHandled);
        if IsHandled then
            exit;

        if ExactCostRevMandatory and
           (FromSalesLine.Type = FromSalesLine.Type::Item) and
           (FromSalesLine."Appl.-from Item Entry" <> 0) and
           not MoveNegLines
        then begin
            if RecalculateAmount then
                RecalculateSalesLineAmounts(FromSalesLine, ToSalesLine, Currency);
            ToSalesLine.Validate("Appl.-from Item Entry", FromSalesLine."Appl.-from Item Entry");
            if not CreateToHeader then
                if ToSalesLine."Shipment Date" = 0D then
                    InitShipmentDateInLine(ToSalesHeader, ToSalesLine);
        end;
    end;

    local procedure RecalculateSalesLineAmounts(FromSalesLine: Record "Sales Line"; var ToSalesLine: Record "Sales Line"; Currency: Record Currency)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalculateSalesLineAmounts(FromSalesLine, ToSalesLine, Currency, IsHandled);
        if IsHandled then
            exit;

        ToSalesLine.Validate("Unit Price", FromSalesLine."Unit Price");
        ToSalesLine.Validate("Line Discount %", FromSalesLine."Line Discount %");
        ToSalesLine.Validate(
            "Line Discount Amount",
            Round(FromSalesLine."Line Discount Amount", Currency."Amount Rounding Precision"));
        ToSalesLine.Validate(
            "Inv. Discount Amount",
            Round(FromSalesLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
    end;

    procedure UpdateSalesHeaderWhenCopyFromSalesHeader(var SalesHeader: Record "Sales Header"; OriginalSalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesHeaderWhenCopyFromSalesHeader(SalesHeader, OriginalSalesHeader, FromDocType, IsHandled);
        if IsHandled then
            exit;

        ClearSalesLastNoSFields(SalesHeader);
        SalesHeader.Status := SalesHeader.Status::Open;
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            SalesHeader."Prepayment %" := 0;
        if FromDocType = "Sales Document Type From"::"Return Order" then begin
            SalesHeader.CopySellToAddressToShipToAddress();
            OnUpdateSalesHeaderWhenCopyFromSalesHeaderOnBeforeValidateShipToCode(SalesHeader);
            SalesHeader.Validate(SalesHeader."Ship-to Code");
        end;
        if FromDocType in ["Sales Document Type From"::Quote, "Sales Document Type From"::"Blanket Order"] then
            if OriginalSalesHeader."Posting Date" = 0D then
                SalesHeader."Posting Date" := WorkDate()
            else
                SalesHeader."Posting Date" := OriginalSalesHeader."Posting Date";
    end;

    local procedure UpdateSalesHeaderWhenCopyFromSalesHeaderArchive(var SalesHeader: Record "Sales Header")
    begin
        ClearSalesLastNoSFields(SalesHeader);
        SalesHeader.Status := SalesHeader.Status::Open;
    end;

    procedure ClearSalesLastNoSFields(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."Last Shipping No." := '';
        SalesHeader."Last Posting No." := '';
        SalesHeader."Last Prepayment No." := '';
        SalesHeader."Last Prepmt. Cr. Memo No." := '';
        SalesHeader."Last Return Receipt No." := '';
    end;

    local procedure UpdateSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromSalesDocType: Enum "Sales Document Type From"; var CopyPostedDeferral: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        FromSalesCommentDocTypeInt: Integer;
        ShouldGetUnitCost: Boolean;
        IsHandled: Boolean;
        ShouldRecalculateSalesLine: Boolean;
    begin
        OnBeforeUpdateSalesLine(
          ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine,
          CopyThisLine, RecalculateAmount, FromSalesDocType.AsInteger(), CopyPostedDeferral);

        FromSalesCommentDocTypeInt := DeferralTypeForSalesDoc(FromSalesDocType.AsInteger());
        CopyPostedDeferral := false;
        ShouldRecalculateSalesLine := RecalculateLines and not FromSalesLine."System-Created Entry";
        OnUpdateSalesLineOnBeforeValidateToSalesLine(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, ShouldRecalculateSalesLine);
        if ShouldRecalculateSalesLine then begin
            OnUpdateSalesLineOnBeforeRecalculateSalesLine(ToSalesLine, FromSalesLine);
            RecalculateSalesLine(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, CopyThisLine);
            if IsDeferralToBeCopied(
                "Deferral Document Type"::Sales, ToSalesLine."Document Type".AsInteger(), FromSalesCommentDocTypeInt)
            then
                ToSalesLine.Validate("Deferral Code", FromSalesLine."Deferral Code");
            OnUpdateSalesLineOnAfterRecalculateSalesLine(ToSalesLine, FromSalesLine);
        end else begin
            SetDefaultValuesToSalesLine(ToSalesLine, ToSalesHeader, FromSalesLine);
            if IsDeferralToBeCopied(
                "Deferral Document Type"::Sales, ToSalesLine."Document Type".AsInteger(), FromSalesCommentDocTypeInt)
            then
                if IsDeferralPosted("Deferral Document Type"::Sales, FromSalesCommentDocTypeInt) then
                    CopyPostedDeferral := true
                else
                    ToSalesLine."Returns Deferral Start Date" :=
                      CopyDeferrals("Deferral Document Type"::Sales, FromSalesLine."Document Type".AsInteger(), FromSalesLine."Document No.",
                        FromSalesLine."Line No.", ToSalesLine."Document Type".AsInteger(), ToSalesLine."Document No.", ToSalesLine."Line No.")
            else
                if IsDeferralToBeDefaulted("Deferral Document Type"::Sales, ToSalesLine."Document Type".AsInteger(), FromSalesCommentDocTypeInt) then
                    InitSalesDeferralCode(ToSalesLine);

            OnUpdateSalesLineOnBeforeClearDropShipmentAndSpecialOrder(ToSalesLine, FromSalesLine);
            if not (ToSalesLine."Document Type" in ["Sales Document Type"::Order, "Sales Document Type"::Quote, "Sales Document Type"::"Blanket Order"]) then begin
                ToSalesLine."Drop Shipment" := false;
                ToSalesLine."Special Order" := false;
            end;
            OnUpdateSalesLineBeforeRecalculateAmount(ToSalesLine, FromSalesLine);
            if RecalculateAmount and (FromSalesLine."Appl.-from Item Entry" = 0) then begin
                if (ToSalesLine.Type <> ToSalesLine.Type::" ") and (ToSalesLine."No." <> '') then begin
                    ToSalesLine.Validate("Line Discount %", FromSalesLine."Line Discount %");
                    ToSalesLine.Validate(
                      "Inv. Discount Amount", Round(FromSalesLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
                end;
                IsHandled := false;
                OnUpdateSalesLineOnBeforeToSalesLineValidateUnitCostLcy(ToSalesLine, FromSalesLine, IsHandled);
                if not IsHandled then
                    ToSalesLine.Validate("Unit Cost (LCY)", FromSalesLine."Unit Cost (LCY)");
            end;
            if VATPostingSetup.Get(ToSalesLine."VAT Bus. Posting Group", ToSalesLine."VAT Prod. Posting Group") then begin
                ToSalesLine."VAT Identifier" := VATPostingSetup."VAT Identifier";
                ToSalesLine."VAT Clause Code" := VATPostingSetup."VAT Clause Code";
            end;

            ToSalesLine.UpdateWithWarehouseShip();
            if (ToSalesLine.Type = ToSalesLine.Type::Item) and (ToSalesLine."No." <> '') then begin
                GetItem(ToSalesLine."No.");
                ShouldGetUnitCost := (Item."Costing Method" = Item."Costing Method"::Standard) and not ToSalesLine.IsShipment() and not IsCreatedFromJob(FromSalesLine);
                OnUpdateSalesLineOnAfterCalcShouldGetUnitCost(Item, ShouldGetUnitCost);
                if ShouldGetUnitCost then
                    ToSalesLine.GetUnitCost();

                if Item.Reserve = Item.Reserve::Optional then
                    ToSalesLine.Reserve := ToSalesHeader.Reserve
                else
                    ToSalesLine.Reserve := Item.Reserve;
                OnUpdateSalesLineOnAfterSetReserve(ToSalesLine, FromSalesLine, FromSalesDocType);
                if ToSalesLine.Reserve = ToSalesLine.Reserve::Always then
                    InitShipmentDateInLine(ToSalesHeader, ToSalesLine);
            end;
            OnUpdateSalesLineOnAfterUpdateWithWarehouseShip(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine);
        end;

        OnAfterUpdateSalesLine(
          ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine,
          CopyThisLine, RecalculateAmount, FromSalesDocType.AsInteger(), CopyPostedDeferral,
          ExactCostRevMandatory, MoveNegLines, RecalculateLines);
    end;

    local procedure IsCreatedFromJob(var SalesLine: Record "Sales Line"): Boolean
    begin
        if (SalesLine."Job No." <> '') and (SalesLine."Job Task No." <> '') and (SalesLine."Job Contract Entry No." <> 0) then
            exit(true);
    end;

    local procedure RecalculateSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var CopyThisLine: Boolean)
    var
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalculateSalesLine(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, CopyThisLine, IsHandled);
        if not IsHandled then begin
            ToSalesLine.Validate(Type, FromSalesLine.Type);
            ToSalesLine.Description := FromSalesLine.Description;
            ToSalesLine.Validate("Description 2", FromSalesLine."Description 2");
            OnUpdateSalesLine(ToSalesLine, FromSalesLine);

            if (FromSalesLine.Type <> FromSalesLine.Type::" ") and (FromSalesLine."No." <> '') then begin
                if ToSalesLine.Type = ToSalesLine.Type::"G/L Account" then begin
                    ToSalesLine."No." := FromSalesLine."No.";
                    GLAcc.Get(FromSalesLine."No.");
                    CopyThisLine := GLAcc."Direct Posting";
                    OnRecalculateSalesLineOnBeforeCopyThisLine(ToSalesLine, FromSalesLine);
                    if CopyThisLine then
                        ToSalesLine.Validate("No.", FromSalesLine."No.");
                end else
                    ToSalesLine.Validate("No.", FromSalesLine."No.");

                OnRecalculateSalesLineOnAfterValidateNo(ToSalesLine, FromSalesLine);

                ToSalesLine.Validate("Variant Code", FromSalesLine."Variant Code");

                IsHandled := false;
                OnRecalculateSalesLineOnBeforeValidateLocationCode(ToSalesLine, IsHandled);
                if not IsHandled then
                    ToSalesLine.Validate("Location Code", FromSalesLine."Location Code");

                ToSalesLine.Validate("Unit of Measure", FromSalesLine."Unit of Measure");
                ToSalesLine.Validate("Unit of Measure Code", FromSalesLine."Unit of Measure Code");
                ToSalesLine.Validate(Quantity, FromSalesLine.Quantity);
                OnRecalculateSalesLineOnAfterValidateQuantity(ToSalesLine, FromSalesLine);

                if not (FromSalesLine.Type in [FromSalesLine.Type::Item, FromSalesLine.Type::Resource]) then begin
                    if (FromSalesHeader."Currency Code" <> ToSalesHeader."Currency Code") or
                       (FromSalesHeader."Prices Including VAT" <> ToSalesHeader."Prices Including VAT")
                    then begin
                        ToSalesLine."Unit Price" := 0;
                        ToSalesLine."Line Discount %" := 0;
                    end else begin
                        ToSalesLine.Validate("Unit Price", FromSalesLine."Unit Price");
                        ToSalesLine.Validate("Line Discount %", FromSalesLine."Line Discount %");
                    end;
                    if ToSalesLine.Quantity <> 0 then
                        ToSalesLine.Validate("Line Discount Amount", FromSalesLine."Line Discount Amount");
                    OnRecalculateSalesLineOnAfterValidateLineDiscountAmount(ToSalesLine, FromSalesLine);
                end;

                OnRecalculateSalesLineOnBeforeValidateWorkTypeCode(ToSalesLine, FromSalesLine);

                ToSalesLine.Validate("Work Type Code", FromSalesLine."Work Type Code");
                if (ToSalesLine."Document Type" = ToSalesLine."Document Type"::Order) and
                   (FromSalesLine."Purchasing Code" <> '')
                then
                    ToSalesLine.Validate("Purchasing Code", FromSalesLine."Purchasing Code");
            end;
            if (FromSalesLine.Type = FromSalesLine.Type::" ") and (FromSalesLine."No." <> '') then
                ToSalesLine.Validate("No.", FromSalesLine."No.");
        end;

        OnAfterRecalculateSalesLine(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, CopyThisLine);
    end;

    procedure HandleAsmAttachedToSalesLine(var ToSalesLine: Record "Sales Line")
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleAsmAttachedToSalesLine(ToSalesLine, IsHandled);
        if IsHandled then
            exit;

        if ToSalesLine.Type <> ToSalesLine.Type::Item then
            exit;
        if not (ToSalesLine."Document Type" in [ToSalesLine."Document Type"::Quote, ToSalesLine."Document Type"::Order, ToSalesLine."Document Type"::"Blanket Order"]) then
            exit;
        if AsmHdrExistsForFromDocLine then begin
            ToSalesLine."Qty. to Assemble to Order" := QtyToAsmToOrder;
            ToSalesLine."Qty. to Asm. to Order (Base)" := QtyToAsmToOrderBase;
            ToSalesLine.Modify();
            CopyAsmOrderToAsmOrder(
                TempAsmHeader, TempAsmLine, ToSalesLine, GetAsmOrderType(ToSalesLine."Document Type"), '', true);
        end else begin
            Item.Get(ToSalesLine."No.");
            if (Item."Assembly Policy" = Item."Assembly Policy"::"Assemble-to-Order") and
               (Item."Replenishment System" = Item."Replenishment System"::Assembly) and
               ToSalesLine.IsAsmToOrderAllowed()
            then begin
                ToSalesLine.Validate("Qty. to Assemble to Order", ToSalesLine.Quantity);
                ToSalesLine.Modify();
            end;
        end;

        OnAfterHandleAsmAttachedToSalesLine(ToSalesLine);
    end;

    procedure CopyPurchDocLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var NextLineNo: Integer; var LinesNotCopied: Integer; RecalculateAmount: Boolean; FromPurchDocType: Enum "Purchase Document Type From"; var CopyPostedDeferral: Boolean; DocLineNo: Integer) Result: Boolean
    var
        RoundingLineInserted: Boolean;
        CopyThisLine: Boolean;
        IsHandled: Boolean;
    begin
        CopyThisLine := true;
        IsHandled := false;
        OnBeforeCopyPurchLine(
          ToPurchHeader, FromPurchHeader, FromPurchLine, RecalculateLines, CopyThisLine, ToPurchLine, MoveNegLines,
          RoundingLineInserted, Result, IsHandled, FromPurchDocType, DocLineNo, RecalculateLines, LinesNotCopied, CopyPostedDeferral, NextLineNo);
        if IsHandled then
            exit(Result);
        if not CopyThisLine then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        CheckPurchRounding(FromPurchLine, RoundingLineInserted);

        if ((ToPurchHeader."Language Code" <> FromPurchHeader."Language Code") or RecalculateLines) and
           FromPurchLine.IsExtendedText() or
           FromPurchLine."Prepayment Line" or RoundingLineInserted
        then
            exit(false);

        if IsEntityBlocked(Database::"Purchase Line", ToPurchHeader.IsCreditDocType(), FromPurchLine.Type.AsInteger(), FromPurchLine."No.", FromPurchLine."Variant Code") then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        OnCopyPurchDocLineOnBeforeRecalculateLines(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, NextLineNo);
        if RecalculateLines and not FromPurchLine."System-Created Entry" then begin
            ToPurchLine.Init();
            OnAfterInitToPurchLine(ToPurchLine);
        end else begin
            ToPurchLine := FromPurchLine;
            ToPurchLine."Returns Deferral Start Date" := 0D;
            if ToPurchHeader."Document Type" in [ToPurchHeader."Document Type"::Quote, ToPurchHeader."Document Type"::"Blanket Order"] then
                ToPurchLine."Deferral Code" := '';
            if MoveNegLines and (ToPurchLine.Type <> ToPurchLine.Type::" ") then begin
                ToPurchLine.Amount := -ToPurchLine.Amount;
                ToPurchLine."Amount Including VAT" := -ToPurchLine."Amount Including VAT";
            end
        end;

        NextLineNo := NextLineNo + 10000;
        OnCopyPurchDocLineOnAfterSetNextLineNo(ToPurchLine, FromPurchLine, NextLineNo);
        ToPurchLine."Document Type" := ToPurchHeader."Document Type";
        ToPurchLine."Document No." := ToPurchHeader."No.";
        ToPurchLine."Line No." := NextLineNo;
        if not IncludeHeader then
            CheckPurchVATBusPostingGroup(ToPurchHeader, ToPurchLine);
        ToPurchLine."Copied From Posted Doc." := FromPurchLine."Copied From Posted Doc.";
        ToPurchLine.Validate("Currency Code", FromPurchHeader."Currency Code");
        ValidatePurchLineDiscountFields(FromPurchHeader, ToPurchHeader, ToPurchLine);
        UpdatePurchLine(
          ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine,
          CopyThisLine, RecalculateAmount, FromPurchDocType, CopyPostedDeferral);

        IsHandled := false;
        OnCopyPurchDocLineOnBeforeCheckLocationOnWMS(ToPurchHeader, ToPurchLine, FromPurchLine, IsHandled);
        if not IsHandled then
            ToPurchLine.CheckLocationOnWMS();

        RecalculateAndApplyPurchLine(ToPurchHeader, ToPurchLine, FromPurchLine, RecalculateAmount);

        OnCopyPurchLineOnBeforeValidateQuantity(ToPurchLine, RecalculateLines, FromPurchLine, MoveNegLines);

        if MoveNegLines and (ToPurchLine.Type <> ToPurchLine.Type::" ") then begin
            ToPurchLine.Validate(Quantity, -FromPurchLine.Quantity);
            OnCopyPurchLineOnAfterValidateQuantityMoveNegLines(ToPurchLine, FromPurchLine);
            ToPurchLine."Appl.-to Item Entry" := FromPurchLine."Appl.-to Item Entry"
        end;

        CopyPurchLineExtText(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, DocLineNo, NextLineNo);

        if FromPurchLine."Job No." <> '' then
            CopyPurchaseJobFields(ToPurchLine, FromPurchLine);

        if not RecalculateLines then begin
            ToPurchLine."Dimension Set ID" := FromPurchLine."Dimension Set ID";
            ToPurchLine."Shortcut Dimension 1 Code" := FromPurchLine."Shortcut Dimension 1 Code";
            ToPurchLine."Shortcut Dimension 2 Code" := FromPurchLine."Shortcut Dimension 2 Code";
            OnCopyPurchLineOnAfterSetDimensions(ToPurchLine, FromPurchLine);
        end;

        IsHandled := false;
        OnCopyPurchDocLineOnBeforeCopyThisLine(ToPurchLine, FromPurchLine, MoveNegLines, FromPurchDocType, LinesNotCopied, CopyThisLine, Result, IsHandled, ToPurchHeader, RecalculateLines, NextLineNo);
        if IsHandled then
            exit(Result);

        if CopyThisLine then begin
            OnBeforeInsertToPurchLine(
                ToPurchLine, FromPurchLine, FromPurchDocType.AsInteger(), RecalculateLines, ToPurchHeader, DocLineNo, NextLineNo);
            ToPurchLine.Insert();
            OnAfterInsertToPurchLine(ToPurchLine, FromPurchLine, RecalculateLines, DocLineNo, FromPurchDocType, ToPurchHeader, MoveNegLines, FromPurchHeader);
        end else
            LinesNotCopied := LinesNotCopied + 1;

        exit(CopyThisLine);
    end;

    local procedure RecalculateAndApplyPurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line"; RecalculateAmount: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalculateAndApplyPurchLine(ToPurchHeader, ToPurchLine, FromPurchLine, Currency, RecalculateAmount, ExactCostRevMandatory, CreateToHeader, MoveNegLines, IsHandled);
        if IsHandled then
            exit;

        if ExactCostRevMandatory and
           (FromPurchLine.Type = FromPurchLine.Type::Item) and
           (FromPurchLine."Appl.-to Item Entry" <> 0) and
           not MoveNegLines
        then begin
            if RecalculateAmount then begin
                ToPurchLine.Validate("Direct Unit Cost", FromPurchLine."Direct Unit Cost");
                ToPurchLine.Validate("Line Discount %", FromPurchLine."Line Discount %");
                ToPurchLine.Validate(
                  "Line Discount Amount",
                  Round(FromPurchLine."Line Discount Amount", Currency."Amount Rounding Precision"));
                ToPurchLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromPurchLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            end;
            ToPurchLine.Validate("Appl.-to Item Entry", FromPurchLine."Appl.-to Item Entry");
            if not CreateToHeader then
                if ToPurchLine."Expected Receipt Date" = 0D then begin
                    if ToPurchHeader."Expected Receipt Date" <> 0D then
                        ToPurchLine."Expected Receipt Date" := ToPurchHeader."Expected Receipt Date"
                    else
                        ToPurchLine."Expected Receipt Date" := WorkDate();
                end;
        end;

    end;

    local procedure ValidatePurchLineDiscountFields(FromPurchHeader: Record "Purchase Header"; ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line")
    var
        InvDiscountAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidatePurchLineDiscountFields(FromPurchHeader, ToPurchHeader, ToPurchLine, InvDiscountAmount, IsHandled, RecalculateLines);
        if IsHandled then
            exit;

        if (ToPurchLine.Type <> ToPurchLine.Type::" ") and
           ((ToPurchLine.Amount = 0) or
            (ToPurchHeader."Prices Including VAT" <> FromPurchHeader."Prices Including VAT") or
            (ToPurchHeader."Currency Factor" <> FromPurchHeader."Currency Factor"))
        then begin
            InvDiscountAmount := ToPurchLine."Inv. Discount Amount";
            ToPurchLine.Validate("Line Discount %");
            ToPurchLine.Validate("Inv. Discount Amount", InvDiscountAmount);
        end;
    end;

    procedure UpdatePurchHeaderWhenCopyFromPurchHeader(var PurchaseHeader: Record "Purchase Header"; OriginalPurchaseHeader: Record "Purchase Header"; FromDocType: Enum "Purchase Document Type From")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchHeaderWhenCopyFromPurchHeader(PurchaseHeader, OriginalPurchaseHeader, FromDocType, IsHandled);
        if IsHandled then
            exit;

        ClearPurchLastNoSFields(PurchaseHeader);
        PurchaseHeader.Receive := false;
        PurchaseHeader.Status := PurchaseHeader.Status::Open;
        PurchaseHeader."IC Status" := PurchaseHeader."IC Status"::New;
        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Order then
            PurchaseHeader."Prepayment %" := 0;
        if FromDocType in ["Purchase Document Type From"::Quote, "Purchase Document Type From"::"Blanket Order"] then
            if OriginalPurchaseHeader."Posting Date" = 0D then
                PurchaseHeader."Posting Date" := WorkDate()
            else
                PurchaseHeader."Posting Date" := OriginalPurchaseHeader."Posting Date";
    end;

    local procedure UpdatePurchHeaderWhenCopyFromPurchHeaderArchive(var PurchaseHeader: Record "Purchase Header")
    begin
        ClearPurchLastNoSFields(PurchaseHeader);
        PurchaseHeader.Status := PurchaseHeader.Status::Open;
    end;

    procedure ClearPurchLastNoSFields(var PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearPurchLastNoSFields(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        PurchaseHeader."Last Receiving No." := '';
        PurchaseHeader."Last Posting No." := '';
        PurchaseHeader."Last Prepayment No." := '';
        PurchaseHeader."Last Prepmt. Cr. Memo No." := '';
        PurchaseHeader."Last Return Shipment No." := '';
    end;

    local procedure UpdatePurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromPurchDocType: Enum "Purchase Document Type From"; var CopyPostedDeferral: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        FromPurchCommentDocTypeInt: Integer;
    begin
        OnBeforeUpdatePurchLine(
          ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine,
          CopyThisLine, RecalculateAmount, FromPurchDocType.AsInteger(), CopyPostedDeferral);

        FromPurchCommentDocTypeInt := DeferralTypeForPurchDoc(FromPurchDocType.AsInteger());
        CopyPostedDeferral := false;
        if RecalculateLines and not FromPurchLine."System-Created Entry" then begin
            RecalculatePurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, CopyThisLine);
            if IsDeferralToBeCopied("Deferral Document Type"::Purchase, ToPurchLine."Document Type".AsInteger(), FromPurchCommentDocTypeInt) then
                ToPurchLine.Validate("Deferral Code", FromPurchLine."Deferral Code");
        end else begin
            SetDefaultValuesToPurchLine(ToPurchLine, ToPurchHeader, FromPurchLine."VAT Difference");
            if IsDeferralToBeCopied("Deferral Document Type"::Purchase, ToPurchLine."Document Type".AsInteger(), FromPurchCommentDocTypeInt) then
                if IsDeferralPosted("Deferral Document Type"::Purchase, FromPurchCommentDocTypeInt) then
                    CopyPostedDeferral := true
                else
                    ToPurchLine."Returns Deferral Start Date" :=
                      CopyDeferrals("Deferral Document Type"::Purchase, FromPurchLine."Document Type".AsInteger(), FromPurchLine."Document No.",
                        FromPurchLine."Line No.", ToPurchLine."Document Type".AsInteger(), ToPurchLine."Document No.", ToPurchLine."Line No.")
            else
                if IsDeferralToBeDefaulted("Deferral Document Type"::Purchase, ToPurchLine."Document Type".AsInteger(), FromPurchCommentDocTypeInt) then
                    InitPurchDeferralCode(ToPurchLine);

            if FromPurchLine."Drop Shipment" or FromPurchLine."Special Order" then
                ToPurchLine."Purchasing Code" := '';
            ToPurchLine."Drop Shipment" := false;
            ToPurchLine."Special Order" := false;
            if VATPostingSetup.Get(ToPurchLine."VAT Bus. Posting Group", ToPurchLine."VAT Prod. Posting Group") then
                ToPurchLine."VAT Identifier" := VATPostingSetup."VAT Identifier";

            OnBeforeCopyPurchLines(ToPurchLine);

            CopyDocLines(RecalculateAmount, ToPurchLine, FromPurchLine);

            ToPurchLine.UpdateWithWarehouseReceive();
            ToPurchLine."Pay-to Vendor No." := ToPurchHeader."Pay-to Vendor No.";
            OnUpdatePurchLineOnAfterCopyDocLine(ToPurchLine, FromPurchLine);
        end;
        ToPurchLine.Validate("Order No.", FromPurchLine."Order No.");
        ToPurchLine.Validate("Order Line No.", FromPurchLine."Order Line No.");

        OnAfterUpdatePurchLine(
          ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine,
          CopyThisLine, RecalculateAmount, FromPurchDocType.AsInteger(), CopyPostedDeferral, RecalculateLines);
    end;

    local procedure RecalculatePurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean)
    var
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        OnBeforeRecalculatePurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, CopyThisLine);

        ToPurchLine.Validate(Type, FromPurchLine.Type);
        ToPurchLine.Description := FromPurchLine.Description;
        ToPurchLine.Validate("Description 2", FromPurchLine."Description 2");
        OnUpdatePurchLine(ToPurchLine, FromPurchLine);

        if (FromPurchLine.Type <> FromPurchLine.Type::" ") and (FromPurchLine."No." <> '') then begin
            if ToPurchLine.Type = ToPurchLine.Type::"G/L Account" then begin
                ToPurchLine."No." := FromPurchLine."No.";
                GLAcc.Get(FromPurchLine."No.");
                CopyThisLine := GLAcc."Direct Posting";
                OnRecalculatePurchLineOnAfterCopyThisLine(ToPurchLine, FromPurchLine);
                if CopyThisLine then
                    ToPurchLine.Validate("No.", FromPurchLine."No.");
            end else
                ToPurchLine.Validate("No.", FromPurchLine."No.");
            OnRecalculatePurchLineOnAfterValidateNo(ToPurchLine, FromPurchLine);
            ToPurchLine.Validate("Variant Code", FromPurchLine."Variant Code");

            IsHandled := false;
            OnRecalculatePurchLineOnBeforeValidateLocationCode(ToPurchLine, IsHandled);
            if not IsHandled then
                ToPurchLine.Validate("Location Code", FromPurchLine."Location Code");

            ToPurchLine.Validate("Unit of Measure", FromPurchLine."Unit of Measure");
            ToPurchLine.Validate("Unit of Measure Code", FromPurchLine."Unit of Measure Code");
            ToPurchLine.Validate(Quantity, FromPurchLine.Quantity);
            OnRecalculatePurchLineOnAfterValidateQuantity(ToPurchLine, FromPurchLine);

            if not (FromPurchLine.Type in [FromPurchLine.Type::Item, FromPurchLine.Type::Resource]) then begin
                ToPurchHeader.TestField("Currency Code", FromPurchHeader."Currency Code");
                ToPurchLine.Validate("Direct Unit Cost", FromPurchLine."Direct Unit Cost");
                ToPurchLine.Validate("Line Discount %", FromPurchLine."Line Discount %");
                if ToPurchLine.Quantity <> 0 then
                    ToPurchLine.Validate("Line Discount Amount", FromPurchLine."Line Discount Amount");
            end;
            IsHandled := false;
            OnRecalculatePurchLineOnBeforeValidatePurchasingCode(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, CopyThisLine, IsHandled);
            if not IsHandled then
                if (ToPurchLine."Document Type" = ToPurchLine."Document Type"::Order) and
                   (FromPurchLine."Purchasing Code" <> '') and not FromPurchLine."Drop Shipment" and not FromPurchLine."Special Order"
                then
                    ToPurchLine.Validate("Purchasing Code", FromPurchLine."Purchasing Code");
            OnRecalculatePurchLineOnAfterValidatePurchasingCode(ToPurchLine, FromPurchLine);
        end;
        if (FromPurchLine.Type = FromPurchLine.Type::" ") and (FromPurchLine."No." <> '') then
            ToPurchLine.Validate("No.", FromPurchLine."No.");

        OnAfterRecalculatePurchLine(ToPurchLine, ToPurchHeader, FromPurchHeader, FromPurchLine, CopyThisLine);
    end;

    local procedure CheckPurchRounding(FromPurchLine: Record "Purchase Line"; var RoundingLineInserted: Boolean)
    var
        PurchSetup: Record "Purchases & Payables Setup";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if (FromPurchLine.Type <> FromPurchLine.Type::"G/L Account") or (FromPurchLine."No." = '') then
            exit;
        if not FromPurchLine."System-Created Entry" then
            exit;

        PurchSetup.Get();
        if PurchSetup."Invoice Rounding" then begin
            GetVendor(FromPurchLine, Vendor);
            VendorPostingGroup.Get(Vendor."Vendor Posting Group");
            RoundingLineInserted := FromPurchLine."No." = VendorPostingGroup.GetInvRoundingAccount();
        end;
    end;

    local procedure GetVendor(var FromPurchLine: Record "Purchase Line"; var Vendor: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetVendor(FromPurchLine, Vendor, IsHandled);
        if not IsHandled then
            Vendor.Get(FromPurchLine."Pay-to Vendor No.");
    end;

    local procedure CheckSalesRounding(FromSalesLine: Record "Sales Line"; var RoundingLineInserted: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesRounding(FromSalesLine, RoundingLineInserted, IsHandled);
        if IsHandled then
            exit;

        if (FromSalesLine.Type <> FromSalesLine.Type::"G/L Account") or (FromSalesLine."No." = '') then
            exit;
        if not FromSalesLine."System-Created Entry" then
            exit;

        SalesSetup.Get();
        if SalesSetup."Invoice Rounding" then begin
            Customer.Get(FromSalesLine."Bill-to Customer No.");
            CustomerPostingGroup.Get(Customer."Customer Posting Group");
            RoundingLineInserted := FromSalesLine."No." = CustomerPostingGroup.GetInvRoundingAccount();
        end;

        OnAfterCheckSalesRounding(FromSalesLine, RoundingLineInserted);
    end;

    local procedure CopyFromSalesDocAssgntToLine(var ToSalesLine: Record "Sales Line"; FromDocType: Enum "Sales Document Type"; FromDocNo: Code[20]; FromLineNo: Integer; var ItemChargeAssgntNextLineNo: Integer)
    var
        FromItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ToItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
        IsHandled: Boolean;
    begin
        FromItemChargeAssgntSales.Reset();
        FromItemChargeAssgntSales.SetRange("Document Type", FromDocType);
        FromItemChargeAssgntSales.SetRange("Document No.", FromDocNo);
        FromItemChargeAssgntSales.SetRange("Document Line No.", FromLineNo);
        FromItemChargeAssgntSales.SetFilter("Applies-to Doc. Type", '<>%1', FromDocType);
        OnCopyFromSalesDocAssgntToLineOnAfterSetFilters(FromItemChargeAssgntSales, RecalculateLines);
        if FromItemChargeAssgntSales.Find('-') then
            repeat
                ToItemChargeAssgntSales.Copy(FromItemChargeAssgntSales);
                ToItemChargeAssgntSales."Document Type" := ToSalesLine."Document Type";
                ToItemChargeAssgntSales."Document No." := ToSalesLine."Document No.";
                ToItemChargeAssgntSales."Document Line No." := ToSalesLine."Line No.";
                IsHandled := false;
                OnCopyFromSalesDocAssgntToLineOnBeforeInsert(FromItemChargeAssgntSales, RecalculateLines, IsHandled);
                if not IsHandled then
                    ItemChargeAssgntSales.InsertItemChargeAssignment(
                      ToItemChargeAssgntSales, ToItemChargeAssgntSales."Applies-to Doc. Type",
                      ToItemChargeAssgntSales."Applies-to Doc. No.", ToItemChargeAssgntSales."Applies-to Doc. Line No.",
                      ToItemChargeAssgntSales."Item No.", ToItemChargeAssgntSales.Description, ItemChargeAssgntNextLineNo);
            until FromItemChargeAssgntSales.Next() = 0;

        OnAfterCopyFromSalesDocAssgntToLine(ToSalesLine, RecalculateLines);
    end;

    local procedure CopyFromPurchDocAssgntToLine(var ToPurchLine: Record "Purchase Line"; FromDocType: Enum "Purchase Document Type"; FromDocNo: Code[20]; FromLineNo: Integer; var ItemChargeAssgntNextLineNo: Integer)
    var
        FromItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ToItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        IsHandled: Boolean;
    begin
        FromItemChargeAssgntPurch.Reset();
        FromItemChargeAssgntPurch.SetRange("Document Type", FromDocType);
        FromItemChargeAssgntPurch.SetRange("Document No.", FromDocNo);
        FromItemChargeAssgntPurch.SetRange("Document Line No.", FromLineNo);
        FromItemChargeAssgntPurch.SetFilter("Applies-to Doc. Type", '<>%1', FromDocType);
        OnCopyFromPurchDocAssgntToLineOnAfterSetFilters(FromItemChargeAssgntPurch, RecalculateLines);
        if FromItemChargeAssgntPurch.Find('-') then
            repeat
                ToItemChargeAssgntPurch.Copy(FromItemChargeAssgntPurch);
                ToItemChargeAssgntPurch."Document Type" := ToPurchLine."Document Type";
                ToItemChargeAssgntPurch."Document No." := ToPurchLine."Document No.";
                ToItemChargeAssgntPurch."Document Line No." := ToPurchLine."Line No.";
                IsHandled := false;
                OnCopyFromPurchDocAssgntToLineOnBeforeInsert(FromItemChargeAssgntPurch, RecalculateLines, IsHandled);
                if not IsHandled then
                    ItemChargeAssgntPurch.InsertItemChargeAssignment(
                      ToItemChargeAssgntPurch, ToItemChargeAssgntPurch."Applies-to Doc. Type",
                      ToItemChargeAssgntPurch."Applies-to Doc. No.", ToItemChargeAssgntPurch."Applies-to Doc. Line No.",
                      ToItemChargeAssgntPurch."Item No.", ToItemChargeAssgntPurch.Description, ItemChargeAssgntNextLineNo);
            until FromItemChargeAssgntPurch.Next() = 0;

        OnAfterCopyFromPurchDocAssgntToLine(ToPurchLine, RecalculateLines);
    end;

    local procedure CopyFromPurchLineItemChargeAssign(FromPurchLine: Record "Purchase Line"; ToPurchLine: Record "Purchase Line"; FromPurchHeader: Record "Purchase Header"; var ItemChargeAssgntNextLineNo: Integer)
    var
        TempToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary;
        ToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        Currency: Record Currency;
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
        CurrencyFactor: Decimal;
        QtyToAssign: Decimal;
        SumQtyToAssign: Decimal;
        RemainingQty: Decimal;
    begin
        if FromPurchLine."Document Type" = FromPurchLine."Document Type"::"Credit Memo" then
            ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Credit Memo")
        else
            ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");

        ValueEntry.SetRange("Document No.", FromPurchLine."Document No.");
        ValueEntry.SetRange("Document Line No.", FromPurchLine."Line No.");
        ValueEntry.SetRange("Item Charge No.", FromPurchLine."No.");
        ToItemChargeAssignmentPurch."Document Type" := ToPurchLine."Document Type";
        ToItemChargeAssignmentPurch."Document No." := ToPurchLine."Document No.";
        ToItemChargeAssignmentPurch."Document Line No." := ToPurchLine."Line No.";
        ToItemChargeAssignmentPurch."Item Charge No." := FromPurchLine."No.";
        ToItemChargeAssignmentPurch."Unit Cost" := FromPurchLine."Unit Cost";

        if ValueEntry.FindSet() then begin
            repeat
                if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then
                    if ItemLedgerEntry."Document Type" = ItemLedgerEntry."Document Type"::"Purchase Receipt" then begin
                        Item.Get(ItemLedgerEntry."Item No.");
                        CurrencyFactor := FromPurchHeader."Currency Factor";

                        if not Currency.Get(FromPurchHeader."Currency Code") then begin
                            CurrencyFactor := 1;
                            Currency.InitRoundingPrecision();
                        end;

                        if ToPurchLine."Unit Cost" = 0 then
                            QtyToAssign := 0
                        else
                            QtyToAssign :=
                              Sign(ToPurchLine.Quantity) * Abs(ValueEntry."Cost Amount (Actual)") * CurrencyFactor / ToPurchLine."Unit Cost";
                        SumQtyToAssign += QtyToAssign;

                        ItemChargeAssgntPurch.InsertItemChargeAssignmentWithValuesTo(
                            ToItemChargeAssignmentPurch, ToItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
                            ItemLedgerEntry."Document No.", ItemLedgerEntry."Document Line No.", ItemLedgerEntry."Item No.", Item.Description,
                            QtyToAssign, 0, ItemChargeAssgntNextLineNo, TempToItemChargeAssignmentPurch);
                    end;
                OnCopyFromPurchLineItemChargeAssignOnAfterValueEntryLoop(
                    FromPurchHeader, ToPurchLine, ValueEntry, TempToItemChargeAssignmentPurch, ToItemChargeAssignmentPurch,
                    ItemChargeAssgntNextLineNo, SumQtyToAssign);
            until ValueEntry.Next() = 0;
            ItemChargeAssgntPurch.Summarize(TempToItemChargeAssignmentPurch, ToItemChargeAssignmentPurch);

            // Use 2 passes to correct rounding issues
            ToItemChargeAssignmentPurch.SetRange("Document Type", ToPurchLine."Document Type");
            ToItemChargeAssignmentPurch.SetRange("Document No.", ToPurchLine."Document No.");
            ToItemChargeAssignmentPurch.SetRange("Document Line No.", ToPurchLine."Line No.");
            if ToItemChargeAssignmentPurch.FindSet(true) then begin
                RemainingQty := (FromPurchLine.Quantity - SumQtyToAssign) / ValueEntry.Count();
                SumQtyToAssign := 0;
                repeat
                    AddRemainingQtyToPurchItemCharge(ToItemChargeAssignmentPurch, RemainingQty);
                    SumQtyToAssign += ToItemChargeAssignmentPurch."Qty. to Assign";
                until ToItemChargeAssignmentPurch.Next() = 0;

                RemainingQty := FromPurchLine.Quantity - SumQtyToAssign;
                if RemainingQty <> 0 then
                    AddRemainingQtyToPurchItemCharge(ToItemChargeAssignmentPurch, RemainingQty);
            end;
        end;
    end;

    local procedure CopyFromSalesLineItemChargeAssign(FromSalesLine: Record "Sales Line"; ToSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header"; var ItemChargeAssgntNextLineNo: Integer)
    var
        ValueEntry: Record "Value Entry";
        Currency: Record Currency;
        TempToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)" temporary;
        ToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
        CurrencyFactor: Decimal;
        QtyToAssign: Decimal;
        SumQtyToAssign: Decimal;
        RemainingQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromSalesLineItemChargeAssign(FromSalesLine, ToSalesLine, FromSalesHeader, ItemChargeAssgntNextLineNo, IsHandled);
        if IsHandled then
            exit;

        if FromSalesLine."Document Type" = FromSalesLine."Document Type"::"Credit Memo" then
            ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Credit Memo")
        else
            ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");

        ValueEntry.SetRange("Document No.", FromSalesLine."Document No.");
        ValueEntry.SetRange("Document Line No.", FromSalesLine."Line No.");
        ValueEntry.SetRange("Item Charge No.", FromSalesLine."No.");
        ToItemChargeAssignmentSales."Document Type" := ToSalesLine."Document Type";
        ToItemChargeAssignmentSales."Document No." := ToSalesLine."Document No.";
        ToItemChargeAssignmentSales."Document Line No." := ToSalesLine."Line No.";
        ToItemChargeAssignmentSales."Item Charge No." := FromSalesLine."No.";
        ToItemChargeAssignmentSales."Unit Cost" := FromSalesLine."Unit Price";

        if ValueEntry.FindSet() then begin
            repeat
                if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then
                    if ItemLedgerEntry."Document Type" = ItemLedgerEntry."Document Type"::"Sales Shipment" then begin
                        Item.Get(ItemLedgerEntry."Item No.");
                        CurrencyFactor := FromSalesHeader."Currency Factor";

                        if not Currency.Get(FromSalesHeader."Currency Code") then begin
                            CurrencyFactor := 1;
                            Currency.InitRoundingPrecision();
                        end;

                        QtyToAssign :=
                          Sign(ToSalesLine.Quantity) * Abs(ValueEntry."Sales Amount (Actual)") * CurrencyFactor / ToSalesLine."Unit Price";
                        SumQtyToAssign += QtyToAssign;

                        ItemChargeAssgntSales.InsertItemChargeAssignmentWithValuesTo(
                          ToItemChargeAssignmentSales, ToItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment,
                          ItemLedgerEntry."Document No.", ItemLedgerEntry."Document Line No.", ItemLedgerEntry."Item No.", Item.Description,
                          QtyToAssign, 0, ItemChargeAssgntNextLineNo, TempToItemChargeAssignmentSales);
                    end;
                OnCopyFromSalesLineItemChargeAssignOnAfterValueEntryLoop(
                    FromSalesHeader, ToSalesLine, ValueEntry, TempToItemChargeAssignmentSales, ToItemChargeAssignmentSales,
                    ItemChargeAssgntNextLineNo, SumQtyToAssign);
            until ValueEntry.Next() = 0;
            ItemChargeAssgntSales.Summarize(TempToItemChargeAssignmentSales, ToItemChargeAssignmentSales);

            // Use 2 passes to correct rounding issues
            ToItemChargeAssignmentSales.SetRange("Document Type", ToSalesLine."Document Type");
            ToItemChargeAssignmentSales.SetRange("Document No.", ToSalesLine."Document No.");
            ToItemChargeAssignmentSales.SetRange("Document Line No.", ToSalesLine."Line No.");
            if ToItemChargeAssignmentSales.FindSet(true) then begin
                RemainingQty := (FromSalesLine.Quantity - SumQtyToAssign) / ValueEntry.Count();
                SumQtyToAssign := 0;
                repeat
                    AddRemainingQtyToSalesItemCharge(ToItemChargeAssignmentSales, RemainingQty);
                    SumQtyToAssign += ToItemChargeAssignmentSales."Qty. to Assign";
                until ToItemChargeAssignmentSales.Next() = 0;

                RemainingQty := FromSalesLine.Quantity - SumQtyToAssign;
                if RemainingQty <> 0 then
                    AddRemainingQtyToSalesItemCharge(ToItemChargeAssignmentSales, RemainingQty);
            end;
        end;
    end;

    local procedure AddRemainingQtyToPurchItemCharge(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; RemainingQty: Decimal)
    begin
        ItemChargeAssignmentPurch.Validate(
          "Qty. to Assign", Round(ItemChargeAssignmentPurch."Qty. to Assign" + RemainingQty, UOMMgt.QtyRndPrecision()));
        ItemChargeAssignmentPurch.Modify(true);
    end;

    local procedure AddRemainingQtyToSalesItemCharge(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; RemainingQty: Decimal)
    begin
        ItemChargeAssignmentSales.Validate(
          "Qty. to Assign", Round(ItemChargeAssignmentSales."Qty. to Assign" + RemainingQty, UOMMgt.QtyRndPrecision()));
        ItemChargeAssignmentSales.Modify(true);
    end;

    local procedure WarnSalesInvoicePmtDisc(var ToSalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From"; FromDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if HideDialog then
            exit;

        if IncludeHeader and
           (ToSalesHeader."Document Type" in
            [ToSalesHeader."Document Type"::"Return Order", ToSalesHeader."Document Type"::"Credit Memo"])
        then begin
            CustLedgEntry.SetCurrentKey("Document No.");
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
            CustLedgEntry.SetRange("Document No.", FromDocNo);
            if CustLedgEntry.FindFirst() then
                if (CustLedgEntry."Pmt. Disc. Given (LCY)" <> 0) and
                   (CustLedgEntry."Journal Batch Name" = '')
                then
                    Message(Text006, FromDocType, FromDocNo);
        end;

        if IncludeHeader and
           (ToSalesHeader."Document Type" in
            [ToSalesHeader."Document Type"::Invoice, ToSalesHeader."Document Type"::Order,
             ToSalesHeader."Document Type"::Quote, ToSalesHeader."Document Type"::"Blanket Order"]) and
           (FromDocType = "Sales Document Type From"::"Posted Return Receipt")
        then begin
            CustLedgEntry.SetCurrentKey("Document No.");
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
            CustLedgEntry.SetRange("Document No.", FromDocNo);
            if CustLedgEntry.FindFirst() then
                if (CustLedgEntry."Pmt. Disc. Given (LCY)" <> 0) and
                   (CustLedgEntry."Journal Batch Name" = '')
                then
                    Message(Text006, FromDocType, FromDocNo);
        end;
    end;

    local procedure WarnPurchInvoicePmtDisc(var ToPurchHeader: Record "Purchase Header"; FromDocType: Enum "Purchase Document Type From"; FromDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if HideDialog then
            exit;

        if IncludeHeader and
           (ToPurchHeader."Document Type" in
            [ToPurchHeader."Document Type"::"Return Order", ToPurchHeader."Document Type"::"Credit Memo"])
        then begin
            VendLedgEntry.SetCurrentKey("Document No.");
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
            VendLedgEntry.SetRange("Document No.", FromDocNo);
            if VendLedgEntry.FindFirst() then
                if (VendLedgEntry."Pmt. Disc. Rcd.(LCY)" <> 0) and
                   (VendLedgEntry."Journal Batch Name" = '')
                then
                    Message(Text009, FromDocType, FromDocNo);
        end;

        if IncludeHeader and
           (ToPurchHeader."Document Type" in
            [ToPurchHeader."Document Type"::Invoice, ToPurchHeader."Document Type"::Order,
             ToPurchHeader."Document Type"::Quote, ToPurchHeader."Document Type"::"Blanket Order"]) and
           (FromDocType = "Purchase Document Type From"::"Posted Return Shipment")
        then begin
            VendLedgEntry.SetCurrentKey("Document No.");
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
            VendLedgEntry.SetRange("Document No.", FromDocNo);
            if VendLedgEntry.FindFirst() then
                if (VendLedgEntry."Pmt. Disc. Rcd.(LCY)" <> 0) and
                   (VendLedgEntry."Journal Batch Name" = '')
                then
                    Message(Text006, FromDocType, FromDocNo);
        end;
    end;

    local procedure CheckCopyFromSalesHeaderAvail(FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header")
    var
        FromSalesLine: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
    begin
        if ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice] then begin
            FromSalesLine.SetRange("Document Type", FromSalesHeader."Document Type");
            FromSalesLine.SetRange("Document No.", FromSalesHeader."No.");
            FromSalesLine.SetRange(Type, FromSalesLine.Type::Item);
            FromSalesLine.SetFilter("No.", '<>%1', '');
            FromSalesLine.SetFilter(Quantity, '>0');
            OnCheckCopyFromSalesHeaderAvailOnAfterSetFilters(FromSalesLine, FromSalesHeader, ToSalesHeader);
            if FromSalesLine.FindSet() then
                repeat
                    if not IsItemOrVariantBlocked(FromSalesLine."No.", FromSalesLine."Variant Code") then begin
                        ToSalesLine.CopyFromSalesLine(FromSalesLine);
                        if ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::Order then
                            ToSalesLine."Outstanding Quantity" := FromSalesLine.Quantity - FromSalesLine."Qty. to Assemble to Order";
                        CheckItemAvailability(ToSalesHeader, ToSalesLine);
                        OnCheckCopyFromSalesHeaderAvailOnAfterCheckItemAvailability(
                          ToSalesHeader, ToSalesLine, FromSalesHeader, IncludeHeader, FromSalesLine);

                        if ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::Order then begin
                            ToSalesLine."Outstanding Quantity" := FromSalesLine.Quantity;
                            if ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::Order then
                                ToSalesLine."Outstanding Quantity" := FromSalesLine.Quantity - FromSalesLine."Qty. to Assemble to Order";
                            ToSalesLine."Qty. to Assemble to Order" := 0;
                            ToSalesLine."Drop Shipment" := FromSalesLine."Drop Shipment";
                            CheckItemAvailability(ToSalesHeader, ToSalesLine);

                            if ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::Order then begin
                                ToSalesLine."Outstanding Quantity" := FromSalesLine.Quantity;
                                ToSalesLine."Qty. to Assemble to Order" := FromSalesLine."Qty. to Assemble to Order";
                                CheckATOItemAvailable(FromSalesLine, ToSalesLine);
                            end;
                        end;
                    end;
                until FromSalesLine.Next() = 0;
        end;
    end;

    local procedure CheckCopyFromSalesShptAvail(FromSalesShptHeader: Record "Sales Shipment Header"; ToSalesHeader: Record "Sales Header")
    var
        FromSalesShptLine: Record "Sales Shipment Line";
        ToSalesLine: Record "Sales Line";
        FromPostedAsmHeader: Record "Posted Assembly Header";
    begin
        if not (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice]) then
            exit;

        FromSalesShptLine.SetRange("Document No.", FromSalesShptHeader."No.");
        FromSalesShptLine.SetRange(Type, FromSalesShptLine.Type::Item);
        FromSalesShptLine.SetFilter("No.", '<>%1', '');
        FromSalesShptLine.SetFilter(Quantity, '>0');
        OnCheckCopyFromSalesShptAvailOnAfterSetFilters(FromSalesShptLine, FromSalesShptHeader, ToSalesHeader);
        if FromSalesShptLine.FindSet() then
            repeat
                if not IsItemOrVariantBlocked(FromSalesShptLine."No.", FromSalesShptLine."Variant Code") then begin
                    ToSalesLine.CopyFromSalesShptLine(FromSalesShptLine);
                    if ToSalesLine."Document Type" = ToSalesLine."Document Type"::Order then
                        if FromSalesShptLine.AsmToShipmentExists(FromPostedAsmHeader) then
                            ToSalesLine."Outstanding Quantity" := FromSalesShptLine.Quantity - FromPostedAsmHeader.Quantity;
                    CheckItemAvailability(ToSalesHeader, ToSalesLine);
                    OnCheckCopyFromSalesShptAvailOnAfterCheckItemAvailability(
                      ToSalesHeader, ToSalesLine, FromSalesShptHeader, IncludeHeader, FromSalesShptLine);

                    if ToSalesLine."Document Type" = ToSalesLine."Document Type"::Order then
                        if FromSalesShptLine.AsmToShipmentExists(FromPostedAsmHeader) then begin
                            ToSalesLine."Qty. to Assemble to Order" := FromPostedAsmHeader.Quantity;
                            CheckPostedATOItemAvailable(FromSalesShptLine, ToSalesLine);
                        end;
                end;
            until FromSalesShptLine.Next() = 0;
    end;

    local procedure CheckCopyFromSalesInvoiceAvail(FromSalesInvHeader: Record "Sales Invoice Header"; ToSalesHeader: Record "Sales Header")
    var
        FromSalesInvLine: Record "Sales Invoice Line";
        ToSalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCopyFromSalesInvoiceAvail(FromSalesInvHeader, ToSalesHeader, FromSalesInvLine, ToSalesLine, IsHandled);
        if IsHandled then
            exit;

        if not (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice]) then
            exit;

        FromSalesInvLine.SetRange("Document No.", FromSalesInvHeader."No.");
        FromSalesInvLine.SetRange(Type, FromSalesInvLine.Type::Item);
        FromSalesInvLine.SetFilter("No.", '<>%1', '');
        FromSalesInvLine.SetRange("Prepayment Line", false);
        FromSalesInvLine.SetFilter(Quantity, '>0');
        OnCheckCopyFromSalesInvoiceAvailOnAfterSetFilters(FromSalesInvLine, FromSalesInvHeader, ToSalesHeader);
        if FromSalesInvLine.FindSet() then
            repeat
                if not IsItemOrVariantBlocked(FromSalesInvLine."No.", FromSalesInvLine."Variant Code") then begin
                    ToSalesLine.CopyFromSalesInvLine(FromSalesInvLine);
                    CheckCopyFromSalesInvoiceAvailOnBeforeCheckItemAvailability(ToSalesLine, FromSalesInvLine, ToSalesHeader, FromSalesInvHeader);
                    CheckItemAvailability(ToSalesHeader, ToSalesLine);
                    OnCheckCopyFromSalesInvoiceAvailOnAfterCheckItemAvailability(
                      ToSalesHeader, ToSalesLine, FromSalesInvHeader, IncludeHeader, FromSalesInvLine);
                end;
            until FromSalesInvLine.Next() = 0;
    end;

    local procedure CheckCopyFromSalesRetRcptAvail(FromReturnRcptHeader: Record "Return Receipt Header"; ToSalesHeader: Record "Sales Header")
    var
        FromReturnRcptLine: Record "Return Receipt Line";
        ToSalesLine: Record "Sales Line";
    begin
        if not (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice]) then
            exit;

        FromReturnRcptLine.SetRange("Document No.", FromReturnRcptHeader."No.");
        FromReturnRcptLine.SetRange(Type, FromReturnRcptLine.Type::Item);
        FromReturnRcptLine.SetFilter("No.", '<>%1', '');
        FromReturnRcptLine.SetFilter(Quantity, '>0');
        OnCheckCopyFromSalesRetRcptAvailOnAfterSetFilters(FromReturnRcptLine, FromReturnRcptHeader, ToSalesHeader);
        if FromReturnRcptLine.FindSet() then
            repeat
                if not IsItemOrVariantBlocked(FromReturnRcptLine."No.", FromReturnRcptLine."Variant Code") then begin
                    ToSalesLine.CopyFromReturnRcptLine(FromReturnRcptLine);
                    CheckItemAvailability(ToSalesHeader, ToSalesLine);
                    OnCheckCopyFromSalesRetRcptAvailOnAfterCheckItemAvailability(
                      ToSalesHeader, ToSalesLine, FromReturnRcptHeader, IncludeHeader, FromReturnRcptLine);
                end;
            until FromReturnRcptLine.Next() = 0;
    end;

    local procedure CheckCopyFromSalesCrMemoAvail(FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; ToSalesHeader: Record "Sales Header")
    var
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
        ToSalesLine: Record "Sales Line";
    begin
        if not (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice]) then
            exit;

        FromSalesCrMemoLine.SetRange("Document No.", FromSalesCrMemoHeader."No.");
        FromSalesCrMemoLine.SetRange(Type, FromSalesCrMemoLine.Type::Item);
        FromSalesCrMemoLine.SetFilter("No.", '<>%1', '');
        FromSalesCrMemoLine.SetRange("Prepayment Line", false);
        FromSalesCrMemoLine.SetFilter(Quantity, '>0');
        OnCheckCopyFromSalesCrMemoAvailOnAfterSetFilters(FromSalesCrMemoLine, FromSalesCrMemoHeader, ToSalesHeader);
        if FromSalesCrMemoLine.FindSet() then
            repeat
                if not IsItemOrVariantBlocked(FromSalesCrMemoLine."No.", FromSalesCrMemoLine."Variant Code") then begin
                    ToSalesLine.CopyFromSalesCrMemoLine(FromSalesCrMemoLine);
                    OnCheckCopyFromSalesCrMemoAvailOnBeforeCheckItemAvailability(FromSalesCrMemoLine, ToSalesLine);
                    CheckItemAvailability(ToSalesHeader, ToSalesLine);
                    OnCheckCopyFromSalesCrMemoAvailOnAfterCheckItemAvailability(
                      ToSalesHeader, ToSalesLine, FromSalesCrMemoHeader, IncludeHeader, FromSalesCrMemoLine);
                end;
            until FromSalesCrMemoLine.Next() = 0;
    end;

    local procedure CheckCopyFromSalesHeaderArchiveAvail(FromSalesHeaderArchive: Record "Sales Header Archive"; ToSalesHeader: Record "Sales Header")
    var
        FromSalesLineArchive: Record "Sales Line Archive";
        ToSalesLine: Record "Sales Line";
    begin
        OnBeforeCheckCopyFromSalesHeaderArchiveAvail(FromSalesHeaderArchive, ToSalesHeader, MoveNegLines);
        if not (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice]) then
            exit;

        FromSalesLineArchive.SetRange("Document Type", FromSalesHeaderArchive."Document Type");
        FromSalesLineArchive.SetRange("Document No.", FromSalesHeaderArchive."No.");
        FromSalesLineArchive.SetRange("Doc. No. Occurrence", FromSalesHeaderArchive."Doc. No. Occurrence");
        FromSalesLineArchive.SetRange("Version No.", FromSalesHeaderArchive."Version No.");
        FromSalesLineArchive.SetRange(Type, FromSalesLineArchive.Type::Item);
        FromSalesLineArchive.SetFilter("No.", '<>%1', '');
        OnCheckCopyFromSalesHeaderArchiveAvailOnAfterSetFilters(FromSalesLineArchive, FromSalesHeaderArchive, ToSalesHeader);
        if FromSalesLineArchive.FindSet() then
            repeat
                if FromSalesLineArchive.Quantity > 0 then begin
                    ToSalesLine."No." := FromSalesLineArchive."No.";
                    ToSalesLine."Variant Code" := FromSalesLineArchive."Variant Code";
                    ToSalesLine."Location Code" := FromSalesLineArchive."Location Code";
                    ToSalesLine."Bin Code" := FromSalesLineArchive."Bin Code";
                    ToSalesLine."Unit of Measure Code" := FromSalesLineArchive."Unit of Measure Code";
                    ToSalesLine."Qty. per Unit of Measure" := FromSalesLineArchive."Qty. per Unit of Measure";
                    ToSalesLine."Outstanding Quantity" := FromSalesLineArchive.Quantity;
                    CheckItemAvailability(ToSalesHeader, ToSalesLine);
                    OnCheckCopyFromSalesHeaderArchiveAvailOnAfterCheckItemAvailability(ToSalesHeader, ToSalesLine,
                    FromSalesHeaderArchive, FromSalesLineArchive, IncludeHeader);
                end;
            until FromSalesLineArchive.Next() = 0;
    end;

    local procedure CheckItemAvailability(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckItemAvailability(ToSalesHeader, ToSalesLine, HideDialog, IsHandled, RecalculateLines);
        if IsHandled then
            exit;

        if HideDialog then
            exit;

        ToSalesLine."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine."Document No." := ToSalesHeader."No.";
        ToSalesLine.Type := ToSalesLine.Type::Item;
        ToSalesLine."Purchase Order No." := '';
        ToSalesLine."Purch. Order Line No." := 0;
        ToSalesLine."Drop Shipment" :=
          not RecalculateLines and ToSalesLine."Drop Shipment" and
          (ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::Order);

        SetShipmentDateInLine(ToSalesHeader, ToSalesLine);

        IsHandled := false;
        OnCheckItemAvailabilityOnBeforeRunSalesLineCheck(ToSalesHeader, ToSalesLine, IsHandled);
        if not IsHandled then
            if ItemCheckAvail.SalesLineCheck(ToSalesLine) then
                ItemCheckAvail.RaiseUpdateInterruptedError();
    end;

    local procedure InitShipmentDateInLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        if SalesHeader."Shipment Date" <> 0D then
            SalesLine."Shipment Date" := SalesHeader."Shipment Date"
        else
            SalesLine."Shipment Date" := WorkDate();
        OnAfterInitShipmentDateInLine(SalesHeader, SalesLine);
    end;

    local procedure SetShipmentDateInLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        OnBeforeSetShipmentDateInLine(SalesHeader, SalesLine);
        if SalesLine."Shipment Date" = 0D then begin
            InitShipmentDateInLine(SalesHeader, SalesLine);
            SalesLine.Validate("Shipment Date");
        end;
    end;

    local procedure CheckATOItemAvailable(var FromSalesLine: Record "Sales Line"; ToSalesLine: Record "Sales Line")
    var
        ATOLink: Record "Assemble-to-Order Link";
        AsmHeader: Record "Assembly Header";
        TempAsmHeader: Record "Assembly Header" temporary;
        TempAsmLine: Record "Assembly Line" temporary;
    begin
        if HideDialog then
            exit;

        if ATOLink.ATOCopyCheckAvailShowWarning(
             AsmHeader, ToSalesLine, TempAsmHeader, TempAsmLine,
             not FromSalesLine.AsmToOrderExists(AsmHeader))
        then
            if ItemCheckAvail.ShowAsmWarningYesNo(TempAsmHeader, TempAsmLine) then
                ItemCheckAvail.RaiseUpdateInterruptedError();
    end;

    local procedure CheckPostedATOItemAvailable(var FromSalesShptLine: Record "Sales Shipment Line"; ToSalesLine: Record "Sales Line")
    var
        ATOLink: Record "Assemble-to-Order Link";
        PostedAsmHeader: Record "Posted Assembly Header";
        TempAsmHeader: Record "Assembly Header" temporary;
        TempAsmLine: Record "Assembly Line" temporary;
    begin
        if HideDialog then
            exit;

        if ATOLink.PstdATOCopyCheckAvailShowWarn(
             PostedAsmHeader, ToSalesLine, TempAsmHeader, TempAsmLine,
             not FromSalesShptLine.AsmToShipmentExists(PostedAsmHeader))
        then
            if ItemCheckAvail.ShowAsmWarningYesNo(TempAsmHeader, TempAsmLine) then
                ItemCheckAvail.RaiseUpdateInterruptedError();
    end;

#if not CLEAN24
    [Obsolete('Replaced by same procedure in codeunit CopyServiceContractMgt.', '24.0')]
    procedure CopyServContractLines(ToServContractHeader: Record "Service Contract Header"; FromDocType: Option; FromDocNo: Code[20]; var FromServContractLine: Record "Service Contract Line") AllLinesCopied: Boolean
    var
        CopyServiceContractMgt: Codeunit "Copy Service Contract Mgt.";
    begin
        exit(CopyServiceContractMgt.CopyServiceContractLines(ToServContractHeader, "Service Contract Type From".FromInteger(FromDocType), FromDocNo, FromServContractLine));
    end;
#endif

#if not CLEAN24
    [Obsolete('Replaced by procedure GetServiceContractType() in codeunit CopyServiceContractMgt.', '24.0')]
    procedure ServContractHeaderDocType(DocType: Option): Integer
    var
        ServContractHeader: Record "Service Contract Header";
        ServDocType: Option Quote,Contract;
    begin
        case DocType of
            ServDocType::Quote:
                exit(ServContractHeader."Contract Type"::Quote.AsInteger());
            ServDocType::Contract:
                exit(ServContractHeader."Contract Type"::Contract.AsInteger());
        end;
    end;
#endif

    procedure CopySalesShptLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromSalesShptLine: Record "Sales Shipment Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        FromSalesLineBuf: Record "Sales Line" temporary;
        FromSalesShptHeader: Record "Sales Shipment Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocSalesLine: Record "Sales Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
        IsHandled: Boolean;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToSalesHeader."Currency Code");
        OpenWindow();

        OnBeforeCopySalesShptLinesToDoc(TempDocSalesLine, ToSalesHeader, FromSalesShptLine);

        if FromSalesShptLine.FindSet() then
            repeat
                FromLineCounter := FromLineCounter + 1;
                if IsTimeForUpdate() then
                    UpdateWindow(1, FromLineCounter);
                if FromSalesShptHeader."No." <> FromSalesShptLine."Document No." then begin
                    FromSalesShptHeader.Get(FromSalesShptLine."Document No.");
                    TransferOldExtLines.ClearLineNumbers();
                end;

                IsHandled := false;
                OnCopySalesShptLinesToDocOnBeforeTestPricesInclVAT(ToSalesHeader, IncludeHeader, RecalculateLines, IsHandled);
                if not IsHandled then
                    FromSalesShptHeader.TestField("Prices Including VAT", ToSalesHeader."Prices Including VAT");
                FromSalesShptHeader.TestField("Prices Including VAT", ToSalesHeader."Prices Including VAT");

                OnCopySalesShptLinesToDocOnBeforeFromSalesHeaderTransferFields(FromSalesShptHeader, FromSalesHeader, ToSalesHeader, FromSalesShptLine);
                FromSalesHeader.TransferFields(FromSalesShptHeader);
                OnCopySalesShptLinesToDocOnAfterFromSalesHeaderTransferFields(FromSalesShptHeader, FromSalesHeader);
                FillExactCostRevLink :=
                  IsSalesFillExactCostRevLink(ToSalesHeader, 0, FromSalesHeader."Currency Code");
                FromSalesLine.TransferFields(FromSalesShptLine);
                FromSalesLine."Appl.-from Item Entry" := 0;
                FromSalesLine."Copied From Posted Doc." := true;

                CheckUpdateOldDocumentNoFromSalesShptLine(FromSalesShptLine, OldDocNo, InsertDocNoLine);

                OnBeforeCopySalesShptLinesToBuffer(FromSalesLine, FromSalesShptLine, ToSalesHeader);

                SplitLine := true;
                FromSalesShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                OnCopySalesShptLinesToDocOnBeforeSplitPstdSalesLinesPerILE(ItemLedgEntry, FromSalesShptLine);
                if not SplitPstdSalesLinesPerILE(
                     ToSalesHeader, FromSalesHeader, ItemLedgEntry, FromSalesLineBuf,
                     FromSalesLine, TempDocSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, true)
                then
                    if CopyItemTrkg then
                        SplitLine :=
                          SplitSalesDocLinesPerItemTrkg(
                            ItemLedgEntry, TempItemTrkgEntry, FromSalesLineBuf,
                            FromSalesLine, TempDocSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, true)
                    else
                        SplitLine := false;

                if not SplitLine then begin
                    FromSalesLineBuf := FromSalesLine;
                    CopyLine := true;
                end else
                    CopyLine := FromSalesLineBuf.FindSet() and FillExactCostRevLink;

                OnCopySalesShptLinesToDocOnAfterSplitPstdSalesLinesPerILE(FromSalesLineBuf, FromSalesShptLine);

                UpdateWindow(1, FromLineCounter);
                if CopyLine then begin
                    NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                    OnCopySalesShptLinesToDocOnAfterCalcNextLineNo(ToSalesHeader, FromSalesShptLine, FromSalesHeader, NextLineNo, InsertDocNoLine);
                    AsmHdrExistsForFromDocLine := FromSalesShptLine.AsmToShipmentExists(PostedAsmHeader);
                    InitAsmCopyHandling(true);
                    if AsmHdrExistsForFromDocLine then begin
                        QtyToAsmToOrder := FromSalesShptLine.Quantity;
                        QtyToAsmToOrderBase := FromSalesShptLine."Quantity (Base)";
                        GenerateAsmDataFromPosted(PostedAsmHeader, ToSalesHeader."Document Type");
                    end;
                    if InsertDocNoLine then begin
                        InsertOldSalesDocNoLine(ToSalesHeader, FromSalesShptLine."Document No.", 1, NextLineNo);
                        InsertDocNoLine := false;
                    end;
                    repeat
                        ToLineCounter := ToLineCounter + 1;
                        if IsTimeForUpdate() then
                            UpdateWindow(2, ToLineCounter);

                        OnCopySalesShptLinesToDocOnBeforeCopySalesLine(ToSalesHeader, FromSalesLineBuf, FromSalesShptLine, CopyItemTrkg);

                        if CopySalesDocLine(
                             ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLineBuf, NextLineNo, LinesNotCopied, false,
                             "Sales Document Type From"::"Posted Shipment", CopyPostedDeferral, FromSalesLineBuf."Line No.")
                        then begin
                            if CopyItemTrkg then begin
                                if SplitLine then
                                    ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                      TempItemTrkgEntry, TempTrkgItemLedgEntry, false, FromSalesLineBuf."Document No.", FromSalesLineBuf."Line No.")
                                else
                                    ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntry);

                                ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
                                  TempTrkgItemLedgEntry, ToSalesLine,
                                  FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                                  FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT", true);
                            end;
                            OnAfterCopySalesLineFromSalesShptLineBuffer(
                              ToSalesLine, FromSalesShptLine, IncludeHeader, RecalculateLines, TempDocSalesLine, ToSalesHeader, FromSalesLineBuf, ExactCostRevMandatory);
                        end;
                        OnCopySalesShptLinesToDocOnAfterCopySalesLine(ToSalesHeader, ToSalesLine, FromSalesShptLine);
                    until FromSalesLineBuf.Next() = 0;
                end;
                OnCopySalesShptLinesToDocOnAfterCopySalesShptLineToSalesLine(FromSalesShptLine, ToSalesLine);
            until FromSalesShptLine.Next() = 0;

        CloseWindow();

        OnAfterCopySalesShptLinesToDoc(ToSalesHeader, FromSalesShptLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CheckUpdateOldDocumentNoFromSalesShptLine(FromSalesShptLine: Record "Sales Shipment Line"; var OldDocNo: Code[20]; var InsertDocNoLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUpdateOldDocumentNoFromSalesShptLine(FromSalesShptLine, OldDocNo, InsertDocNoLine, IsHandled);
        if IsHandled then
            exit;

        if FromSalesShptLine."Document No." <> OldDocNo then begin
            OldDocNo := FromSalesShptLine."Document No.";
            InsertDocNoLine := true;
        end;
    end;

    procedure CopySalesInvLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromSalesInvLine: Record "Sales Invoice Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        FromSalesLine2: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        TempSalesLineBuf: Record "Sales Line" temporary;
        FromSalesInvHeader: Record "Sales Invoice Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocSalesLine: Record "Sales Line" temporary;
        OldInvDocNo: Code[20];
        OldShptDocNo: Code[20];
        OldBufDocNo: Code[20];
        NextLineNo: Integer;
        SalesCombDocLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        SalesInvLineCount: Integer;
        SalesLineCount: Integer;
        BufferCount: Integer;
        FirstLineShipped: Boolean;
        IsHandled: Boolean;
        FirstLineText: Boolean;
        ItemChargeAssgntNextLineNo: Integer;
        ShouldInsertOldSalesDocNoLine: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopySalesInvLinesToDoc(ToSalesHeader, FromSalesInvLine, CopyJobData, RecalculateLines, IsHandled);
        if IsHandled then
            exit;

        MissingExCostRevLink := false;
        InitCurrency(ToSalesHeader."Currency Code");
        TempSalesLineBuf.Reset();
        TempSalesLineBuf.DeleteAll();
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.DeleteAll();
        OpenWindow();
        InitAsmCopyHandling(true);
        TempSalesInvLine.DeleteAll();

        OnBeforeCopySalesInvLines(TempDocSalesLine, ToSalesHeader, FromSalesInvLine, CopyJobData);

        // Fill sales line buffer
        SalesInvLineCount := 0;
        FirstLineText := false;
        if FromSalesInvLine.FindSet() then
            repeat
                FromLineCounter := FromLineCounter + 1;
                if IsTimeForUpdate() then
                    UpdateWindow(1, FromLineCounter);
                SetTempSalesInvLine(FromSalesInvLine, TempSalesInvLine, SalesInvLineCount, NextLineNo, FirstLineText);
                if FromSalesInvHeader."No." <> FromSalesInvLine."Document No." then begin
                    FromSalesInvHeader.Get(FromSalesInvLine."Document No.");
                    TransferOldExtLines.ClearLineNumbers();
                    OnCopySalesInvLinesToDocOnAfterGetFromSalesInvHeader(ToSalesHeader, FromSalesInvHeader);
                end;

                IsHandled := false;
                OnCopySalesInvLinesToDocOnBeforeTestPricesInclVAT(ToSalesHeader, IncludeHeader, RecalculateLines, IsHandled);
                if not IsHandled then
                    FromSalesInvHeader.TestField("Prices Including VAT", ToSalesHeader."Prices Including VAT");

                OnCopySalesInvLinesToDocOnBeforeFromSalesHeaderTransferFields(FromSalesHeader, FromSalesInvHeader, ToSalesHeader, FromSalesInvLine);
                FromSalesHeader.TransferFields(FromSalesInvHeader);
                OnCopySalesInvLinesToDocOnAfterFromSalesHeaderTransferFields(FromSalesHeader, FromSalesInvHeader);
                FillExactCostRevLink := IsSalesFillExactCostRevLink(ToSalesHeader, 1, FromSalesHeader."Currency Code");
                FromSalesLine.TransferFields(FromSalesInvLine);
                FromSalesLine."Appl.-from Item Entry" := 0;
                // Reuse fields to buffer invoice line information
                FromSalesLine."Shipment No." := FromSalesInvLine."Document No.";
                FromSalesLine."Shipment Line No." := 0;
                FromSalesLine."Return Receipt No." := '';
                FromSalesLine."Return Receipt Line No." := FromSalesInvLine."Line No.";
                FromSalesLine."Copied From Posted Doc." := true;

                OnBeforeCopySalesInvLinesToBuffer(FromSalesLine, FromSalesInvLine, ToSalesHeader);

                SplitLine := true;
                FromSalesInvLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                if not SplitPstdSalesLinesPerILE(
                     ToSalesHeader, FromSalesHeader, ItemLedgEntryBuf, TempSalesLineBuf,
                     FromSalesLine, TempDocSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, false)
                then
                    if CopyItemTrkg then
                        SplitLine := SplitSalesDocLinesPerItemTrkg(
                            ItemLedgEntryBuf, TempItemTrkgEntry, TempSalesLineBuf,
                            FromSalesLine, TempDocSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, false)
                    else
                        SplitLine := false;

                if not SplitLine then
                    CopySalesLinesToBuffer(
                      FromSalesHeader, FromSalesLine, FromSalesLine2, TempSalesLineBuf,
                      ToSalesHeader, TempDocSalesLine, FromSalesInvLine."Document No.", NextLineNo);

                if TempSalesLineBuf."Shipment Line No." <> 0 then
                    SkipOldInvoiceDescription(true);

                OnAfterCopySalesInvLine(TempDocSalesLine, ToSalesHeader, TempSalesLineBuf, FromSalesInvLine);
            until FromSalesInvLine.Next() = 0;

        OnCopySalesInvLinesToDocOnAfterFillSalesLinesBuffer(ToSalesHeader);

        // Create sales line from buffer
        UpdateWindow(1, FromLineCounter);
        BufferCount := 0;
        FirstLineShipped := true;

        OnCopySalesInvLinesToDocOnBeforeTempSalesLineBufLoop(ToSalesHeader, TempSalesLineBuf);

        // Sorting according to Sales Line Document No.,Line No.
        TempSalesLineBuf.SetCurrentKey("Line No.");
        SalesLineCount := 0;
        if TempSalesLineBuf.FindSet() then
            repeat
                if TempSalesLineBuf.Type = TempSalesLineBuf.Type::Item then
                    SalesLineCount += 1;
            until TempSalesLineBuf.Next() = 0;
        if TempSalesLineBuf.FindSet() then begin
            NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
            repeat
                ToLineCounter := ToLineCounter + 1;
                if IsTimeForUpdate() then
                    UpdateWindow(2, ToLineCounter);
                ShouldInsertOldSalesDocNoLine := TempSalesLineBuf."Shipment No." <> OldInvDocNo;
                OnCopySalesInvLinesToDocOnAfterCalcShouldInsertOldSalesDocNoLine(TempSalesLineBuf, ToSalesHeader, ShouldInsertOldSalesDocNoLine);
                if ShouldInsertOldSalesDocNoLine then begin
                    OldInvDocNo := TempSalesLineBuf."Shipment No.";
                    OldShptDocNo := '';
                    FirstLineShipped := true;
                    OnCopySalesInvLinesToDocOnBeforeInsertOldSalesDocNoLine(ToSalesHeader, SkipCopyFromDescription);
                    InsertOldSalesDocNoLine(ToSalesHeader, OldInvDocNo, 2, NextLineNo);
                    OnCopySalesInvLinesToDocOnAfterInsertOldSalesDocNoLine(ToSalesHeader, SkipCopyFromDescription);
                end;
                CheckFirstLineShipped(TempSalesLineBuf."Document No.", TempSalesLineBuf."Shipment Line No.", SalesCombDocLineNo, NextLineNo, FirstLineShipped);
                OnCopySalesInvLinesToDocOnAfterCheckFirstLineShipped(ToSalesHeader, 2, TempSalesLineBuf."Document No.", OldShptDocNo);
                if (TempSalesLineBuf."Document No." <> OldShptDocNo) and (TempSalesLineBuf."Shipment Line No." > 0) then begin
                    if FirstLineShipped then
                        SalesCombDocLineNo := NextLineNo;
                    OldShptDocNo := TempSalesLineBuf."Document No.";
                    InsertOldSalesCombDocNoLine(ToSalesHeader, OldInvDocNo, OldShptDocNo, SalesCombDocLineNo, true);
                    NextLineNo := NextLineNo + 10000;
                    FirstLineShipped := true;
                end;

                InitFromSalesLine(FromSalesLine2, TempSalesLineBuf);
                if GetSalesDocNo(TempDocSalesLine, TempSalesLineBuf."Line No.") <> OldBufDocNo then begin
                    OldBufDocNo := GetSalesDocNo(TempDocSalesLine, TempSalesLineBuf."Line No.");
                    TransferOldExtLines.ClearLineNumbers();
                end;

                OnCopySalesInvLinesToDocOnBeforeCopySalesLine(ToSalesHeader, FromSalesLine2, TempSalesLineBuf,
                    ToSalesLine, FromSalesInvLine, IncludeHeader, RecalculateLines,
                    TempDocSalesLine, FromSalesLine, ExactCostRevMandatory);

                AsmHdrExistsForFromDocLine := false;
                if (TempSalesLineBuf.Type = TempSalesLineBuf.Type::Item) and (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Quote, ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::"Blanket Order"]) then
                    CheckAsmHdrExistsForFromDocLine(ToSalesHeader, FromSalesLine2, BufferCount, SalesLineCount = SalesInvLineCount);

                if CopySalesDocLine(
                    ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine2, NextLineNo, LinesNotCopied, TempSalesLineBuf."Return Receipt No." = '',
                    "Sales Document Type From"::"Posted Invoice", CopyPostedDeferral, GetSalesLineNo(TempDocSalesLine, FromSalesLine2."Line No."))
                then begin
                    if CopyPostedDeferral then
                        CopySalesPostedDeferrals(ToSalesLine, "Deferral Document Type"::Sales,
                          DeferralTypeForSalesDoc("Sales Document Type From"::"Posted Invoice".AsInteger()), TempSalesLineBuf."Shipment No.", TempSalesLineBuf."Return Receipt Line No.",
                          ToSalesLine."Document Type".AsInteger(), ToSalesLine."Document No.", ToSalesLine."Line No.");
                    FromSalesInvLine.Get(TempSalesLineBuf."Shipment No.", TempSalesLineBuf."Return Receipt Line No.");
                    OnCopySalesInvLinesToDocOnAfterCopySalesPostedDeferrals(FromSalesInvLine, NextLineNo, ToSalesLine, TempSalesLineBuf);
                    // copy item charges
                    if TempSalesLineBuf.Type = TempSalesLineBuf.Type::"Charge (Item)" then begin
                        FromSalesLine.TransferFields(FromSalesInvLine);
                        FromSalesLine."Document Type" := FromSalesLine."Document Type"::Invoice;
                        CopyFromSalesLineItemChargeAssign(FromSalesLine, ToSalesLine, FromSalesHeader, ItemChargeAssgntNextLineNo);
                    end;

                    IsHandled := false;
                    OnCopySalesInvLinesToDocOnBeforeCopyItemTracking(TempSalesLineBuf, ToSalesHeader, FromSalesInvLine, ItemLedgEntryBuf, TempItemTrkgEntry, IsHandled);
                    // copy item tracking
                    if not IsHandled then
                        if (TempSalesLineBuf.Type = TempSalesLineBuf.Type::Item) and (TempSalesLineBuf.Quantity <> 0) and SalesDocCanReceiveTracking(ToSalesHeader) then begin
                            FromSalesInvLine."Document No." := OldInvDocNo;
                            FromSalesInvLine."Line No." := TempSalesLineBuf."Return Receipt Line No.";
                            FromSalesInvLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                            if IsCopyItemTrkg(ItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) then begin
                                CopyItemLedgEntryTrackingToSalesLine(
                                  ItemLedgEntryBuf, TempItemTrkgEntry, TempSalesLineBuf, ToSalesLine, ToSalesHeader."Prices Including VAT",
                                  FromSalesHeader."Prices Including VAT", FillExactCostRevLink, MissingExCostRevLink);
                                OnCopySalesInvLinesToDocOnAfterCopyItemLedgEntryTrackingToSalesLine(ToSalesLine);
                            end;
                        end;

                    OnAfterCopySalesLineFromSalesLineBuffer(
                      ToSalesLine, FromSalesInvLine, IncludeHeader, RecalculateLines, TempDocSalesLine, ToSalesHeader, TempSalesLineBuf,
                      FromSalesLine2, FromSalesLine, ExactCostRevMandatory, FromSalesInvHeader);
                end;
                OnCopySalesInvLinesToDocOnAfterCopySalesDocLine(ToSalesLine, FromSalesInvLine);
            until TempSalesLineBuf.Next() = 0;
        end;
        CloseWindow();

        OnAfterCopySalesInvLinesToDoc(ToSalesHeader, FromSalesInvLine, LinesNotCopied, MissingExCostRevLink);
    end;

    procedure CopySalesCrMemoLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        FromSalesLine2: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        FromSalesLineBuf: Record "Sales Line" temporary;
        FromSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocSalesLine: Record "Sales Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldCrMemoDocNo: Code[20];
        OldReturnRcptDocNo: Code[20];
        OldBufDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        ItemChargeAssgntNextLineNo: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        ShouldCopyItemTracking: Boolean;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToSalesHeader."Currency Code");
        FromSalesLineBuf.Reset();
        FromSalesLineBuf.DeleteAll();
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.DeleteAll();
        OpenWindow();

        OnBeforeCopySalesCrMemoLinesToDoc(TempDocSalesLine, ToSalesHeader, FromSalesCrMemoLine, CopyJobData);

        // Fill sales line buffer
        if FromSalesCrMemoLine.FindSet() then
            repeat
                FromLineCounter := FromLineCounter + 1;
                if IsTimeForUpdate() then
                    UpdateWindow(1, FromLineCounter);
                if FromSalesCrMemoHeader."No." <> FromSalesCrMemoLine."Document No." then begin
                    FromSalesCrMemoHeader.Get(FromSalesCrMemoLine."Document No.");
                    TransferOldExtLines.ClearLineNumbers();
                end;
                OnCopySalesCrMemoLinesToDocOnBeforeFromSalesHeaderTransferFields(FromSalesCrMemoHeader, FromSalesHeader, ToSalesHeader, FromSalesCrMemoLine);
                FromSalesHeader.TransferFields(FromSalesCrMemoHeader);
                OnCopySalesCrMemoLinesToDocOnAfterFromSalesHeaderTransferFields(FromSalesCrMemoHeader, FromSalesHeader);
                FillExactCostRevLink :=
                  IsSalesFillExactCostRevLink(ToSalesHeader, 3, FromSalesHeader."Currency Code");
                FromSalesLine.TransferFields(FromSalesCrMemoLine);
                FromSalesLine."Appl.-from Item Entry" := 0;
                // Reuse fields to buffer credit memo line information
                FromSalesLine."Shipment No." := FromSalesCrMemoLine."Document No.";
                FromSalesLine."Shipment Line No." := 0;
                FromSalesLine."Return Receipt No." := '';
                FromSalesLine."Return Receipt Line No." := FromSalesCrMemoLine."Line No.";
                FromSalesLine."Copied From Posted Doc." := true;

                OnBeforeCopySalesCrMemoLinesToBuffer(FromSalesLine, FromSalesCrMemoLine, ToSalesHeader);

                SplitLine := true;
                FromSalesCrMemoLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                if not SplitPstdSalesLinesPerILE(
                     ToSalesHeader, FromSalesHeader, ItemLedgEntryBuf, FromSalesLineBuf,
                     FromSalesLine, TempDocSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, false)
                then
                    if CopyItemTrkg then
                        SplitLine :=
                          SplitSalesDocLinesPerItemTrkg(
                            ItemLedgEntryBuf, TempItemTrkgEntry, FromSalesLineBuf,
                            FromSalesLine, TempDocSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, false)
                    else
                        SplitLine := false;

                if not SplitLine then
                    CopySalesLinesToBuffer(
                      FromSalesHeader, FromSalesLine, FromSalesLine2, FromSalesLineBuf,
                      ToSalesHeader, TempDocSalesLine, FromSalesCrMemoLine."Document No.", NextLineNo);
                OnAfterCopySalesCrMemoLine(TempDocSalesLine, ToSalesHeader, FromSalesLineBuf, FromSalesCrMemoLine, FromSalesLine);
            until FromSalesCrMemoLine.Next() = 0;

        OnCopySalesCrMemoLinesToDocOnAfterFillSalesLineBuffer(ToSalesHeader, FromSalesLineBuf);

        // Create sales line from buffer
        UpdateWindow(1, FromLineCounter);
        // Sorting according to Sales Line Document No.,Line No.
        FromSalesLineBuf.SetCurrentKey("Document Type", "Document No.", "Line No.");
        if FromSalesLineBuf.FindSet() then begin
            NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
            repeat
                ToLineCounter := ToLineCounter + 1;
                if IsTimeForUpdate() then
                    UpdateWindow(2, ToLineCounter);
                if FromSalesLineBuf."Shipment No." <> OldCrMemoDocNo then begin
                    OldCrMemoDocNo := FromSalesLineBuf."Shipment No.";
                    OldReturnRcptDocNo := '';
                    InsertOldSalesDocNoLine(ToSalesHeader, OldCrMemoDocNo, 4, NextLineNo);
                end;
                if (FromSalesLineBuf."Document No." <> OldReturnRcptDocNo) and (FromSalesLineBuf."Shipment Line No." > 0) then begin
                    OldReturnRcptDocNo := FromSalesLineBuf."Document No.";
                    InsertOldSalesCombDocNoLine(ToSalesHeader, OldCrMemoDocNo, OldReturnRcptDocNo, NextLineNo, false);
                end;
                // Empty buffer fields
                FromSalesLine2 := FromSalesLineBuf;
                FromSalesLine2."Shipment No." := '';
                FromSalesLine2."Shipment Line No." := 0;
                FromSalesLine2."Return Receipt No." := '';
                FromSalesLine2."Return Receipt Line No." := 0;
                if GetSalesDocNo(TempDocSalesLine, FromSalesLineBuf."Line No.") <> OldBufDocNo then begin
                    OldBufDocNo := GetSalesDocNo(TempDocSalesLine, FromSalesLineBuf."Line No.");
                    TransferOldExtLines.ClearLineNumbers();
                end;

                OnCopySalesCrMemoLinesToDocOnBeforeCopySalesLine(ToSalesHeader, FromSalesLine2, FromSalesLineBuf);

                if CopySalesDocLine(
                     ToSalesHeader, ToSalesLine, FromSalesHeader,
                     FromSalesLine2, NextLineNo, LinesNotCopied, FromSalesLineBuf."Return Receipt No." = '',
                     "Sales Document Type From"::"Posted Credit Memo", CopyPostedDeferral, GetSalesLineNo(TempDocSalesLine, FromSalesLine2."Line No."))
                then begin
                    if CopyPostedDeferral then
                        CopySalesPostedDeferrals(ToSalesLine, "Deferral Document Type"::Sales,
                          DeferralTypeForSalesDoc("Sales Document Type From"::"Posted Credit Memo".AsInteger()), FromSalesLineBuf."Shipment No.",
                          FromSalesLineBuf."Return Receipt Line No.", ToSalesLine."Document Type".AsInteger(), ToSalesLine."Document No.", ToSalesLine."Line No.");
                    FromSalesCrMemoLine.Get(FromSalesLineBuf."Shipment No.", FromSalesLineBuf."Return Receipt Line No.");
                    // copy item charges
                    if FromSalesLineBuf.Type = FromSalesLineBuf.Type::"Charge (Item)" then begin
                        FromSalesLine.TransferFields(FromSalesCrMemoLine);
                        FromSalesLine."Document Type" := FromSalesLine."Document Type"::"Credit Memo";
                        CopyFromSalesLineItemChargeAssign(FromSalesLine, ToSalesLine, FromSalesHeader, ItemChargeAssgntNextLineNo);
                    end;
                    // copy item tracking
                    ShouldCopyItemTracking := (FromSalesLineBuf.Type = FromSalesLineBuf.Type::Item) and (FromSalesLineBuf.Quantity <> 0);
                    OnCopySalesCrMemoLinesToDocOnAfterCalcShouldCopyItemTracking(ToSalesHeader, ShouldCopyItemTracking, ToSalesLine);
                    if ShouldCopyItemTracking then begin
                        FromSalesCrMemoLine."Document No." := OldCrMemoDocNo;
                        FromSalesCrMemoLine."Line No." := FromSalesLineBuf."Return Receipt Line No.";
                        FromSalesCrMemoLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                        if IsCopyItemTrkg(ItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) then begin
                            if MoveNegLines or not ExactCostRevMandatory then
                                ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntryBuf)
                            else
                                ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                  TempItemTrkgEntry, TempTrkgItemLedgEntry, false, FromSalesLineBuf."Document No.", FromSalesLineBuf."Line No.");

                            ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
                              TempTrkgItemLedgEntry, ToSalesLine,
                              FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                              FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT", false);
                            OnCopySalesCrMemoLinesToDocOnAfterCopyItemLedgEntryTrkgToSalesLn(ToSalesLine);
                        end;
                    end;
                    OnAfterCopySalesLineFromSalesCrMemoLineBuffer(
                      ToSalesLine, FromSalesCrMemoLine, IncludeHeader, RecalculateLines, TempDocSalesLine, ToSalesHeader, FromSalesLineBuf, FromSalesLine);
                end;
            until FromSalesLineBuf.Next() = 0;
        end;

        CloseWindow();

        OnAfterCopySalesCrMemoLinesToDoc(ToSalesHeader, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
    end;

    procedure CopySalesReturnRcptLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromReturnRcptLine: Record "Return Receipt Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        ToSalesLine: Record "Sales Line";
        FromSalesLineBuf: Record "Sales Line" temporary;
        FromReturnRcptHeader: Record "Return Receipt Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocSalesLine: Record "Sales Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToSalesHeader."Currency Code");
        OpenWindow();

        OnBeforeCopySalesReturnRcptLinesToDoc(TempDocSalesLine, ToSalesHeader, FromReturnRcptLine);

        if FromReturnRcptLine.FindSet() then
            repeat
                FromLineCounter := FromLineCounter + 1;
                if IsTimeForUpdate() then
                    UpdateWindow(1, FromLineCounter);
                if FromReturnRcptHeader."No." <> FromReturnRcptLine."Document No." then begin
                    FromReturnRcptHeader.Get(FromReturnRcptLine."Document No.");
                    TransferOldExtLines.ClearLineNumbers();
                end;
                OnCopySalesReturnRcptLinesToDocOnBeforeFromSalesHeaderTransferFields(FromReturnRcptHeader, FromSalesHeader, ToSalesHeader, FromReturnRcptLine);
                FromSalesHeader.TransferFields(FromReturnRcptHeader);
                OnCopySalesReturnRcptLinesToDocOnAfterFromSalesHeaderTransferFields(FromReturnRcptHeader, FromSalesHeader);
                FillExactCostRevLink :=
                  IsSalesFillExactCostRevLink(ToSalesHeader, 2, FromSalesHeader."Currency Code");
                FromSalesLine.TransferFields(FromReturnRcptLine);
                FromSalesLine."Appl.-from Item Entry" := 0;
                FromSalesLine."Copied From Posted Doc." := true;

                CheckUpdateOldDocumentNoFromReturnRcptLine(FromReturnRcptLine, OldDocNo, InsertDocNoLine);

                OnBeforeCopySalesReturnRcptLinesToBuffer(FromSalesLine, FromReturnRcptLine, ToSalesHeader);

                SplitLine := true;
                FromReturnRcptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                if not SplitPstdSalesLinesPerILE(
                     ToSalesHeader, FromSalesHeader, ItemLedgEntry, FromSalesLineBuf,
                     FromSalesLine, TempDocSalesLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, true)
                then
                    if CopyItemTrkg then
                        SplitLine :=
                          SplitSalesDocLinesPerItemTrkg(
                            ItemLedgEntry, TempItemTrkgEntry, FromSalesLineBuf,
                            FromSalesLine, TempDocSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, true)
                    else
                        SplitLine := false;

                if not SplitLine then begin
                    FromSalesLineBuf := FromSalesLine;
                    CopyLine := true;
                end else
                    CopyLine := FromSalesLineBuf.FindSet() and FillExactCostRevLink;

                UpdateWindow(1, FromLineCounter);

                OnCopySalesReturnRcptLinesToDocOnBeforeCopyLines(ToSalesHeader, FromReturnRcptLine, FromSalesLineBuf);

                if CopyLine then begin
                    NextLineNo := GetLastToSalesLineNo(ToSalesHeader);
                    OnCopySalesReturnRcptLinesToDocOnAfterCalcNextLineNo(ToSalesHeader, FromReturnRcptLine, FromSalesHeader, NextLineNo, InsertDocNoLine);
                    if InsertDocNoLine then begin
                        InsertOldSalesDocNoLine(ToSalesHeader, FromReturnRcptLine."Document No.", 3, NextLineNo);
                        InsertDocNoLine := false;
                    end;
                    repeat
                        ToLineCounter := ToLineCounter + 1;
                        if IsTimeForUpdate() then
                            UpdateWindow(2, ToLineCounter);
                        OnCopySalesReturnRcptLinesToDocOnBeforeCopySalesDocLine(ToSalesHeader, FromSalesLineBuf, CopyItemTrkg);
                        if CopySalesDocLine(
                             ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLineBuf, NextLineNo, LinesNotCopied, false,
                             "Sales Document Type From"::"Posted Return Receipt", CopyPostedDeferral, FromSalesLineBuf."Line No.")
                        then begin
                            if CopyItemTrkg then begin
                                if SplitLine then
                                    ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                      TempItemTrkgEntry, TempTrkgItemLedgEntry, false, FromSalesLineBuf."Document No.", FromSalesLineBuf."Line No.")
                                else
                                    ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntry);

                                ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
                                  TempTrkgItemLedgEntry, ToSalesLine,
                                  FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                                  FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT", true);
                            end;
                            OnAfterCopySalesLineFromReturnRcptLineBuffer(
                              ToSalesLine, FromReturnRcptLine, IncludeHeader, RecalculateLines,
                              TempDocSalesLine, ToSalesHeader, FromSalesLineBuf, CopyItemTrkg);
                        end;
                    until FromSalesLineBuf.Next() = 0
                end;
                OnCopySalesReturnRcptLinesToDocOnAfterCopySalesDocLine(FromReturnRcptLine, ToSalesLine);
            until FromReturnRcptLine.Next() = 0;

        CloseWindow();

        OnAfterCopySalesReturnRcptLinesToDoc(ToSalesHeader, FromReturnRcptLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CheckUpdateOldDocumentNoFromReturnRcptLine(FromReturnRcptLine: Record "Return Receipt Line"; var OldDocNo: Code[20]; var InsertDocNoLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUpdateOldDocumentNoFromReturnRcptLine(FromReturnRcptLine, OldDocNo, InsertDocNoLine, IsHandled);
        if IsHandled then
            exit;

        if FromReturnRcptLine."Document No." <> OldDocNo then begin
            OldDocNo := FromReturnRcptLine."Document No.";
            InsertDocNoLine := true;
        end;
    end;

    local procedure CopySalesLinesToBuffer(FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; var FromSalesLine2: Record "Sales Line"; var TempSalesLineBuf: Record "Sales Line" temporary; ToSalesHeader: Record "Sales Header"; var TempDocSalesLine: Record "Sales Line" temporary; DocNo: Code[20]; var NextLineNo: Integer)
    begin
        FromSalesLine2 := TempSalesLineBuf;
        TempSalesLineBuf := FromSalesLine;
        TempSalesLineBuf."Document No." := '';
        TempSalesLineBuf."Line No." := NextLineNo;
        OnAfterCopySalesLinesToBufferFields(TempSalesLineBuf, FromSalesLine2, FromSalesLine);

        NextLineNo := NextLineNo + 10000;
        if not IsRecalculateAmount(
             FromSalesHeader."Currency Code", ToSalesHeader."Currency Code",
             FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT")
        then
            TempSalesLineBuf."Return Receipt No." := DocNo;
        ReCalcSalesLine(FromSalesHeader, ToSalesHeader, TempSalesLineBuf);
        OnCopySalesLinesToBufferTransferFields(FromSalesHeader, FromSalesLine, TempSalesLineBuf);
        TempSalesLineBuf.Insert();
        AddSalesDocLine(TempDocSalesLine, TempSalesLineBuf."Line No.", DocNo, FromSalesLine."Line No.");
    end;

    local procedure CopyItemLedgEntryTrackingToSalesLine(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TempReservationEntry: Record "Reservation Entry" temporary; TempFromSalesLine: Record "Sales Line" temporary; ToSalesLine: Record "Sales Line"; ToSalesPricesInctVAT: Boolean; FromSalesPricesInctVAT: Boolean; FillExactCostRevLink: Boolean; var MissingExCostRevLink: Boolean)
    var
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        AssemblyHeader: Record "Assembly Header";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        if MoveNegLines or not ExactCostRevMandatory then
            ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, TempItemLedgEntry)
        else
            ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
              TempReservationEntry, TempTrkgItemLedgEntry, false, TempFromSalesLine."Document No.", TempFromSalesLine."Line No.");

        if ToSalesLine.AsmToOrderExists(AssemblyHeader) then
            SetTrackingOnAssemblyReservation(AssemblyHeader, TempItemLedgEntry)
        else
            ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
              TempTrkgItemLedgEntry, ToSalesLine, FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
              FromSalesPricesInctVAT, ToSalesPricesInctVAT, false);
    end;

    procedure SplitPstdSalesLinesPerILE(ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; var ItemLedgEntry: Record "Item Ledger Entry"; var TempSalesLineBuf: Record "Sales Line" temporary; FromSalesLine: Record "Sales Line"; var TempDocSalesLine: Record "Sales Line" temporary; var NextLineNo: Integer; var CopyItemTrkg: Boolean; var MissingExCostRevLink: Boolean; FillExactCostRevLink: Boolean; FromShptOrRcpt: Boolean) Result: Boolean
    var
        OrgQtyBase: Decimal;
        OneRecord: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSplitPstdSalesLinesPerILE(ToSalesHeader, FromSalesHeader, FromSalesLine, TempSalesLineBuf, FromShptOrRcpt, IsHandled);
        if IsHandled then
            exit(Result);

        if FromShptOrRcpt then begin
            TempSalesLineBuf.Reset();
            TempSalesLineBuf.DeleteAll();
        end else
            TempSalesLineBuf.Init();

        CopyItemTrkg := false;

        if (FromSalesLine.Type <> FromSalesLine.Type::Item) or (FromSalesLine.Quantity = 0) then
            exit(false);
        if IsCopyItemTrkg(ItemLedgEntry, CopyItemTrkg, FillExactCostRevLink) or
           not FillExactCostRevLink or MoveNegLines or
           not ExactCostRevMandatory
        then
            exit(false);

        OneRecord := ItemLedgEntry.count() = 1;
        ItemLedgEntry.FindSet();
        if ItemLedgEntry.Quantity >= 0 then begin
            TempSalesLineBuf."Document No." := ItemLedgEntry."Document No.";
            if GetSalesDocTypeForItemLedgEntry(ItemLedgEntry) in
               [TempSalesLineBuf."Document Type"::Order, TempSalesLineBuf."Document Type"::"Return Order"]
            then
                TempSalesLineBuf."Shipment Line No." := 1;
            OnSplitPstdSalesLinesPerILEOnAfterAssignShipmentLineNo(ItemLedgEntry, TempSalesLineBuf);
            exit(false);
        end;
        OrgQtyBase := FromSalesLine."Quantity (Base)";
        repeat
            OnSplitPstdSalesLinesPerILEOnBeforeItemLedgEntryLoop(ItemLedgEntry, FromSalesLine);
            if ItemLedgEntry."Shipped Qty. Not Returned" = 0 then
                SkippedLine := true;

            if ItemLedgEntry."Shipped Qty. Not Returned" < 0 then begin
                TempSalesLineBuf := FromSalesLine;

                if -ItemLedgEntry."Shipped Qty. Not Returned" < Abs(FromSalesLine."Quantity (Base)") then begin
                    if FromSalesLine."Quantity (Base)" > 0 then
                        TempSalesLineBuf."Quantity (Base)" := -ItemLedgEntry."Shipped Qty. Not Returned"
                    else
                        TempSalesLineBuf."Quantity (Base)" := ItemLedgEntry."Shipped Qty. Not Returned";
                    if TempSalesLineBuf."Qty. per Unit of Measure" = 0 then
                        TempSalesLineBuf.Quantity := TempSalesLineBuf."Quantity (Base)"
                    else
                        TempSalesLineBuf.Quantity :=
                          Round(
                            TempSalesLineBuf."Quantity (Base)" / TempSalesLineBuf."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                end;
                FromSalesLine."Quantity (Base)" := FromSalesLine."Quantity (Base)" - TempSalesLineBuf."Quantity (Base)";
                FromSalesLine.Quantity := FromSalesLine.Quantity - TempSalesLineBuf.Quantity;
                TempSalesLineBuf."Appl.-from Item Entry" := ItemLedgEntry."Entry No.";
                NextLineNo := NextLineNo + 1;
                TempSalesLineBuf."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                TempSalesLineBuf."Document No." := ItemLedgEntry."Document No.";
                if GetSalesDocTypeForItemLedgEntry(ItemLedgEntry) in
                   [TempSalesLineBuf."Document Type"::Order, TempSalesLineBuf."Document Type"::"Return Order"]
                then
                    TempSalesLineBuf."Shipment Line No." := 1;

                if not FromShptOrRcpt then
                    UpdateRevSalesLineAmount(
                      TempSalesLineBuf, OrgQtyBase,
                      FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT");

                OnSplitPstdSalesLinesPerILETransferFields(FromSalesHeader, FromSalesLine, TempSalesLineBuf, ToSalesHeader, ItemLedgEntry);
                TempSalesLineBuf.Insert();
                if OneRecord then
                    AddSalesDocLine(TempDocSalesLine, TempSalesLineBuf."Line No.", FromSalesLine."Document No.", FromSalesLine."Line No.")
                else
                    AddSalesDocLine(TempDocSalesLine, TempSalesLineBuf."Line No.", ItemLedgEntry."Document No.", TempSalesLineBuf."Line No.");
            end;
        until (ItemLedgEntry.Next() = 0) or (FromSalesLine."Quantity (Base)" = 0);

        if (FromSalesLine."Quantity (Base)" <> 0) and FillExactCostRevLink then
            MissingExCostRevLink := true;
        OnSplitPstdSalesLinesPerILEOnBeforeCheckUnappliedLines(ToSalesHeader, SkippedLine, MissingExCostRevLink);
        CheckUnappliedLines(SkippedLine, MissingExCostRevLink);
        exit(true);
    end;

    local procedure SplitSalesDocLinesPerItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var TempItemTrkgEntry: Record "Reservation Entry" temporary; var TempSalesLineBuf: Record "Sales Line" temporary; FromSalesLine: Record "Sales Line"; var TempDocSalesLine: Record "Sales Line" temporary; var NextLineNo: Integer; var NextItemTrkgEntryNo: Integer; var MissingExCostRevLink: Boolean; FromShptOrRcpt: Boolean): Boolean
    var
        SalesLineBuf: array[2] of Record "Sales Line" temporary;
        Tracked: Boolean;
        ReversibleQtyBase: Decimal;
        SignFactor: Integer;
        i: Integer;
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSplitSalesDocLinesPerItemTrkg(ItemLedgEntry, TempItemTrkgEntry, TempSalesLineBuf, FromSalesLine, TempDocSalesLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, FromShptOrRcpt, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if FromShptOrRcpt then begin
            TempSalesLineBuf.Reset();
            TempSalesLineBuf.DeleteAll();
            TempItemTrkgEntry.Reset();
            TempItemTrkgEntry.DeleteAll();
        end else
            TempSalesLineBuf.Init();

        if MoveNegLines or not ExactCostRevMandatory then
            exit(false);

        if FromSalesLine."Quantity (Base)" < 0 then
            SignFactor := -1
        else
            SignFactor := 1;
        OnSplitSalesDocLinesPerItemTrkgOnAfterCalcSignFactor(FromSalesLine, SignFactor);

        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgEntry.FindSet();
        repeat
            SalesLineBuf[1] := FromSalesLine;
            SalesLineBuf[1]."Line No." := NextLineNo;
            SalesLineBuf[1]."Quantity (Base)" := 0;
            SalesLineBuf[1].Quantity := 0;
            SalesLineBuf[1]."Document No." := ItemLedgEntry."Document No.";
            if GetSalesDocTypeForItemLedgEntry(ItemLedgEntry) in
               [SalesLineBuf[1]."Document Type"::Order, SalesLineBuf[1]."Document Type"::"Return Order"]
            then
                SalesLineBuf[1]."Shipment Line No." := 1;
            OnSplitSalesDocLinesPerItemTrkgOnAfterInitSalesLineBuf1(SalesLineBuf[1], ItemLedgEntry);
            SalesLineBuf[2] := SalesLineBuf[1];
            SalesLineBuf[2]."Line No." := SalesLineBuf[2]."Line No." + 1;

            if not FromShptOrRcpt then begin
                ItemLedgEntry.SetRange("Document No.", ItemLedgEntry."Document No.");
                ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type");
                ItemLedgEntry.SetRange("Document Line No.", ItemLedgEntry."Document Line No.");
            end;
            repeat
                i := 1;
                CalcReversibleQtyBaseSalesDoc(ItemLedgEntry, FromSalesLine, SalesLineBuf, TempItemTrkgEntry, ReversibleQtyBase, SignFactor);

                if ReversibleQtyBase <> 0 then begin
                    if not ItemLedgEntry.Positive then
                        if IsSplitItemLedgEntry(ItemLedgEntry) then
                            i := 2;

                    UpdateSalesLineQtyBaseFromReversibleQtyBase(FromSalesLine, SalesLineBuf[i], ReversibleQtyBase);
                    // Fill buffer with exact cost reversing link
                    InsertTempReservationEntry(
                      ItemLedgEntry, TempItemTrkgEntry, -Abs(ReversibleQtyBase),
                      SalesLineBuf[i]."Line No.", NextItemTrkgEntryNo, true);
                    Tracked := true;
                end;
            until (ItemLedgEntry.Next() = 0) or (FromSalesLine."Quantity (Base)" = 0);

            for i := 1 to 2 do
                if SalesLineBuf[i]."Quantity (Base)" <> 0 then begin
                    TempSalesLineBuf := SalesLineBuf[i];
                    TempSalesLineBuf.Insert();
                    AddSalesDocLine(TempDocSalesLine, TempSalesLineBuf."Line No.", ItemLedgEntry."Document No.", FromSalesLine."Line No.");
                    NextLineNo := SalesLineBuf[i]."Line No." + 1;
                end;

            if not FromShptOrRcpt then begin
                ItemLedgEntry.SetRange("Document No.");
                ItemLedgEntry.SetRange("Document Type");
                ItemLedgEntry.SetRange("Document Line No.");
            end;
        until (ItemLedgEntry.Next() = 0) or FromShptOrRcpt;

        if (FromSalesLine."Quantity (Base)" <> 0) and not Tracked then
            MissingExCostRevLink := true;
        CheckUnappliedLines(SkippedLine, MissingExCostRevLink);

        exit(true);
    end;

    local procedure CalcReversibleQtyBaseSalesDoc(var ItemLedgEntry: Record "Item Ledger Entry"; FromSalesLine: Record "Sales Line"; var SalesLineBuf: array[2] of Record "Sales Line" temporary; var TempItemTrkgEntry: Record "Reservation Entry" temporary; var ReversibleQtyBase: Decimal; SignFactor: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcReversibleQtyBaseSalesDoc(FromSalesLine, ItemLedgEntry, ReversibleQtyBase, IsHandled);
        if IsHandled then
            exit;

        if not ItemLedgEntry.Positive then
            ItemLedgEntry."Shipped Qty. Not Returned" :=
              ItemLedgEntry."Shipped Qty. Not Returned" -
              CalcDistributedQty(TempItemTrkgEntry, ItemLedgEntry, SalesLineBuf[2]."Line No." + 1);
        if ItemLedgEntry."Shipped Qty. Not Returned" = 0 then
            SkippedLine := true;

        if ItemLedgEntry."Document Type" in [ItemLedgEntry."Document Type"::"Sales Return Receipt", ItemLedgEntry."Document Type"::"Sales Credit Memo"] then
            if ItemLedgEntry."Remaining Quantity" < FromSalesLine."Quantity (Base)" * SignFactor then
                ReversibleQtyBase := ItemLedgEntry."Remaining Quantity" * SignFactor
            else
                ReversibleQtyBase := FromSalesLine."Quantity (Base)"
        else
            if ItemLedgEntry.Positive then begin
                ReversibleQtyBase := ItemLedgEntry."Remaining Quantity";
                if ReversibleQtyBase < FromSalesLine."Quantity (Base)" * SignFactor then
                    ReversibleQtyBase := ReversibleQtyBase * SignFactor
                else
                    ReversibleQtyBase := FromSalesLine."Quantity (Base)";
            end else
                if -ItemLedgEntry."Shipped Qty. Not Returned" < FromSalesLine."Quantity (Base)" * SignFactor then
                    ReversibleQtyBase := -ItemLedgEntry."Shipped Qty. Not Returned" * SignFactor
                else
                    ReversibleQtyBase := FromSalesLine."Quantity (Base)";
    end;

    local procedure UpdateSalesLineQtyBaseFromReversibleQtyBase(var FromSalesLine: Record "Sales Line"; var SalesLineBuf: Record "Sales Line" temporary; ReversibleQtyBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesLineQtyBaseFromReversibleQtyBase(FromSalesLine, SalesLineBuf, ReversibleQtyBase, IsHandled);
        if IsHandled then
            exit;

        SalesLineBuf."Quantity (Base)" := SalesLineBuf."Quantity (Base)" + ReversibleQtyBase;
        if SalesLineBuf."Qty. per Unit of Measure" = 0 then
            SalesLineBuf.Quantity := SalesLineBuf."Quantity (Base)"
        else
            SalesLineBuf.Quantity :=
              Round(
                SalesLineBuf."Quantity (Base)" / SalesLineBuf."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        FromSalesLine."Quantity (Base)" := FromSalesLine."Quantity (Base)" - ReversibleQtyBase;
    end;

    procedure CopyPurchRcptLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        OriginalPurchHeader: Record "Purchase Header";
        ToPurchLine: Record "Purchase Line";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromPurchRcptHeader: Record "Purch. Rcpt. Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocPurchaseLine: Record "Purchase Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        FillExactCostRevLink: Boolean;
        SplitLine: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCopyPurchRcptLinesToDoc(ToPurchHeader, FromPurchRcptLine);
        MissingExCostRevLink := false;
        InitCurrency(ToPurchHeader."Currency Code");
        OpenWindow();

        if FromPurchRcptLine.FindSet() then
            repeat
                FromLineCounter := FromLineCounter + 1;
                if IsTimeForUpdate() then
                    UpdateWindow(1, FromLineCounter);
                if FromPurchRcptHeader."No." <> FromPurchRcptLine."Document No." then begin
                    FromPurchRcptHeader.Get(FromPurchRcptLine."Document No.");
                    IsHandled := false;
                    OnCopyPurchRcptLinesToDocOnBeforeTestFieldPricesIncludingVAT(ToPurchHeader, IncludeHeader, RecalculateLines, FromPurchRcptHeader, IsHandled);
                    if not IsHandled then
                        if OriginalPurchHeader.Get(OriginalPurchHeader."Document Type"::Order, FromPurchRcptHeader."Order No.") then
                            OriginalPurchHeader.TestField("Prices Including VAT", ToPurchHeader."Prices Including VAT");
                    TransferOldExtLines.ClearLineNumbers();
                end;
                FromPurchHeader.TransferFields(FromPurchRcptHeader);
                FillExactCostRevLink :=
                  IsPurchFillExactCostRevLink(ToPurchHeader, 0, FromPurchHeader."Currency Code");
                FromPurchLine.TransferFields(FromPurchRcptLine);
                FromPurchLine."Appl.-to Item Entry" := 0;
                FromPurchLine."Copied From Posted Doc." := true;

                OnCopyPurchRcptLinesToDocOnAfterTransferFields(FromPurchLine, FromPurchHeader, ToPurchHeader, FromPurchRcptHeader, FromPurchRcptLine);

                CheckUpdateOldDocumentNoFromPurchRcptLine(FromPurchRcptLine, OldDocNo, InsertDocNoLine);

                SplitLine := true;
                FromPurchRcptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                OnCopyPurchRcptLinesToDocOnAfterFilterPstdDocLnItemLedgEntries(FromPurchLine, ItemLedgEntry);
                if not SplitPstdPurchLinesPerILE(
                     ToPurchHeader, FromPurchHeader, ItemLedgEntry, FromPurchLineBuf,
                     FromPurchLine, TempDocPurchaseLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, true)
                then
                    if CopyItemTrkg then
                        SplitLine :=
                          SplitPurchDocLinesPerItemTrkg(
                            ItemLedgEntry, TempItemTrkgEntry, FromPurchLineBuf,
                            FromPurchLine, TempDocPurchaseLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, true)
                    else
                        SplitLine := false;

                if not SplitLine then begin
                    FromPurchLineBuf := FromPurchLine;
                    CopyLine := true;
                end else
                    CopyLine := FromPurchLineBuf.FindSet() and FillExactCostRevLink;

                UpdateWindow(1, FromLineCounter);
                if CopyLine then begin
                    NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                    OnCopyPurchRcptLinesToDocOnBeforeCheckInsertDocNoLine(ToPurchHeader, FromPurchRcptLine, FromPurchHeader, NextLineNo, InsertDocNoLine);
                    if InsertDocNoLine then begin
                        InsertOldPurchDocNoLine(ToPurchHeader, FromPurchRcptLine."Document No.", 1, NextLineNo);
                        InsertDocNoLine := false;
                    end;
                    repeat
                        ToLineCounter := ToLineCounter + 1;
                        if IsTimeForUpdate() then
                            UpdateWindow(2, ToLineCounter);
                        if FromPurchLine."Prod. Order No." <> '' then
                            FromPurchLine."Quantity (Base)" := 0;

                        OnCopyPurchRcptLinesToDocOnBeforeCopyPurchLine(ToPurchHeader, FromPurchLineBuf, CopyItemTrkg);

                        if CopyPurchDocLine(
                             ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLineBuf, NextLineNo, LinesNotCopied, false,
                             "Purchase Document Type From"::"Posted Receipt", CopyPostedDeferral, FromPurchLineBuf."Line No.")
                        then begin
                            OnCopyPurchRcptLinesToDocOnBeforeCopyItemTrkg(ToPurchHeader, ToPurchLine, FromPurchLineBuf, RecalculateLines);
                            if CopyItemTrkg then begin
                                if SplitLine then
                                    ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                      TempItemTrkgEntry, TempTrkgItemLedgEntry, true, FromPurchLineBuf."Document No.", FromPurchLineBuf."Line No.")
                                else
                                    ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntry);

                                ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
                                  TempTrkgItemLedgEntry, ToPurchLine,
                                  FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                                  FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT", true);
                            end;
                            OnAfterCopyPurchLineFromPurchRcptLineBuffer(
                              ToPurchLine, FromPurchRcptLine, IncludeHeader, RecalculateLines,
                              TempDocPurchaseLine, ToPurchHeader, FromPurchLineBuf, CopyItemTrkg, NextLineNo);
                        end;
                    until FromPurchLineBuf.Next() = 0;
                    OnAfterCopyPurchRcptLine(FromPurchRcptLine, ToPurchLine);
                end;
            until FromPurchRcptLine.Next() = 0;

        CloseWindow();

        OnAfterCopyPurchRcptLinesToDoc(ToPurchHeader, FromPurchRcptLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CheckUpdateOldDocumentNoFromPurchRcptLine(FromPurchRcptLine: Record "Purch. Rcpt. Line"; var OldDocNo: Code[20]; var InsertDocNoLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUpdateOldDocumentNoFromPurchRcptLine(FromPurchRcptLine, OldDocNo, InsertDocNoLine, IsHandled);
        if IsHandled then
            exit;

        if FromPurchRcptLine."Document No." <> OldDocNo then begin
            OldDocNo := FromPurchRcptLine."Document No.";
            InsertDocNoLine := true;
        end;
    end;

    procedure CopyPurchInvLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromPurchInvLine: Record "Purch. Inv. Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        FromPurchLine2: Record "Purchase Line";
        ToPurchLine: Record "Purchase Line";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromPurchInvHeader: Record "Purch. Inv. Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocPurchaseLine: Record "Purchase Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldInvDocNo: Code[20];
        OldRcptDocNo: Code[20];
        OldBufDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        ItemChargeAssgntNextLineNo: Integer;
        ShouldInsertOldPurchDocNoLine: Boolean;
        ShouldCopyItemTrackingEntries: Boolean;
        IsHandled: Boolean;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToPurchHeader."Currency Code");
        FromPurchLineBuf.Reset();
        FromPurchLineBuf.DeleteAll();
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.DeleteAll();
        OpenWindow();

        OnBeforeCopyPurchInvLines(TempDocPurchaseLine, ToPurchHeader, FromPurchInvLine);

        // Fill purchase line buffer
        if FromPurchInvLine.FindSet() then
            repeat
                FromLineCounter := FromLineCounter + 1;
                if IsTimeForUpdate() then
                    UpdateWindow(1, FromLineCounter);
                if FromPurchInvHeader."No." <> FromPurchInvLine."Document No." then begin
                    FromPurchInvHeader.Get(FromPurchInvLine."Document No.");
                    IsHandled := false;
                    OnCopyPurchInvLinesToDocOnBeforeTestFieldPricesIncludingVAT(ToPurchHeader, IncludeHeader, RecalculateLines, FromPurchInvHeader, IsHandled);
                    if not IsHandled then
                        FromPurchInvHeader.TestField("Prices Including VAT", ToPurchHeader."Prices Including VAT");
                    TransferOldExtLines.ClearLineNumbers();
                end;
                FromPurchHeader.TransferFields(FromPurchInvHeader);
                FillExactCostRevLink := IsPurchFillExactCostRevLink(ToPurchHeader, 1, FromPurchHeader."Currency Code");
                FromPurchLine.TransferFields(FromPurchInvLine);
                FromPurchLine."Appl.-to Item Entry" := 0;
                // Reuse fields to buffer invoice line information
                FromPurchLine."Receipt No." := FromPurchInvLine."Document No.";
                FromPurchLine."Receipt Line No." := 0;
                FromPurchLine."Return Shipment No." := '';
                FromPurchLine."Return Shipment Line No." := FromPurchInvLine."Line No.";
                FromPurchLine."Copied From Posted Doc." := true;

                OnCopyPurchInvLinesToDocOnAfterTransferFields(FromPurchLine, FromPurchHeader, ToPurchHeader, FromPurchInvHeader, FromPurchInvLine);

                SplitLine := true;
                FromPurchInvLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                if not SplitPstdPurchLinesPerILE(
                     ToPurchHeader, FromPurchHeader, ItemLedgEntryBuf, FromPurchLineBuf,
                     FromPurchLine, TempDocPurchaseLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, false)
                then
                    if CopyItemTrkg then
                        SplitLine := SplitPurchDocLinesPerItemTrkg(
                            ItemLedgEntryBuf, TempItemTrkgEntry, FromPurchLineBuf,
                            FromPurchLine, TempDocPurchaseLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, false)
                    else
                        SplitLine := false;

                if not SplitLine then
                    CopyPurchLinesToBuffer(
                      FromPurchHeader, FromPurchLine, FromPurchLine2, FromPurchLineBuf, ToPurchHeader, TempDocPurchaseLine,
                      FromPurchInvLine."Document No.", NextLineNo);

                if FromPurchLineBuf."Receipt Line No." <> 0 then
                    SkipOldInvoiceDescription(true);

                OnAfterCopyPurchInvLines(TempDocPurchaseLine, ToPurchHeader, FromPurchLineBuf, FromPurchInvLine);
            until FromPurchInvLine.Next() = 0;

        OnCopyPurchInvLinesToDocOnAfterFillPurchLineBuffer(ToPurchHeader);

        // Create purchase line from buffer
        UpdateWindow(1, FromLineCounter);
        // Sorting according to Purchase Line Document No.,Line No.
        FromPurchLineBuf.SetCurrentKey("Line No.");
        if FromPurchLineBuf.FindSet() then begin
            NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
            repeat
                ToLineCounter := ToLineCounter + 1;
                if IsTimeForUpdate() then
                    UpdateWindow(2, ToLineCounter);

                IsHandled := false;
                OnCopyPurchInvLinesToDocOnBeforeInsertOldPurchLine(ToPurchHeader, FromPurchLineBuf, OldInvDocNo, OldRcptDocNo, NextLineNo, SkipCopyFromDescription, InsertCancellationLine, IsHandled);
                if not IsHandled then begin
                    ShouldInsertOldPurchDocNoLine := FromPurchLineBuf."Receipt No." <> OldInvDocNo;
                    OnCopyPurchInvLinesToDocOnAfterCalcShouldInsertOldPurchDocNoLine(ToPurchHeader, FromPurchInvHeader, FromPurchHeader, NextLineNo, OldInvDocNo, OldRcptDocNo, ShouldInsertOldPurchDocNoLine);
                    if ShouldInsertOldPurchDocNoLine then begin
                        OldInvDocNo := FromPurchLineBuf."Receipt No.";
                        OldRcptDocNo := '';
                        InsertOldPurchDocNoLine(ToPurchHeader, OldInvDocNo, 2, NextLineNo);
                    end;
                    if (FromPurchLineBuf."Document No." <> OldRcptDocNo) and (FromPurchLineBuf."Receipt Line No." > 0) then begin
                        OldRcptDocNo := FromPurchLineBuf."Document No.";
                        InsertOldPurchCombDocNoLine(ToPurchHeader, OldInvDocNo, OldRcptDocNo, NextLineNo, true);
                    end;
                end;
                // Empty buffer fields
                FromPurchLine2 := FromPurchLineBuf;
                FromPurchLine2."Receipt No." := '';
                FromPurchLine2."Receipt Line No." := 0;
                FromPurchLine2."Return Shipment No." := '';
                FromPurchLine2."Return Shipment Line No." := 0;
                if GetPurchDocNo(TempDocPurchaseLine, FromPurchLineBuf."Line No.") <> OldBufDocNo then begin
                    OldBufDocNo := GetPurchDocNo(TempDocPurchaseLine, FromPurchLineBuf."Line No.");
                    TransferOldExtLines.ClearLineNumbers();
                end;

                OnCopyPurchInvLinesToDocOnBeforeCopyPurchLine(ToPurchHeader, FromPurchLine2, FromPurchLineBuf);

                if CopyPurchDocLine(
                    ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine2, NextLineNo, LinesNotCopied,
                    FromPurchLineBuf."Return Shipment No." = '',
                    "Purchase Document Type From"::"Posted Invoice", CopyPostedDeferral, GetPurchLineNo(TempDocPurchaseLine, FromPurchLine2."Line No."))
                then begin
                    if CopyPostedDeferral then
                        CopyPurchPostedDeferrals(
                            ToPurchLine, "Deferral Document Type"::Purchase,
                            DeferralTypeForPurchDoc("Purchase Document Type From"::"Posted Invoice".AsInteger()), FromPurchLineBuf."Receipt No.",
                            FromPurchLineBuf."Return Shipment Line No.", ToPurchLine."Document Type".AsInteger(), ToPurchLine."Document No.", ToPurchLine."Line No.");
                    FromPurchInvLine.Get(FromPurchLineBuf."Receipt No.", FromPurchLineBuf."Return Shipment Line No.");

                    OnCopyPurchInvLinesToDocOnBeforeCopyItemCharges(FromPurchInvLine, NextLineNo, ToPurchLine, TempDocPurchaseLine, RecalculateLines);
                    // copy item charges
                    if FromPurchLineBuf.Type = FromPurchLineBuf.Type::"Charge (Item)" then begin
                        FromPurchLine.TransferFields(FromPurchInvLine);
                        FromPurchLine."Document Type" := FromPurchLine."Document Type"::Invoice;
                        CopyFromPurchLineItemChargeAssign(FromPurchLine, ToPurchLine, FromPurchHeader, ItemChargeAssgntNextLineNo);
                    end;
                    // copy item tracking
                    ShouldCopyItemTrackingEntries := (FromPurchLineBuf.Type = FromPurchLineBuf.Type::Item) and (FromPurchLineBuf.Quantity <> 0) and (FromPurchLineBuf."Prod. Order No." = '') and PurchaseDocCanReceiveTracking(ToPurchHeader);
                    OnCopyPurchInvLinesToDocOnAfterCalcShouldCopyItemTrackingEntries(ToPurchLine, ShouldCopyItemTrackingEntries);
                    if ShouldCopyItemTrackingEntries then begin
                        FromPurchInvLine."Document No." := OldInvDocNo;
                        FromPurchInvLine."Line No." := FromPurchLineBuf."Return Shipment Line No.";
                        FromPurchInvLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                        if IsCopyItemTrkg(ItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) then begin
                            if FromPurchLineBuf."Job No." <> '' then
                                ItemLedgEntryBuf.SetFilter("Entry Type", '<> %1', ItemLedgEntryBuf."Entry Type"::"Negative Adjmt.");
                            if MoveNegLines or not ExactCostRevMandatory then
                                ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntryBuf)
                            else
                                ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                  TempItemTrkgEntry, TempTrkgItemLedgEntry, true, FromPurchLineBuf."Document No.", FromPurchLineBuf."Line No.");

                            ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(TempTrkgItemLedgEntry, ToPurchLine,
                              FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                              FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT", false);
                        end;
                    end;
                    OnAfterCopyPurchLineFromPurchLineBuffer(
                      ToPurchLine, FromPurchInvLine, IncludeHeader, RecalculateLines, TempDocPurchaseLine, ToPurchHeader, FromPurchLineBuf);
                end;
                OnAfterCopyPurchInvLine(FromPurchInvLine, ToPurchLine, ToPurchHeader);
            until FromPurchLineBuf.Next() = 0;
        end;

        CloseWindow();

        OnAfterCopyPurchInvLinesToDoc(ToPurchHeader, FromPurchInvLine, LinesNotCopied, MissingExCostRevLink);
    end;

    procedure CopyPurchCrMemoLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        FromPurchLine2: Record "Purchase Line";
        ToPurchLine: Record "Purchase Line";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocPurchaseLine: Record "Purchase Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldCrMemoDocNo: Code[20];
        OldReturnShptDocNo: Code[20];
        OldBufDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        ItemChargeAssgntNextLineNo: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        ShouldCopyItemTrackingEntries: Boolean;
        IsHandled: Boolean;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToPurchHeader."Currency Code");
        FromPurchLineBuf.Reset();
        FromPurchLineBuf.DeleteAll();
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.DeleteAll();
        OpenWindow();

        OnBeforeCopyPurchCrMemoLinesToDoc(TempDocPurchaseLine, ToPurchHeader, FromPurchCrMemoLine);

        // Fill purchase line buffer
        if FromPurchCrMemoLine.FindSet() then
            repeat
                FromLineCounter := FromLineCounter + 1;
                if IsTimeForUpdate() then
                    UpdateWindow(1, FromLineCounter);
                if FromPurchCrMemoHeader."No." <> FromPurchCrMemoLine."Document No." then begin
                    FromPurchCrMemoHeader.Get(FromPurchCrMemoLine."Document No.");
                    IsHandled := false;
                    OnCopyPurchCrMemoLinesToDocOnBeforeTestFieldPricesIncludingVAT(ToPurchHeader, IncludeHeader, RecalculateLines, FromPurchCrMemoHeader, IsHandled);
                    if not IsHandled then
                        FromPurchCrMemoHeader.TestField("Prices Including VAT", ToPurchHeader."Prices Including VAT");
                    TransferOldExtLines.ClearLineNumbers();
                end;
                FromPurchHeader.TransferFields(FromPurchCrMemoHeader);
                FillExactCostRevLink :=
                  IsPurchFillExactCostRevLink(ToPurchHeader, 3, FromPurchHeader."Currency Code");
                FromPurchLine.TransferFields(FromPurchCrMemoLine);
                FromPurchLine."Appl.-to Item Entry" := 0;
                // Reuse fields to buffer credit memo line information
                FromPurchLine."Receipt No." := FromPurchCrMemoLine."Document No.";
                FromPurchLine."Receipt Line No." := 0;
                FromPurchLine."Return Shipment No." := '';
                FromPurchLine."Return Shipment Line No." := FromPurchCrMemoLine."Line No.";
                FromPurchLine."Copied From Posted Doc." := true;

                OnCopyPurchCrMemoLinesToDocOnAfterTransferFields(FromPurchLine, FromPurchHeader, ToPurchHeader, FromPurchCrMemoHeader, FromPurchCrMemoLine);

                SplitLine := true;
                FromPurchCrMemoLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                if not SplitPstdPurchLinesPerILE(
                     ToPurchHeader, FromPurchHeader, ItemLedgEntryBuf, FromPurchLineBuf,
                     FromPurchLine, TempDocPurchaseLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, false)
                then
                    if CopyItemTrkg then
                        SplitLine :=
                          SplitPurchDocLinesPerItemTrkg(
                            ItemLedgEntryBuf, TempItemTrkgEntry, FromPurchLineBuf,
                            FromPurchLine, TempDocPurchaseLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, false)
                    else
                        SplitLine := false;

                if not SplitLine then
                    CopyPurchLinesToBuffer(
                      FromPurchHeader, FromPurchLine, FromPurchLine2, FromPurchLineBuf, ToPurchHeader, TempDocPurchaseLine,
                      FromPurchCrMemoLine."Document No.", NextLineNo);
                OnCopyPurchCrMemoLinesToDocOnAfterFromPurchCrMemoLineLoop(TempDocPurchaseLine, ToPurchHeader, FromPurchLineBuf, FromPurchCrMemoLine, SplitLine);
            until FromPurchCrMemoLine.Next() = 0;

        OnCopyPurchCrMemoLinesToDocOnAfterFillPurchLineBuffer(ToPurchHeader);

        // Create purchase line from buffer
        UpdateWindow(1, FromLineCounter);
        // Sorting according to Purchase Line Document No.,Line No.
        FromPurchLineBuf.SetCurrentKey("Document Type", "Document No.", "Line No.");
        if FromPurchLineBuf.FindSet() then begin
            NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
            repeat
                ToLineCounter := ToLineCounter + 1;
                if IsTimeForUpdate() then
                    UpdateWindow(2, ToLineCounter);
                if FromPurchLineBuf."Receipt No." <> OldCrMemoDocNo then begin
                    OldCrMemoDocNo := FromPurchLineBuf."Receipt No.";
                    OldReturnShptDocNo := '';
                    InsertOldPurchDocNoLine(ToPurchHeader, OldCrMemoDocNo, 4, NextLineNo);
                end;
                if FromPurchLineBuf."Document No." <> OldReturnShptDocNo then begin
                    OldReturnShptDocNo := FromPurchLineBuf."Document No.";
                    InsertOldPurchCombDocNoLine(ToPurchHeader, OldCrMemoDocNo, OldReturnShptDocNo, NextLineNo, false);
                end;
                // Empty buffer fields
                FromPurchLine2 := FromPurchLineBuf;
                FromPurchLine2."Receipt No." := '';
                FromPurchLine2."Receipt Line No." := 0;
                FromPurchLine2."Return Shipment No." := '';
                FromPurchLine2."Return Shipment Line No." := 0;
                if GetPurchDocNo(TempDocPurchaseLine, FromPurchLineBuf."Line No.") <> OldBufDocNo then begin
                    OldBufDocNo := GetPurchDocNo(TempDocPurchaseLine, FromPurchLineBuf."Line No.");
                    TransferOldExtLines.ClearLineNumbers();
                end;

                OnCopyPurchCrMemoLinesToDocOnBeforeCopyPurchLine(ToPurchHeader, FromPurchLine2);

                if CopyPurchDocLine(
                    ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine2, NextLineNo, LinesNotCopied, FromPurchLineBuf."Return Shipment No." = '',
                    "Purchase Document Type From"::"Posted Credit Memo", CopyPostedDeferral, GetPurchLineNo(TempDocPurchaseLine, FromPurchLine2."Line No."))
                then begin
                    if CopyPostedDeferral then
                        CopyPurchPostedDeferrals(
                            ToPurchLine, "Deferral Document Type"::Purchase,
                            DeferralTypeForPurchDoc("Purchase Document Type From"::"Posted Credit Memo".AsInteger()), FromPurchLineBuf."Receipt No.",
                            FromPurchLineBuf."Return Shipment Line No.", ToPurchLine."Document Type".AsInteger(), ToPurchLine."Document No.", ToPurchLine."Line No.");
                    FromPurchCrMemoLine.Get(FromPurchLineBuf."Receipt No.", FromPurchLineBuf."Return Shipment Line No.");

                    OnCopyPurchCrMemoLinesToDocOnBeforeCopyItemCharges(ToPurchLine, FromPurchLineBuf, RecalculateLines);
                    // copy item charges
                    if FromPurchLineBuf.Type = FromPurchLineBuf.Type::"Charge (Item)" then begin
                        FromPurchLine.TransferFields(FromPurchCrMemoLine);
                        FromPurchLine."Document Type" := FromPurchLine."Document Type"::"Credit Memo";
                        CopyFromPurchLineItemChargeAssign(FromPurchLine, ToPurchLine, FromPurchHeader, ItemChargeAssgntNextLineNo);
                    end;
                    // copy item tracking
                    ShouldCopyItemTrackingEntries := (FromPurchLineBuf.Type = FromPurchLineBuf.Type::Item) and (FromPurchLineBuf.Quantity <> 0) and (FromPurchLineBuf."Prod. Order No." = '');
                    OnCopyPurchCrMemoLinesToDocOnAfterCalcShouldCopyItemTrackingEntries(ToPurchLine, ShouldCopyItemTrackingEntries);
                    if ShouldCopyItemTrackingEntries then begin
                        FromPurchCrMemoLine."Document No." := OldCrMemoDocNo;
                        FromPurchCrMemoLine."Line No." := FromPurchLineBuf."Return Shipment Line No.";
                        FromPurchCrMemoLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                        if IsCopyItemTrkg(ItemLedgEntryBuf, CopyItemTrkg, FillExactCostRevLink) then begin
                            if FromPurchLineBuf."Job No." <> '' then
                                ItemLedgEntryBuf.SetFilter("Entry Type", '<> %1', ItemLedgEntryBuf."Entry Type"::"Negative Adjmt.");
                            OnCopyPurchCrMemoLinesToDocOnAfterFilterEntryType(FromPurchLineBuf, ItemLedgEntryBuf);
                            if MoveNegLines or not ExactCostRevMandatory then
                                ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntryBuf)
                            else
                                ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                  TempItemTrkgEntry, TempTrkgItemLedgEntry, true, FromPurchLineBuf."Document No.", FromPurchLineBuf."Line No.");

                            ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
                              TempTrkgItemLedgEntry, ToPurchLine,
                              FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                              FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT", false);
                        end;
                    end;
                    OnAfterCopyPurchLineFromPurchCrMemoLineBuffer(
                      ToPurchLine, FromPurchCrMemoLine, IncludeHeader, RecalculateLines, TempDocPurchaseLine, ToPurchHeader, FromPurchLineBuf);
                end;
                OnAfterCopyPurchCrMemoLine(FromPurchCrMemoLine, ToPurchLine, ToPurchHeader);
            until FromPurchLineBuf.Next() = 0;
        end;

        CloseWindow();

        OnAfterCopyPurchCrMemoLinesToDoc(ToPurchHeader, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink);
    end;

    procedure CopyPurchReturnShptLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromReturnShptLine: Record "Return Shipment Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        OriginalPurchHeader: Record "Purchase Header";
        ToPurchLine: Record "Purchase Line";
        FromPurchLineBuf: Record "Purchase Line" temporary;
        FromReturnShptHeader: Record "Return Shipment Header";
        TempItemTrkgEntry: Record "Reservation Entry" temporary;
        TempDocPurchaseLine: Record "Purchase Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        OldDocNo: Code[20];
        NextLineNo: Integer;
        NextItemTrkgEntryNo: Integer;
        FromLineCounter: Integer;
        ToLineCounter: Integer;
        CopyItemTrkg: Boolean;
        SplitLine: Boolean;
        FillExactCostRevLink: Boolean;
        CopyLine: Boolean;
        InsertDocNoLine: Boolean;
        IsHandled: Boolean;
    begin
        MissingExCostRevLink := false;
        InitCurrency(ToPurchHeader."Currency Code");
        OpenWindow();

        OnBeforeCopyPurchReturnShptLinesToDoc(TempDocPurchaseLine, ToPurchHeader, FromReturnShptLine);

        if FromReturnShptLine.FindSet() then
            repeat
                FromLineCounter := FromLineCounter + 1;
                if IsTimeForUpdate() then
                    UpdateWindow(1, FromLineCounter);
                if FromReturnShptHeader."No." <> FromReturnShptLine."Document No." then begin
                    FromReturnShptHeader.Get(FromReturnShptLine."Document No.");
                    IsHandled := false;
                    OnCopyPurchReturnShptLinesToDocOnBeforeTestFieldPricesIncludingVAT(ToPurchHeader, IncludeHeader, RecalculateLines, FromReturnShptHeader, IsHandled);
                    if not IsHandled then
                        if OriginalPurchHeader.Get(OriginalPurchHeader."Document Type"::"Return Order", FromReturnShptHeader."Return Order No.") then
                            OriginalPurchHeader.TestField("Prices Including VAT", ToPurchHeader."Prices Including VAT");
                    TransferOldExtLines.ClearLineNumbers();
                end;
                FromPurchHeader.TransferFields(FromReturnShptHeader);
                FillExactCostRevLink :=
                  IsPurchFillExactCostRevLink(ToPurchHeader, 2, FromPurchHeader."Currency Code");
                FromPurchLine.TransferFields(FromReturnShptLine);
                FromPurchLine.Validate("Order No.", FromReturnShptLine."Return Order No.");
                FromPurchLine.Validate("Order Line No.", FromReturnShptLine."Return Order Line No.");
                FromPurchLine."Appl.-to Item Entry" := 0;
                FromPurchLine."Copied From Posted Doc." := true;

                OnCopyPurchReturnShptLinesToDocOnAfterTransferFields(FromPurchLine, FromPurchHeader, ToPurchHeader, FromReturnShptHeader, FromReturnShptLine);

                CheckUpdateOldDocumentNoFromReturnShptLine(FromReturnShptLine, OldDocNo, InsertDocNoLine);

                SplitLine := true;
                FromReturnShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                if not SplitPstdPurchLinesPerILE(
                     ToPurchHeader, FromPurchHeader, ItemLedgEntry, FromPurchLineBuf,
                     FromPurchLine, TempDocPurchaseLine, NextLineNo, CopyItemTrkg, MissingExCostRevLink, FillExactCostRevLink, true)
                then
                    if CopyItemTrkg then
                        SplitLine :=
                          SplitPurchDocLinesPerItemTrkg(
                            ItemLedgEntry, TempItemTrkgEntry, FromPurchLineBuf,
                            FromPurchLine, TempDocPurchaseLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, true)
                    else
                        SplitLine := false;

                if not SplitLine then begin
                    FromPurchLineBuf := FromPurchLine;
                    CopyLine := true;
                end else
                    CopyLine := FromPurchLineBuf.FindSet() and FillExactCostRevLink;

                UpdateWindow(1, FromLineCounter);
                if CopyLine then begin
                    NextLineNo := GetLastToPurchLineNo(ToPurchHeader);
                    OnCopyPurchReturnShptLinesToDocOnAfterCalcNextLineNo(ToPurchHeader, FromReturnShptLine, FromPurchHeader, NextLineNo, InsertDocNoLine);
                    if InsertDocNoLine then begin
                        InsertOldPurchDocNoLine(ToPurchHeader, FromReturnShptLine."Document No.", 3, NextLineNo);
                        InsertDocNoLine := false;
                    end;
                    repeat
                        ToLineCounter := ToLineCounter + 1;
                        if IsTimeForUpdate() then
                            UpdateWindow(2, ToLineCounter);

                        OnCopyPurchReturnShptLinesToDocOnBeforeCopyPurchLine(ToPurchHeader, FromPurchLineBuf, CopyItemTrkg);

                        if CopyPurchDocLine(
                            ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLineBuf, NextLineNo, LinesNotCopied, false,
                            "Purchase Document Type From"::"Posted Return Shipment", CopyPostedDeferral, FromPurchLineBuf."Line No.")
                        then begin
                            OnCopyPurchReturnShptLinesToDocOnBeforeCopyItemTrkg(ToPurchLine, FromPurchLineBuf, RecalculateLines);
                            if CopyItemTrkg then begin
                                if SplitLine then
                                    ItemTrackingDocMgt.CollectItemTrkgPerPostedDocLine(
                                      TempItemTrkgEntry, TempTrkgItemLedgEntry, true, FromPurchLineBuf."Document No.", FromPurchLineBuf."Line No.")
                                else
                                    ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntry);

                                ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
                                  TempTrkgItemLedgEntry, ToPurchLine,
                                  FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
                                  FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT", true);
                            end;
                            OnAfterCopyPurchLineFromReturnShptLineBuffer(
                              ToPurchLine, FromReturnShptLine, IncludeHeader, RecalculateLines,
                              TempDocPurchaseLine, ToPurchHeader, FromPurchLineBuf, CopyItemTrkg);
                        end;
                    until FromPurchLineBuf.Next() = 0;
                end;
                OnAfterCopyReturnShptLine(FromReturnShptLine, ToPurchLine);
            until FromReturnShptLine.Next() = 0;

        CloseWindow();

        OnAfterCopyPurchReturnShptLinesToDoc(ToPurchHeader, FromReturnShptLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CheckUpdateOldDocumentNoFromReturnShptLine(FromReturnShptLine: Record "Return Shipment Line"; var OldDocNo: Code[20]; var InsertDocNoLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUpdateOldDocumentNoFromReturnShptLine(FromReturnShptLine, OldDocNo, InsertDocNoLine, IsHandled);
        if IsHandled then
            exit;

        if FromReturnShptLine."Document No." <> OldDocNo then begin
            OldDocNo := FromReturnShptLine."Document No.";
            InsertDocNoLine := true;
        end;
    end;

    local procedure CopyPurchLinesToBuffer(FromPurchHeader: Record "Purchase Header"; FromPurchLine: Record "Purchase Line"; var FromPurchLine2: Record "Purchase Line"; var TempPurchLineBuf: Record "Purchase Line" temporary; ToPurchHeader: Record "Purchase Header"; var TempDocPurchaseLine: Record "Purchase Line" temporary; DocNo: Code[20]; var NextLineNo: Integer)
    begin
        FromPurchLine2 := TempPurchLineBuf;
        TempPurchLineBuf := FromPurchLine;
        TempPurchLineBuf."Document No." := '';
        TempPurchLineBuf."Line No." := NextLineNo;
        OnAfterCopyPurchLinesToBufferFields(TempPurchLineBuf, FromPurchLine2, FromPurchLine, ToPurchHeader);

        NextLineNo := NextLineNo + 10000;
        if not IsRecalculateAmount(
             FromPurchHeader."Currency Code", ToPurchHeader."Currency Code",
             FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT")
        then
            TempPurchLineBuf."Return Shipment No." := DocNo;
        ReCalcPurchLine(FromPurchHeader, ToPurchHeader, TempPurchLineBuf);
        TempPurchLineBuf.Insert();
        AddPurchDocLine(TempDocPurchaseLine, TempPurchLineBuf."Line No.", DocNo, FromPurchLine."Line No.");

        OnAfterCopyPurchLinesToBuffer(TempPurchLineBuf, FromPurchLine2, FromPurchLine);
    end;

    local procedure CreateJobPlanningLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; JobContractEntryNo: Integer): Integer
    var
        JobPlanningLine: Record "Job Planning Line";
        NewJobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateJobPlanningLine(SalesHeader, SalesLine, JobContractEntryNo, IsHandled);
        if IsHandled then
            exit;

        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", JobContractEntryNo);
        if JobPlanningLine.FindFirst() then begin
            NewJobPlanningLine.InitFromJobPlanningLine(JobPlanningLine, SalesLine.Quantity);

            JobPlanningLineInvoice.InitFromJobPlanningLine(NewJobPlanningLine);
            JobPlanningLineInvoice.InitFromSales(SalesHeader, SalesHeader."Posting Date", SalesLine."Line No.");
            JobPlanningLineInvoice.Insert();

            NewJobPlanningLine.UpdateQtyToTransfer();
            NewJobPlanningLine.Insert();
        end;

        exit(NewJobPlanningLine."Job Contract Entry No.");
    end;

    local procedure SplitPstdPurchLinesPerILE(ToPurchHeader: Record "Purchase Header"; FromPurchHeader: Record "Purchase Header"; var ItemLedgEntry: Record "Item Ledger Entry"; var FromPurchLineBuf: Record "Purchase Line"; FromPurchLine: Record "Purchase Line"; var TempDocPurchaseLine: Record "Purchase Line" temporary; var NextLineNo: Integer; var CopyItemTrkg: Boolean; var MissingExCostRevLink: Boolean; FillExactCostRevLink: Boolean; FromShptOrRcpt: Boolean) Result: Boolean
    var
        Item: Record Item;
        ApplyRec: Record "Item Application Entry";
        OrgQtyBase: Decimal;
        OneRecord: Boolean;
        IsHandled: Boolean;
    begin
        if FromShptOrRcpt then begin
            FromPurchLineBuf.Reset();
            FromPurchLineBuf.DeleteAll();
        end else
            FromPurchLineBuf.Init();

        CopyItemTrkg := false;

        if (FromPurchLine.Type <> FromPurchLine.Type::Item) or (FromPurchLine.Quantity = 0) or (FromPurchLine."Prod. Order No." <> '')
        then
            exit(false);

        Item.Get(FromPurchLine."No.");
        if Item.IsNonInventoriableType() then
            exit(false);

        if IsCopyItemTrkg(ItemLedgEntry, CopyItemTrkg, FillExactCostRevLink) or
           not FillExactCostRevLink or MoveNegLines or
           not ExactCostRevMandatory
        then
            exit(false);

        IsHandled := false;
        OnSplitPstdPurchLinesPerILEOnBeforeCheckJobNo(FromPurchLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if FromPurchLine."Job No." <> '' then
            exit(false);

        OneRecord := ItemLedgEntry.count() = 1;
        ItemLedgEntry.FindSet();
        if ItemLedgEntry.Quantity <= 0 then begin
            FromPurchLineBuf."Document No." := ItemLedgEntry."Document No.";
            if GetPurchDocTypeForItemLedgEntry(ItemLedgEntry) in
               [FromPurchLineBuf."Document Type"::Order, FromPurchLineBuf."Document Type"::"Return Order"]
            then
                FromPurchLineBuf."Receipt Line No." := 1;
            exit(false);
        end;
        OrgQtyBase := FromPurchLine."Quantity (Base)";
        repeat
            if not ApplyFully then begin
                ApplyRec.AppliedOutbndEntryExists(ItemLedgEntry."Entry No.", false, false);
                if ApplyRec.Find('-') then
                    SkippedLine := SkippedLine or ApplyRec.Find('-');
            end;
            if ApplyFully then begin
                ApplyRec.AppliedOutbndEntryExists(ItemLedgEntry."Entry No.", false, false);
                if ApplyRec.Find('-') then
                    repeat
                        SomeAreFixed := SomeAreFixed or ApplyRec.Fixed();
                    until ApplyRec.Next() = 0;
            end;

            if AskApply and (ItemLedgEntry."Item Tracking" = ItemLedgEntry."Item Tracking"::None) then
                if not (ItemLedgEntry."Remaining Quantity" > 0) or (ItemLedgEntry."Item Tracking" <> ItemLedgEntry."Item Tracking"::None) then
                    ConfirmApply();
            if AskApply then
                if ItemLedgEntry."Remaining Quantity" < Abs(FromPurchLine."Quantity (Base)") then
                    ConfirmApply();
            if (ItemLedgEntry."Remaining Quantity" > 0) or ApplyFully then begin
                FromPurchLineBuf := FromPurchLine;
                if ItemLedgEntry."Remaining Quantity" < Abs(FromPurchLine."Quantity (Base)") then
                    if not ApplyFully then begin
                        if FromPurchLine."Quantity (Base)" > 0 then
                            FromPurchLineBuf."Quantity (Base)" := ItemLedgEntry."Remaining Quantity"
                        else
                            FromPurchLineBuf."Quantity (Base)" := -ItemLedgEntry."Remaining Quantity";
                        ConvertFromBase(
                          FromPurchLineBuf.Quantity, FromPurchLineBuf."Quantity (Base)", FromPurchLineBuf."Qty. per Unit of Measure");
                    end else begin
                        ReappDone := true;
                        FromPurchLineBuf."Quantity (Base)" := Sign(ItemLedgEntry.Quantity) * ItemLedgEntry.Quantity - ApplyRec.Returned(ItemLedgEntry."Entry No.");
                        ConvertFromBase(
                          FromPurchLineBuf.Quantity, FromPurchLineBuf."Quantity (Base)", FromPurchLineBuf."Qty. per Unit of Measure");
                    end;
                FromPurchLine."Quantity (Base)" := FromPurchLine."Quantity (Base)" - FromPurchLineBuf."Quantity (Base)";
                FromPurchLine.Quantity := FromPurchLine.Quantity - FromPurchLineBuf.Quantity;
                FromPurchLineBuf."Appl.-to Item Entry" := ItemLedgEntry."Entry No.";
                NextLineNo := NextLineNo + 1;
                FromPurchLineBuf."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                FromPurchLineBuf."Document No." := ItemLedgEntry."Document No.";
                if GetPurchDocTypeForItemLedgEntry(ItemLedgEntry) in
                   [FromPurchLineBuf."Document Type"::Order, FromPurchLineBuf."Document Type"::"Return Order"]
                then
                    FromPurchLineBuf."Receipt Line No." := 1;

                if not FromShptOrRcpt then
                    UpdateRevPurchLineAmount(
                      FromPurchLineBuf, OrgQtyBase,
                      FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT");
                if FromPurchLineBuf.Quantity <> 0 then begin
                    OnSplitPstdPurchLinesPerILEOnBeforeFromPurchLineBufInsert(FromPurchHeader, FromPurchLine, FromPurchLineBuf, ToPurchHeader);
                    FromPurchLineBuf.Insert();
                    if OneRecord then
                        AddPurchDocLine(TempDocPurchaseLine, FromPurchLineBuf."Line No.", FromPurchLine."Document No.", FromPurchLine."Line No.")
                    else
                        AddPurchDocLine(TempDocPurchaseLine, FromPurchLineBuf."Line No.", ItemLedgEntry."Document No.", FromPurchLineBuf."Line No.");
                end else
                    SkippedLine := true;
            end else
                if ItemLedgEntry."Remaining Quantity" = 0 then
                    SkippedLine := true;
        until (ItemLedgEntry.Next() = 0) or (FromPurchLine."Quantity (Base)" = 0);

        if (FromPurchLine."Quantity (Base)" <> 0) and FillExactCostRevLink then
            MissingExCostRevLink := true;
        OnSplitPstdPurchLinesPerILEOnBeforeCheckUnappliedLines(ToPurchHeader, SkippedLine, MissingExCostRevLink);
        CheckUnappliedLines(SkippedLine, MissingExCostRevLink);

        exit(true);
    end;

    local procedure SplitPurchDocLinesPerItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var TempItemTrkgEntry: Record "Reservation Entry" temporary; var FromPurchLineBuf: Record "Purchase Line"; FromPurchLine: Record "Purchase Line"; var TempDocPurchaseLine: Record "Purchase Line" temporary; var NextLineNo: Integer; var NextItemTrkgEntryNo: Integer; var MissingExCostRevLink: Boolean; FromShptOrRcpt: Boolean): Boolean
    var
        PurchLineBuf: array[2] of Record "Purchase Line" temporary;
        ApplyRec: Record "Item Application Entry";
        Tracked: Boolean;
        RemainingQtyBase: Decimal;
        SignFactor: Integer;
        i: Integer;
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSplitPurchDocLinesPerItemTrkg(ItemLedgEntry, TempItemTrkgEntry, FromPurchLineBuf, FromPurchLine, TempDocPurchaseLine, NextLineNo, NextItemTrkgEntryNo, MissingExCostRevLink, FromShptOrRcpt, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if FromShptOrRcpt then begin
            FromPurchLineBuf.Reset();
            FromPurchLineBuf.DeleteAll();
            TempItemTrkgEntry.Reset();
            TempItemTrkgEntry.DeleteAll();
        end else
            FromPurchLineBuf.Init();

        if MoveNegLines or not ExactCostRevMandatory then
            exit(false);

        if FromPurchLine."Quantity (Base)" < 0 then
            SignFactor := -1
        else
            SignFactor := 1;

        ItemLedgEntry.SetCurrentKey("Document No.", "Document Type", "Document Line No.");
        ItemLedgEntry.FindSet();
        repeat
            PurchLineBuf[1] := FromPurchLine;
            PurchLineBuf[1]."Line No." := NextLineNo;
            PurchLineBuf[1]."Quantity (Base)" := 0;
            PurchLineBuf[1].Quantity := 0;
            PurchLineBuf[1]."Document No." := ItemLedgEntry."Document No.";
            if GetPurchDocTypeForItemLedgEntry(ItemLedgEntry) in
               [PurchLineBuf[1]."Document Type"::Order, PurchLineBuf[1]."Document Type"::"Return Order"]
            then
                PurchLineBuf[1]."Receipt Line No." := 1;
            PurchLineBuf[2] := PurchLineBuf[1];
            PurchLineBuf[2]."Line No." := PurchLineBuf[2]."Line No." + 1;

            if not FromShptOrRcpt then begin
                ItemLedgEntry.SetRange("Document No.", ItemLedgEntry."Document No.");
                ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type");
                ItemLedgEntry.SetRange("Document Line No.", ItemLedgEntry."Document Line No.");
            end;
            repeat
                i := 1;
                if ItemLedgEntry.Positive then
                    ItemLedgEntry."Remaining Quantity" :=
                      ItemLedgEntry."Remaining Quantity" -
                      CalcDistributedQty(TempItemTrkgEntry, ItemLedgEntry, PurchLineBuf[2]."Line No." + 1);

                if ItemLedgEntry."Document Type" in [ItemLedgEntry."Document Type"::"Purchase Return Shipment", ItemLedgEntry."Document Type"::"Purchase Credit Memo"] then
                    if -ItemLedgEntry."Shipped Qty. Not Returned" < FromPurchLine."Quantity (Base)" * SignFactor then
                        RemainingQtyBase := -ItemLedgEntry."Shipped Qty. Not Returned" * SignFactor
                    else
                        RemainingQtyBase := FromPurchLine."Quantity (Base)"
                else
                    if not ItemLedgEntry.Positive then begin
                        RemainingQtyBase := -ItemLedgEntry."Shipped Qty. Not Returned";
                        if RemainingQtyBase < FromPurchLine."Quantity (Base)" * SignFactor then
                            RemainingQtyBase := RemainingQtyBase * SignFactor
                        else
                            RemainingQtyBase := FromPurchLine."Quantity (Base)";
                    end else
                        if ItemLedgEntry."Remaining Quantity" < FromPurchLine."Quantity (Base)" * SignFactor then begin
                            if (ItemLedgEntry."Item Tracking" = ItemLedgEntry."Item Tracking"::None) and AskApply then
                                ConfirmApply();
                            if (not ApplyFully) or (ItemLedgEntry."Item Tracking" <> ItemLedgEntry."Item Tracking"::None) then
                                RemainingQtyBase := GetQtyOfPurchILENotShipped(ItemLedgEntry."Entry No.", FromPurchLine) * SignFactor
                            else
                                RemainingQtyBase := FromPurchLine."Quantity (Base)" - ApplyRec.Returned(ItemLedgEntry."Entry No.");
                        end else
                            RemainingQtyBase := FromPurchLine."Quantity (Base)";

                if RemainingQtyBase <> 0 then begin
                    if ItemLedgEntry.Positive then
                        if IsSplitItemLedgEntry(ItemLedgEntry) then
                            i := 2;

                    PurchLineBuf[i]."Quantity (Base)" := PurchLineBuf[i]."Quantity (Base)" + RemainingQtyBase;
                    if PurchLineBuf[i]."Qty. per Unit of Measure" = 0 then
                        PurchLineBuf[i].Quantity := PurchLineBuf[i]."Quantity (Base)"
                    else
                        PurchLineBuf[i].Quantity :=
                          Round(
                            PurchLineBuf[i]."Quantity (Base)" / PurchLineBuf[i]."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    FromPurchLine."Quantity (Base)" := FromPurchLine."Quantity (Base)" - RemainingQtyBase;
                    // Fill buffer with exact cost reversing link for remaining quantity
                    if ItemLedgEntry."Document Type" in [ItemLedgEntry."Document Type"::"Purchase Return Shipment", ItemLedgEntry."Document Type"::"Purchase Credit Memo"] then
                        InsertTempReservationEntry(
                          ItemLedgEntry, TempItemTrkgEntry, -Abs(RemainingQtyBase),
                          PurchLineBuf[i]."Line No.", NextItemTrkgEntryNo, true)
                    else
                        InsertTempReservationEntry(
                          ItemLedgEntry, TempItemTrkgEntry, Abs(RemainingQtyBase),
                          PurchLineBuf[i]."Line No.", NextItemTrkgEntryNo, true);
                    Tracked := true;
                end else
                    SkippedLine := true;
            until (ItemLedgEntry.Next() = 0) or (FromPurchLine."Quantity (Base)" = 0);

            for i := 1 to 2 do
                if PurchLineBuf[i]."Quantity (Base)" <> 0 then begin
                    FromPurchLineBuf := PurchLineBuf[i];
                    FromPurchLineBuf.Insert();
                    AddPurchDocLine(TempDocPurchaseLine, FromPurchLineBuf."Line No.", ItemLedgEntry."Document No.", FromPurchLine."Line No.");
                    NextLineNo := PurchLineBuf[i]."Line No." + 1;
                end;

            if not FromShptOrRcpt then begin
                ItemLedgEntry.SetRange("Document No.");
                ItemLedgEntry.SetRange("Document Type");
                ItemLedgEntry.SetRange("Document Line No.");
            end;
        until (ItemLedgEntry.Next() = 0) or FromShptOrRcpt;
        if (FromPurchLine."Quantity (Base)" <> 0) and not Tracked then
            MissingExCostRevLink := true;
        CheckUnappliedLines(SkippedLine, MissingExCostRevLink);

        exit(true);
    end;

    local procedure CalcDistributedQty(var TempItemTrkgEntry: Record "Reservation Entry" temporary; ItemLedgEntry: Record "Item Ledger Entry"; NextLineNo: Integer): Decimal
    begin
        TempItemTrkgEntry.Reset();
        TempItemTrkgEntry.SetCurrentKey("Source ID", "Source Ref. No.");
        TempItemTrkgEntry.SetRange("Source ID", ItemLedgEntry."Document No.");
        TempItemTrkgEntry.SetFilter("Source Ref. No.", '<%1', NextLineNo);
        TempItemTrkgEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        TempItemTrkgEntry.CalcSums("Quantity (Base)");
        TempItemTrkgEntry.Reset();
        exit(TempItemTrkgEntry."Quantity (Base)");
    end;

#if not CLEAN23
    [Scope('OnPrem')]
    [Obsolete('Use the new implementation of IsEntityBlocked, which adds support for Item Variants', '23.0')]
    procedure IsEntityBlocked(TableNo: Integer; CreditDocType: Boolean; Type: Option; EntityNo: Code[20]) EntityIsBlocked: Boolean
    begin
        exit(IsEntityBlocked(TableNo, CreditDocType, Type, EntityNo, ''));
    end;
#endif
    [Scope('OnPrem')]
    procedure IsEntityBlocked(TableNo: Integer; CreditDocType: Boolean; Type: Option; EntityNo: Code[20]; EntityCode: Code[10]) EntityIsBlocked: Boolean
    var
        GLAccount: Record "G/L Account";
        FixedAsset: Record "Fixed Asset";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Resource: Record Resource;
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        MessageType: Option Error,Warning,Information;
        BlockedForSalesPurch: Boolean;
        IsHandled: Boolean;
        ItemItemVariantLbl: Label '%1 %2', Comment = '%1 - Item No., %2 - Variant Code';
    begin
        OnBeforeIsEntityBlocked(TableNo, CreditDocType, Type, EntityNo, EntityIsBlocked, IsHandled, EntityCode);
        if IsHandled then
            exit(EntityIsBlocked);

        if SkipWarningNotification then
            MessageType := MessageType::Error
        else
            MessageType := MessageType::Warning;

        case Type of
            "Sales Line Type"::"G/L Account".AsInteger():
                if GLAccount.Get(EntityNo) then begin
                    if not GLAccount."Direct Posting" then
                        ErrorMessageMgt.LogMessage(
                          MessageType, 0, StrSubstNo(DirectPostingErr, GLAccount."No."), GLAccount, GLAccount.FieldNo("Direct Posting"), '')
                    else
                        if GLAccount.Blocked then
                            ErrorMessageMgt.LogMessage(
                              MessageType, 0, StrSubstNo(IsBlockedErr, GLAccount.TableCaption(), GLAccount."No.")
                              , GLAccount, GLAccount.FieldNo(Blocked), '');
                    exit(not GLAccount."Direct Posting" or GLAccount.Blocked);
                end;
            "Sales Line Type"::Item.AsInteger():
                if Item.Get(EntityNo) then begin
                    if Item.Blocked then begin
                        ErrorMessageMgt.LogMessage(
                            MessageType, 0, StrSubstNo(IsBlockedErr, Item.TableCaption(), Item."No."),
                            Item, Item.FieldNo(Blocked), ForwardLinkMgt.GetHelpCodeForBlockedItem());
                        exit(true);
                    end;

                    if not CreditDocType then
                        case TableNo of
                            Database::"Sales Line":
                                if Item."Sales Blocked" then begin
                                    BlockedForSalesPurch := true;
                                    ErrorMessageMgt.LogMessage(
                                        MessageType, 0, StrSubstNo(IsSalesBlockedItemErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Sales Blocked")), Item,
                                        Item.FieldNo("Sales Blocked"), ForwardLinkMgt.GetHelpCodeForBlockedItem());
                                end;
                            Database::"Purchase Line":
                                if Item."Purchasing Blocked" then begin
                                    BlockedForSalesPurch := true;
                                    ErrorMessageMgt.LogMessage(
                                        MessageType, 0, StrSubstNo(IsPurchBlockedItemErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Purchasing Blocked")), Item,
                                        Item.FieldNo("Purchasing Blocked"), ForwardLinkMgt.GetHelpCodeForBlockedItem());
                                end;
                            else
                                BlockedForSalesPurch := false;
                        end;

                    if not BlockedForSalesPurch then
                        if (EntityCode <> '') and ItemVariant.Get(EntityNo, EntityCode) then begin
                            if ItemVariant.Blocked then begin
                                ErrorMessageMgt.LogMessage(
                                    MessageType, 0, StrSubstNo(IsBlockedErr, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, ItemVariant."Item No.", ItemVariant.Code)),
                                    ItemVariant, ItemVariant.FieldNo(Blocked), ForwardLinkMgt.GetHelpCodeForBlockedItem());
                                exit(true);
                            end;

                            if not CreditDocType then
                                case TableNo of
                                    Database::"Sales Line":
                                        if ItemVariant."Sales Blocked" then begin
                                            BlockedForSalesPurch := true;
                                            ErrorMessageMgt.LogMessage(
                                                MessageType, 0,
                                                StrSubstNo(IsSalesBlockedItemErr, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Sales Blocked")),
                                                ItemVariant, ItemVariant.FieldNo("Sales Blocked"), ForwardLinkMgt.GetHelpCodeForBlockedItem());
                                        end;
                                    Database::"Purchase Line":
                                        if ItemVariant."Purchasing Blocked" then begin
                                            BlockedForSalesPurch := true;
                                            ErrorMessageMgt.LogMessage(
                                                MessageType, 0,
                                                StrSubstNo(IsPurchBlockedItemErr, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, ItemVariant."Item No.", ItemVariant.Code), ItemVariant.FieldCaption("Purchasing Blocked")),
                                                ItemVariant, ItemVariant.FieldNo("Purchasing Blocked"), ForwardLinkMgt.GetHelpCodeForBlockedItem());
                                        end;
                                end;
                        end;
                    exit(BlockedForSalesPurch);
                end;
            "Sales Line Type"::Resource.AsInteger():
                if Resource.Get(EntityNo) then begin
                    if Resource.Blocked then
                        ErrorMessageMgt.LogMessage(
                          MessageType, 0, StrSubstNo(IsBlockedErr, Resource.TableCaption(), Resource."No."), Resource, Resource.FieldNo(Blocked), '');
                    exit(Resource.Blocked);
                end;
            "Sales Line Type"::"Fixed Asset".AsInteger():
                if FixedAsset.Get(EntityNo) then begin
                    if FixedAsset.Blocked then
                        ErrorMessageMgt.LogMessage(
                          MessageType, 0, StrSubstNo(IsBlockedErr, FixedAsset.TableCaption(), FixedAsset."No."),
                          FixedAsset, FixedAsset.FieldNo(Blocked), '')
                    else
                        if FixedAsset.Inactive then
                            ErrorMessageMgt.LogMessage(
                              MessageType, 0, StrSubstNo(FAIsInactiveErr, FixedAsset."No."), FixedAsset, FixedAsset.FieldNo(Inactive), '');
                    exit(FixedAsset.Blocked or FixedAsset.Inactive);
                end;
        end;
    end;

    local procedure IsItemOrVariantBlocked(ItemNo: Code[20]; VariantCode: Code[10]): Boolean
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if (Item.Get(ItemNo) and Item.Blocked) then
            exit(true);
        if VariantCode <> '' then begin
            ItemVariant.SetLoadFields(Blocked);
            exit(ItemVariant.Get(ItemNo, VariantCode) and ItemVariant.Blocked);
        end;
    end;

    local procedure IsSplitItemLedgEntry(OrgItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Document No.");
        ItemLedgEntry.SetRange("Document No.", OrgItemLedgEntry."Document No.");
        ItemLedgEntry.SetRange("Document Type", OrgItemLedgEntry."Document Type");
        ItemLedgEntry.SetRange("Document Line No.", OrgItemLedgEntry."Document Line No.");
        ItemLedgEntry.SetTrackingFilterFromItemLedgEntry(OrgItemLedgEntry);
        ItemLedgEntry.SetFilter("Entry No.", '<%1', OrgItemLedgEntry."Entry No.");
        OnIsSplitItemLedgEntryOnAfterItemLedgEntrySetFilters(ItemLedgEntry, OrgItemLedgEntry);
        exit(not ItemLedgEntry.IsEmpty());
    end;

    procedure IsCopyItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var CopyItemTrkg: Boolean; FillExactCostRevLink: Boolean) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsCopyItemTrkg(ItemLedgEntry, CopyItemTrkg, FillExactCostRevLink, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ItemLedgEntry.IsEmpty() then
            exit(true);
        ItemLedgEntry.SetFilter("Serial No.", '<>%1', '');
        if not ItemLedgEntry.IsEmpty() then begin
            if FillExactCostRevLink then
                CopyItemTrkg := true;
            exit(true);
        end;
        ItemLedgEntry.SetRange("Serial No.");
        ItemLedgEntry.SetFilter("Lot No.", '<>%1', '');
        if not ItemLedgEntry.IsEmpty() then begin
            if FillExactCostRevLink then
                CopyItemTrkg := true;
            exit(true);
        end;
        ItemLedgEntry.SetRange("Lot No.");

        OnAfterIsCopyItemTrkg(ItemLedgEntry, FillExactCostRevLink, CopyItemTrkg, IsHandled);
        if IsHandled then
            exit(true);

        exit(false);
    end;

    local procedure InsertTempReservationEntry(ItemLedgEntry: Record "Item Ledger Entry"; var TempReservationEntry: Record "Reservation Entry"; QtyBase: Decimal; DocLineNo: Integer; var NextEntryNo: Integer; FillExactCostRevLink: Boolean)
    begin
        if QtyBase = 0 then
            exit;

        TempReservationEntry.Init();
        TempReservationEntry."Entry No." := NextEntryNo;
        NextEntryNo := NextEntryNo + 1;
        if not FillExactCostRevLink then
            TempReservationEntry."Reservation Status" := TempReservationEntry."Reservation Status"::Prospect;
        TempReservationEntry."Source ID" := ItemLedgEntry."Document No.";
        TempReservationEntry."Source Ref. No." := DocLineNo;
        TempReservationEntry."Item Ledger Entry No." := ItemLedgEntry."Entry No.";
        TempReservationEntry."Quantity (Base)" := QtyBase;
        OnInsertTempReservationEntryOnBeforeInsert(TempReservationEntry, ItemLedgEntry);
        TempReservationEntry.Insert();
    end;

    procedure GetLastToSalesLineNo(ToSalesHeader: Record "Sales Header"): Decimal
    var
        ToSalesLine: Record "Sales Line";
    begin
        ToSalesLine.LockTable();
        ToSalesLine.SetRange("Document Type", ToSalesHeader."Document Type");
        ToSalesLine.SetRange("Document No.", ToSalesHeader."No.");
        if ToSalesLine.FindLast() then
            exit(ToSalesLine."Line No.");
        exit(0);
    end;

    procedure GetLastToPurchLineNo(ToPurchHeader: Record "Purchase Header"): Decimal
    var
        ToPurchLine: Record "Purchase Line";
    begin
        ToPurchLine.LockTable();
        ToPurchLine.SetRange("Document Type", ToPurchHeader."Document Type");
        ToPurchLine.SetRange("Document No.", ToPurchHeader."No.");
        if ToPurchLine.FindLast() then
            exit(ToPurchLine."Line No.");
        exit(0);
    end;

    procedure InsertOldSalesDocNoLine(ToSalesHeader: Record "Sales Header"; OldDocNo: Code[20]; OldDocType: Integer; var NextLineNo: Integer)
    var
        ToSalesLine2: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertOldSalesDocNoLineProcedure(ToSalesHeader, ToSalesLine2, OldDocType, OldDocNo, IsHandled);
        if IsHandled then
            exit;

        if ShouldSkipCopyFromDescription() then
            exit;

        NextLineNo := NextLineNo + 10000;
        ToSalesLine2.Init();
        ToSalesLine2."Line No." := NextLineNo;
        ToSalesLine2."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine2."Document No." := ToSalesHeader."No.";

        TranslationHelper.SetGlobalLanguageByCode(ToSalesHeader."Language Code");
        if InsertCancellationLine then
            ToSalesLine2.Description := StrSubstNo(CrMemoCancellationMsg, OldDocNo)
        else
            ToSalesLine2.Description := StrSubstNo(Text015, SelectStr(OldDocType, Text013), OldDocNo);
        TranslationHelper.RestoreGlobalLanguage();

        IsHandled := false;
        OnBeforeInsertOldSalesDocNoLine(ToSalesHeader, ToSalesLine2, OldDocType, OldDocNo, IsHandled);
        if not IsHandled then
            ToSalesLine2.Insert();
    end;

    local procedure ShouldSkipCopyFromDescription() Result: Boolean
    begin
        Result := SkipCopyFromDescription;
        OnAfterShouldSkipCopyFromDescription(Result);
    end;

    local procedure InsertOldSalesCombDocNoLine(ToSalesHeader: Record "Sales Header"; OldDocNo: Code[20]; OldDocNo2: Code[20]; var NextLineNo: Integer; CopyFromInvoice: Boolean)
    var
        ToSalesLine2: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertOldSalesCombDocNoLineProcedure(ToSalesHeader, ToSalesLine2, CopyFromInvoice, OldDocNo, OldDocNo2, NextLineNo, IsHandled);
        if IsHandled then
            exit;

        NextLineNo := NextLineNo + 10000;
        ToSalesLine2.Init();
        ToSalesLine2."Line No." := NextLineNo;
        ToSalesLine2."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine2."Document No." := ToSalesHeader."No.";

        TranslationHelper.SetGlobalLanguageByCode(ToSalesHeader."Language Code");
        if CopyFromInvoice then
            ToSalesLine2.Description :=
              StrSubstNo(
                Text018,
                CopyStr(SelectStr(1, Text016) + OldDocNo, 1, 48),
                CopyStr(SelectStr(2, Text016) + OldDocNo2, 1, 48))
        else
            ToSalesLine2.Description :=
              StrSubstNo(
                Text018,
                CopyStr(SelectStr(3, Text016) + OldDocNo, 1, 48),
                CopyStr(SelectStr(4, Text016) + OldDocNo2, 1, 48));
        TranslationHelper.RestoreGlobalLanguage();

        IsHandled := false;
        OnBeforeInsertOldSalesCombDocNoLine(ToSalesHeader, ToSalesLine2, CopyFromInvoice, OldDocNo, OldDocNo2, IsHandled);
        if not IsHandled then
            ToSalesLine2.Insert();
    end;

    local procedure InsertOldPurchDocNoLine(ToPurchHeader: Record "Purchase Header"; OldDocNo: Code[20]; OldDocType: Integer; var NextLineNo: Integer)
    var
        ToPurchLine2: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertOldPurchDocNoLineProcedure(ToPurchHeader, ToPurchLine2, OldDocType, OldDocNo, IsHandled);
        if IsHandled then
            exit;

        if ShouldSkipCopyFromDescription() then
            exit;

        NextLineNo := NextLineNo + 10000;
        ToPurchLine2.Init();
        ToPurchLine2."Line No." := NextLineNo;
        ToPurchLine2."Document Type" := ToPurchHeader."Document Type";
        ToPurchLine2."Document No." := ToPurchHeader."No.";

        TranslationHelper.SetGlobalLanguageByCode(ToPurchHeader."Language Code");
        if InsertCancellationLine then
            ToPurchLine2.Description := StrSubstNo(CrMemoCancellationMsg, OldDocNo)
        else
            ToPurchLine2.Description := StrSubstNo(Text015, SelectStr(OldDocType, Text014), OldDocNo);
        TranslationHelper.RestoreGlobalLanguage();

        IsHandled := false;
        OnBeforeInsertOldPurchDocNoLine(ToPurchHeader, ToPurchLine2, OldDocType, OldDocNo, IsHandled);
        if not IsHandled then
            ToPurchLine2.Insert();
    end;

    local procedure InsertOldPurchCombDocNoLine(ToPurchHeader: Record "Purchase Header"; OldDocNo: Code[20]; OldDocNo2: Code[20]; var NextLineNo: Integer; CopyFromInvoice: Boolean)
    var
        ToPurchLine2: Record "Purchase Line";
    begin
        NextLineNo := NextLineNo + 10000;
        ToPurchLine2.Init();
        ToPurchLine2."Line No." := NextLineNo;
        ToPurchLine2."Document Type" := ToPurchHeader."Document Type";
        ToPurchLine2."Document No." := ToPurchHeader."No.";

        TranslationHelper.SetGlobalLanguageByCode(ToPurchHeader."Language Code");
        if CopyFromInvoice then
            ToPurchLine2.Description :=
              StrSubstNo(
                Text018,
                CopyStr(SelectStr(1, Text017) + OldDocNo, 1, 48),
                CopyStr(SelectStr(2, Text017) + OldDocNo2, 1, 48))
        else
            ToPurchLine2.Description :=
              StrSubstNo(
                Text018,
                CopyStr(SelectStr(3, Text017) + OldDocNo, 1, 48),
                CopyStr(SelectStr(4, Text017) + OldDocNo2, 1, 48));
        TranslationHelper.RestoreGlobalLanguage();

        OnBeforeInsertOldPurchCombDocNoLine(ToPurchHeader, ToPurchLine2, CopyFromInvoice, OldDocNo, OldDocNo2);
        ToPurchLine2.Insert();
    end;

    procedure IsSalesFillExactCostRevLink(ToSalesHeader: Record "Sales Header"; FromDocType: Option "Sales Shipment","Sales Invoice","Sales Return Receipt","Sales Credit Memo"; CurrencyCode: Code[10]) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsSalesFillExactCostRevLink(ToSalesHeader, FromDocType, CurrencyCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case FromDocType of
            FromDocType::"Sales Shipment":
                exit(ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::"Return Order", ToSalesHeader."Document Type"::"Credit Memo"]);
            FromDocType::"Sales Invoice":
                exit(
                  (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::"Return Order", ToSalesHeader."Document Type"::"Credit Memo"]) and
                  (ToSalesHeader."Currency Code" = CurrencyCode));
            FromDocType::"Sales Return Receipt":
                exit(ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice]);
            FromDocType::"Sales Credit Memo":
                exit(
                  (ToSalesHeader."Document Type" in [ToSalesHeader."Document Type"::Order, ToSalesHeader."Document Type"::Invoice]) and
                  (ToSalesHeader."Currency Code" = CurrencyCode));
        end;
        exit(false);
    end;

    procedure IsPurchFillExactCostRevLink(ToPurchHeader: Record "Purchase Header"; FromDocType: Option "Purchase Receipt","Purchase Invoice","Purchase Return Shipment","Purchase Credit Memo"; CurrencyCode: Code[10]) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsPurchFillExactCostRevLink(ToPurchHeader, FromDocType, CurrencyCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case FromDocType of
            FromDocType::"Purchase Receipt":
                exit(ToPurchHeader."Document Type" in [ToPurchHeader."Document Type"::"Return Order", ToPurchHeader."Document Type"::"Credit Memo"]);
            FromDocType::"Purchase Invoice":
                exit(
                  (ToPurchHeader."Document Type" in [ToPurchHeader."Document Type"::"Return Order", ToPurchHeader."Document Type"::"Credit Memo"]) and
                  (ToPurchHeader."Currency Code" = CurrencyCode));
            FromDocType::"Purchase Return Shipment":
                exit(ToPurchHeader."Document Type" in [ToPurchHeader."Document Type"::Order, ToPurchHeader."Document Type"::Invoice]);
            FromDocType::"Purchase Credit Memo":
                exit(
                  (ToPurchHeader."Document Type" in [ToPurchHeader."Document Type"::Order, ToPurchHeader."Document Type"::Invoice]) and
                  (ToPurchHeader."Currency Code" = CurrencyCode));
        end;
        exit(false);
    end;

    local procedure GetSalesDocTypeForItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry"): Enum "Sales Document Type"
    begin
        case ItemLedgEntry."Document Type" of
            ItemLedgEntry."Document Type"::"Sales Shipment":
                exit("Sales Document Type"::Order);
            ItemLedgEntry."Document Type"::"Sales Invoice":
                exit("Sales Document Type"::Invoice);
            ItemLedgEntry."Document Type"::"Sales Credit Memo":
                exit("Sales Document Type"::"Credit Memo");
            ItemLedgEntry."Document Type"::"Sales Return Receipt":
                exit("Sales Document Type"::"Return Order");
        end;
    end;

    local procedure GetPurchDocTypeForItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry"): Enum "Purchase Document Type"
    begin
        case ItemLedgEntry."Document Type" of
            ItemLedgEntry."Document Type"::"Purchase Receipt":
                exit("Purchase Document Type"::Order);
            ItemLedgEntry."Document Type"::"Purchase Invoice":
                exit("Purchase Document Type"::Invoice);
            ItemLedgEntry."Document Type"::"Purchase Credit Memo":
                exit("Purchase Document Type"::"Credit Memo");
            ItemLedgEntry."Document Type"::"Purchase Return Shipment":
                exit("Purchase Document Type"::"Return Order");
        end;
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo <> Item."No." then
            if not Item.Get(ItemNo) then
                Item.Init();
    end;

    local procedure CalcVAT(var Value: Decimal; VATPercentage: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean; RndgPrecision: Decimal)
    begin
        if (ToPricesInclVAT = FromPricesInclVAT) or (Value = 0) then
            exit;

        if ToPricesInclVAT then
            Value := Round(Value * (100 + VATPercentage) / 100, RndgPrecision)
        else
            Value := Round(Value * 100 / (100 + VATPercentage), RndgPrecision);
    end;

    local procedure ReCalcSalesLine(FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        SalesLineAmount: Decimal;
        IsHandled: Boolean;
    begin
        if not IsRecalculateAmount(
            FromSalesHeader."Currency Code", ToSalesHeader."Currency Code",
            FromSalesHeader."Prices Including VAT", ToSalesHeader."Prices Including VAT")
        then
            exit;

        if FromSalesHeader."Currency Code" <> ToSalesHeader."Currency Code" then begin
            if SalesLine.Quantity <> 0 then
                SalesLineAmount := SalesLine."Unit Price" * SalesLine.Quantity
            else
                SalesLineAmount := SalesLine."Unit Price";
            if FromSalesHeader."Currency Code" <> '' then begin
                SalesLineAmount :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    FromSalesHeader."Posting Date", FromSalesHeader."Currency Code",
                    SalesLineAmount, FromSalesHeader."Currency Factor");
                SalesLine."Line Discount Amount" :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    FromSalesHeader."Posting Date", FromSalesHeader."Currency Code",
                    SalesLine."Line Discount Amount", FromSalesHeader."Currency Factor");
                SalesLine."Inv. Discount Amount" :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    FromSalesHeader."Posting Date", FromSalesHeader."Currency Code",
                    SalesLine."Inv. Discount Amount", FromSalesHeader."Currency Factor");
            end;

            if ToSalesHeader."Currency Code" <> '' then begin
                SalesLineAmount :=
                  CurrExchRate.ExchangeAmtLCYToFCY(
                    ToSalesHeader."Posting Date", ToSalesHeader."Currency Code", SalesLineAmount, ToSalesHeader."Currency Factor");
                SalesLine."Line Discount Amount" :=
                  CurrExchRate.ExchangeAmtLCYToFCY(
                    ToSalesHeader."Posting Date", ToSalesHeader."Currency Code", SalesLine."Line Discount Amount", ToSalesHeader."Currency Factor");
                SalesLine."Inv. Discount Amount" :=
                  CurrExchRate.ExchangeAmtLCYToFCY(
                    ToSalesHeader."Posting Date", ToSalesHeader."Currency Code", SalesLine."Inv. Discount Amount", ToSalesHeader."Currency Factor");
            end;
        end;

        IsHandled := false;
        OnRecalcSalesLineOnBeforeRoundUnitPrice(SalesLine, IsHandled);
        if not IsHandled then begin
            SalesLine."Currency Code" := ToSalesHeader."Currency Code";
            if SalesLine.Quantity <> 0 then begin
                SalesLineAmount := Round(SalesLineAmount, Currency."Amount Rounding Precision");
                SalesLine."Unit Price" := Round(SalesLineAmount / SalesLine.Quantity, Currency."Unit-Amount Rounding Precision");
            end else
                SalesLine."Unit Price" := Round(SalesLineAmount, Currency."Unit-Amount Rounding Precision");
        end;
        SalesLine."Line Discount Amount" := Round(SalesLine."Line Discount Amount", Currency."Amount Rounding Precision");
        SalesLine."Inv. Discount Amount" := Round(SalesLine."Inv. Discount Amount", Currency."Amount Rounding Precision");

        IsHandled := false;
        OnReCalcSalesLineOnBeforeCalcVAT(FromSalesHeader, ToSalesHeader, SalesLine, IsHandled);
        if not IsHandled then begin
            CalcVAT(
                SalesLine."Unit Price", SalesLine."VAT %", FromSalesHeader."Prices Including VAT",
                ToSalesHeader."Prices Including VAT", Currency."Unit-Amount Rounding Precision");
            CalcVAT(
                SalesLine."Line Discount Amount", SalesLine."VAT %", FromSalesHeader."Prices Including VAT",
                ToSalesHeader."Prices Including VAT", Currency."Amount Rounding Precision");
            CalcVAT(
                SalesLine."Inv. Discount Amount", SalesLine."VAT %", FromSalesHeader."Prices Including VAT",
                ToSalesHeader."Prices Including VAT", Currency."Amount Rounding Precision");
        end;
    end;

    local procedure ReCalcPurchLine(FromPurchHeader: Record "Purchase Header"; ToPurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        PurchLineAmount: Decimal;
    begin
        if not IsRecalculateAmount(
            FromPurchHeader."Currency Code", ToPurchHeader."Currency Code",
            FromPurchHeader."Prices Including VAT", ToPurchHeader."Prices Including VAT")
        then
            exit;

        if FromPurchHeader."Currency Code" <> ToPurchHeader."Currency Code" then begin
            if PurchLine.Quantity <> 0 then
                PurchLineAmount := PurchLine."Direct Unit Cost" * PurchLine.Quantity
            else
                PurchLineAmount := PurchLine."Direct Unit Cost";
            if FromPurchHeader."Currency Code" <> '' then begin
                PurchLineAmount :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    FromPurchHeader."Posting Date", FromPurchHeader."Currency Code",
                    PurchLineAmount, FromPurchHeader."Currency Factor");
                PurchLine."Line Discount Amount" :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    FromPurchHeader."Posting Date", FromPurchHeader."Currency Code",
                    PurchLine."Line Discount Amount", FromPurchHeader."Currency Factor");
                PurchLine."Inv. Discount Amount" :=
                  CurrExchRate.ExchangeAmtFCYToLCY(
                    FromPurchHeader."Posting Date", FromPurchHeader."Currency Code",
                    PurchLine."Inv. Discount Amount", FromPurchHeader."Currency Factor");
            end;

            if ToPurchHeader."Currency Code" <> '' then begin
                PurchLineAmount :=
                  CurrExchRate.ExchangeAmtLCYToFCY(
                    ToPurchHeader."Posting Date", ToPurchHeader."Currency Code", PurchLineAmount, ToPurchHeader."Currency Factor");
                PurchLine."Line Discount Amount" :=
                  CurrExchRate.ExchangeAmtLCYToFCY(
                    ToPurchHeader."Posting Date", ToPurchHeader."Currency Code", PurchLine."Line Discount Amount", ToPurchHeader."Currency Factor");
                PurchLine."Inv. Discount Amount" :=
                  CurrExchRate.ExchangeAmtLCYToFCY(
                    ToPurchHeader."Posting Date", ToPurchHeader."Currency Code", PurchLine."Inv. Discount Amount", ToPurchHeader."Currency Factor");
            end;
        end;

        PurchLine."Currency Code" := ToPurchHeader."Currency Code";
        if PurchLine.Quantity <> 0 then begin
            PurchLineAmount := Round(PurchLineAmount, Currency."Amount Rounding Precision");
            PurchLine."Direct Unit Cost" := Round(PurchLineAmount / PurchLine.Quantity, Currency."Unit-Amount Rounding Precision");
        end else
            PurchLine."Direct Unit Cost" := Round(PurchLineAmount, Currency."Unit-Amount Rounding Precision");
        PurchLine."Line Discount Amount" := Round(PurchLine."Line Discount Amount", Currency."Amount Rounding Precision");
        PurchLine."Inv. Discount Amount" := Round(PurchLine."Inv. Discount Amount", Currency."Amount Rounding Precision");

        OnReCalcPurchLineOnBeforeCalcVAT(FromPurchHeader, ToPurchHeader, PurchLine);
        CalcVAT(
          PurchLine."Direct Unit Cost", PurchLine."VAT %", FromPurchHeader."Prices Including VAT",
          ToPurchHeader."Prices Including VAT", Currency."Unit-Amount Rounding Precision");
        CalcVAT(
          PurchLine."Line Discount Amount", PurchLine."VAT %", FromPurchHeader."Prices Including VAT",
          ToPurchHeader."Prices Including VAT", Currency."Amount Rounding Precision");
        CalcVAT(
          PurchLine."Inv. Discount Amount", PurchLine."VAT %", FromPurchHeader."Prices Including VAT",
          ToPurchHeader."Prices Including VAT", Currency."Amount Rounding Precision");
    end;

    procedure IsRecalculateAmount(FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean): Boolean
    begin
        exit(
          (FromCurrencyCode <> ToCurrencyCode) or
          (FromPricesInclVAT <> ToPricesInclVAT));
    end;

    local procedure UpdateRevSalesLineAmount(var SalesLine: Record "Sales Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        Amount: Decimal;
    begin
        if (OrgQtyBase = 0) or (SalesLine.Quantity = 0) or
           ((FromPricesInclVAT = ToPricesInclVAT) and (OrgQtyBase = SalesLine."Quantity (Base)"))
        then
            exit;

        Amount := SalesLine.Quantity * SalesLine."Unit Price";
        CalcVAT(
          Amount, SalesLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        SalesLine."Unit Price" := Amount / SalesLine.Quantity;
        SalesLine."Line Discount Amount" :=
          Round(
            Round(SalesLine.Quantity * SalesLine."Unit Price", Currency."Amount Rounding Precision") *
            SalesLine."Line Discount %" / 100,
            Currency."Amount Rounding Precision");
        Amount :=
          Round(SalesLine."Inv. Discount Amount" / OrgQtyBase * SalesLine."Quantity (Base)", Currency."Amount Rounding Precision");
        CalcVAT(
          Amount, SalesLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        SalesLine."Inv. Discount Amount" := Amount;

        OnAfterUpdateRevSalesLineAmount(SalesLine, OrgQtyBase, FromPricesInclVAT, ToPricesInclVAT);
    end;

    procedure CalculateRevSalesLineAmount(var SalesLine: Record "Sales Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        UnitPrice: Decimal;
        LineDiscAmt: Decimal;
        InvDiscAmt: Decimal;
    begin
        UpdateRevSalesLineAmount(SalesLine, OrgQtyBase, FromPricesInclVAT, ToPricesInclVAT);

        UnitPrice := SalesLine."Unit Price";
        LineDiscAmt := SalesLine."Line Discount Amount";
        InvDiscAmt := SalesLine."Inv. Discount Amount";

        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount Amount", LineDiscAmt);
        SalesLine.Validate("Inv. Discount Amount", InvDiscAmt);
    end;

    local procedure UpdateRevPurchLineAmount(var PurchLine: Record "Purchase Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        Amount: Decimal;
    begin
        if (OrgQtyBase = 0) or (PurchLine.Quantity = 0) or
           ((FromPricesInclVAT = ToPricesInclVAT) and (OrgQtyBase = PurchLine."Quantity (Base)"))
        then
            exit;

        Amount := PurchLine.Quantity * PurchLine."Direct Unit Cost";
        CalcVAT(
          Amount, PurchLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        PurchLine."Direct Unit Cost" := Amount / PurchLine.Quantity;
        PurchLine."Line Discount Amount" :=
          Round(
            Round(PurchLine.Quantity * PurchLine."Direct Unit Cost", Currency."Amount Rounding Precision") *
            PurchLine."Line Discount %" / 100,
            Currency."Amount Rounding Precision");
        Amount :=
          Round(PurchLine."Inv. Discount Amount" / Abs(OrgQtyBase) * PurchLine."Quantity (Base)", Currency."Amount Rounding Precision");
        CalcVAT(
          Amount, PurchLine."VAT %", FromPricesInclVAT, ToPricesInclVAT, Currency."Amount Rounding Precision");
        PurchLine."Inv. Discount Amount" := Amount;

        OnAfterUpdateRevPurchLineAmount(PurchLine, OrgQtyBase, FromPricesInclVAT, ToPricesInclVAT);
    end;

    procedure CalculateRevPurchLineAmount(var PurchLine: Record "Purchase Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    var
        DirectUnitCost: Decimal;
        LineDiscAmt: Decimal;
        InvDiscAmt: Decimal;
    begin
        UpdateRevPurchLineAmount(PurchLine, OrgQtyBase, FromPricesInclVAT, ToPricesInclVAT);

        DirectUnitCost := PurchLine."Direct Unit Cost";
        LineDiscAmt := PurchLine."Line Discount Amount";
        InvDiscAmt := PurchLine."Inv. Discount Amount";

        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Validate("Line Discount Amount", LineDiscAmt);
        PurchLine.Validate("Inv. Discount Amount", InvDiscAmt);
    end;

    local procedure InitCurrency(CurrencyCode: Code[10])
    begin
        if CurrencyCode <> '' then
            Currency.Get(CurrencyCode)
        else
            Currency.InitRoundingPrecision();

        Currency.TestField("Unit-Amount Rounding Precision");
        Currency.TestField("Amount Rounding Precision");
    end;

    procedure SetHideProcessWindow(NewHideProcessWindow: Boolean)
    begin
        HideProcessWindow := NewHideProcessWindow;
    end;

    local procedure OpenWindow()
    begin
        if not HideProcessWindow then begin
            Window.Open(
                Text022 +
                Text023 +
                Text024);
            WindowUpdateDateTime := CurrentDateTime;
        end;
    end;

    local procedure CloseWindow()
    begin
        if not HideProcessWindow then
            Window.Close();
    end;

    local procedure UpdateWindow(Number: Integer; CounterValue: Integer)
    begin
        if not HideProcessWindow then
            Window.Update(Number, CounterValue);
    end;

    procedure IsTimeForUpdate(): Boolean
    begin
        if HideProcessWindow then
            exit(false);

        if CurrentDateTime - WindowUpdateDateTime >= 1000 then begin
            WindowUpdateDateTime := CurrentDateTime;
            exit(true);
        end;
        exit(false);
    end;

    local procedure ConfirmApply()
    begin
        AskApply := false;
        ApplyFully := false;
    end;

    local procedure ConvertFromBase(var Quantity: Decimal; QuantityBase: Decimal; QtyPerUOM: Decimal)
    begin
        if QtyPerUOM = 0 then
            Quantity := QuantityBase
        else
            Quantity := Round(QuantityBase / QtyPerUOM, UOMMgt.QtyRndPrecision());
    end;

    local procedure Sign(Quantity: Decimal): Decimal
    begin
        if Quantity < 0 then
            exit(-1);
        exit(1);
    end;

    procedure ShowMessageReapply(OriginalQuantity: Boolean)
    var
        Text: Text[1024];
    begin
        Text := '';
        if SkippedLine then
            Text := Text029;
        if OriginalQuantity and ReappDone then
            if Text = '' then
                Text := Text025;
        if SomeAreFixed then
            Message(Text031);
        if Text <> '' then
            Message(Text);
    end;

    procedure LinkJobPlanningLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
    begin
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        repeat
            JobPlanningLine.SetRange("Job Contract Entry No.", SalesLine."Job Contract Entry No.");
            if JobPlanningLine.FindFirst() then begin
                JobPlanningLineInvoice."Job No." := JobPlanningLine."Job No.";
                JobPlanningLineInvoice."Job Task No." := JobPlanningLine."Job Task No.";
                JobPlanningLineInvoice."Job Planning Line No." := JobPlanningLine."Line No.";
                case SalesHeader."Document Type" of
                    SalesHeader."Document Type"::Invoice:
                        begin
                            JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::Invoice;
                            JobPlanningLineInvoice."Quantity Transferred" := SalesLine.Quantity;
                        end;
                    SalesHeader."Document Type"::"Credit Memo":
                        begin
                            JobPlanningLineInvoice."Document Type" := JobPlanningLineInvoice."Document Type"::"Credit Memo";
                            JobPlanningLineInvoice."Quantity Transferred" := -SalesLine.Quantity;
                        end;
                    else
                        exit;
                end;
                JobPlanningLineInvoice."Document No." := SalesHeader."No.";
                JobPlanningLineInvoice."Line No." := SalesLine."Line No.";
                JobPlanningLineInvoice."Transferred Date" := SalesHeader."Posting Date";
                JobPlanningLineInvoice.Insert();

                JobPlanningLine.UpdateQtyToTransfer();
                JobPlanningLine.Modify();
                OnLinkJobPlanningLineOnAfterJobPlanningLineModify(JobPlanningLineInvoice, JobPlanningLine);
            end;
        until SalesLine.Next() = 0;
    end;

    local procedure GetQtyOfPurchILENotShipped(ItemLedgerEntryNo: Integer; FromPurchLine: Record "Purchase Line"): Decimal
    var
        ItemApplicationEntry: Record "Item Application Entry";
        ItemLedgerEntryLocal: Record "Item Ledger Entry";
        QtyNotShipped: Decimal;
    begin
        QtyNotShipped := 0;
        ItemApplicationEntry.Reset();
        ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.", "Outbound Item Entry No.");
        ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntryNo);
        ItemApplicationEntry.SetRange("Outbound Item Entry No.", 0);
        if not ItemApplicationEntry.FindFirst() then
            exit(QtyNotShipped);
        QtyNotShipped := ItemApplicationEntry.Quantity;
        ItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>0');
        if not ItemApplicationEntry.FindSet(false) then begin
            if FromPurchLine."Copied From Posted Doc." and (FromPurchLine."Receipt No." <> '') then begin
                ItemLedgerEntryLocal.SetLoadFields("Invoiced Quantity");
                ItemLedgerEntryLocal.Get(ItemLedgerEntryNo);
                if Abs(ItemLedgerEntryLocal."Invoiced Quantity") < Abs(QtyNotShipped) then
                    QtyNotShipped := ItemLedgerEntryLocal."Invoiced Quantity";
            end;
            exit(QtyNotShipped);
        end;
        repeat
            ItemLedgerEntryLocal.Get(ItemApplicationEntry."Outbound Item Entry No.");
            if (ItemLedgerEntryLocal."Entry Type" in
                [ItemLedgerEntryLocal."Entry Type"::Sale,
                 ItemLedgerEntryLocal."Entry Type"::Purchase]) or
               ((ItemLedgerEntryLocal."Entry Type" in
                 [ItemLedgerEntryLocal."Entry Type"::"Positive Adjmt.", ItemLedgerEntryLocal."Entry Type"::"Negative Adjmt."]) and
                (ItemLedgerEntryLocal."Job No." = ''))
            then
                QtyNotShipped += ItemApplicationEntry.Quantity;
        until ItemApplicationEntry.Next() = 0;
        exit(QtyNotShipped);
    end;

    local procedure CopyAsmOrderToAsmOrder(var TempFromAsmHeader: Record "Assembly Header" temporary; var TempFromAsmLine: Record "Assembly Line" temporary; ToSalesLine: Record "Sales Line"; ToAsmHeaderDocType: Option; ToAsmHeaderDocNo: Code[20]; InclAsmHeader: Boolean)
    var
        FromAsmHeader: Record "Assembly Header";
        ToAsmHeader: Record "Assembly Header";
        TempToAsmHeader: Record "Assembly Header" temporary;
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        ToAsmLine: Record "Assembly Line";
        BasicAsmOrderCopy: Boolean;
    begin
        OnBeforeCopyAsmOrderToAsmOrderProcedure(TempFromAsmHeader, TempFromAsmLine, ToSalesLine, ToAsmHeaderDocType, ToAsmHeaderDocNo, InclAsmHeader);
        if ToAsmHeaderDocType = -1 then
            exit;
        BasicAsmOrderCopy := ToAsmHeaderDocNo <> '';
        if BasicAsmOrderCopy then
            ToAsmHeader.Get(ToAsmHeaderDocType, ToAsmHeaderDocNo)
        else begin
            if ToSalesLine.AsmToOrderExists(FromAsmHeader) then
                exit;
            Clear(ToAsmHeader);
            AssembleToOrderLink.InsertAsmHeader(ToAsmHeader, "Assembly Document Type".FromInteger(ToAsmHeaderDocType), '');
            InclAsmHeader := true;
        end;

        if InclAsmHeader then begin
            if BasicAsmOrderCopy then begin
                TempToAsmHeader := ToAsmHeader;
                TempToAsmHeader.Insert();
                ProcessToAsmHeader(TempToAsmHeader, TempFromAsmHeader, ToSalesLine, true, true); // Basic, Availabilitycheck
                CheckAsmOrderAvailability(TempToAsmHeader, TempFromAsmLine, ToSalesLine);
            end;
            ProcessToAsmHeader(ToAsmHeader, TempFromAsmHeader, ToSalesLine, BasicAsmOrderCopy, false);
        end else
            if BasicAsmOrderCopy then
                CheckAsmOrderAvailability(ToAsmHeader, TempFromAsmLine, ToSalesLine);
        CreateToAsmLines(ToAsmHeader, TempFromAsmLine, ToAsmLine, ToSalesLine, BasicAsmOrderCopy, false);
        if not BasicAsmOrderCopy then begin
            AssembleToOrderLink."Assembly Document Type" := ToAsmHeader."Document Type";
            AssembleToOrderLink."Assembly Document No." := ToAsmHeader."No.";
            AssembleToOrderLink.Type := AssembleToOrderLink.Type::Sale;
            AssembleToOrderLink."Document Type" := ToSalesLine."Document Type";
            AssembleToOrderLink."Document No." := ToSalesLine."Document No.";
            AssembleToOrderLink."Document Line No." := ToSalesLine."Line No.";
            AssembleToOrderLink.Insert();
            if ToSalesLine."Document Type" = ToSalesLine."Document Type"::Order then begin
                if ToSalesLine."Shipment Date" = 0D then begin
                    ToSalesLine."Shipment Date" := ToAsmHeader."Due Date";
                    OnCopyAsmOrderToAsmOrderOnBeforeModifySalesLine(ToSalesLine);
                    ToSalesLine.Modify();
                end;
                AssembleToOrderLink.ReserveAsmToSale(ToSalesLine, ToSalesLine.Quantity, ToSalesLine."Quantity (Base)");
            end;
        end;

        ToAsmHeader.ShowDueDateBeforeWorkDateMsg();
    end;

    procedure CopyAsmHeaderToAsmHeader(FromAsmHeader: Record "Assembly Header"; ToAsmHeader: Record "Assembly Header"; IncludeHeader: Boolean)
    var
        EmptyToSalesLine: Record "Sales Line";
    begin
        InitialToAsmHeaderCheck(ToAsmHeader, IncludeHeader);
        GenerateAsmDataFromNonPosted(FromAsmHeader);
        Clear(EmptyToSalesLine);
        EmptyToSalesLine.Init();
        CopyAsmOrderToAsmOrder(
            TempAsmHeader, TempAsmLine, EmptyToSalesLine, ToAsmHeader."Document Type".AsInteger(), ToAsmHeader."No.", IncludeHeader);
    end;

    procedure CopyPostedAsmHeaderToAsmHeader(PostedAsmHeader: Record "Posted Assembly Header"; ToAsmHeader: Record "Assembly Header"; IncludeHeader: Boolean)
    var
        EmptyToSalesLine: Record "Sales Line";
    begin
        InitialToAsmHeaderCheck(ToAsmHeader, IncludeHeader);
        GenerateAsmDataFromPosted(PostedAsmHeader, "Assembly Document Type"::Quote);
        Clear(EmptyToSalesLine);
        EmptyToSalesLine.Init();
        CopyAsmOrderToAsmOrder(
            TempAsmHeader, TempAsmLine, EmptyToSalesLine, ToAsmHeader."Document Type".AsInteger(), ToAsmHeader."No.", IncludeHeader);
    end;

    local procedure GenerateAsmDataFromNonPosted(AsmHeader: Record "Assembly Header")
    var
        AsmLine: Record "Assembly Line";
    begin
        InitAsmCopyHandling(false);
        TempAsmHeader := AsmHeader;
        TempAsmHeader.Insert();
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        if AsmLine.FindSet() then
            repeat
                TempAsmLine := AsmLine;
                TempAsmLine.Insert();
            until AsmLine.Next() = 0;
    end;

    local procedure GenerateAsmDataFromPosted(PostedAsmHeader: Record "Posted Assembly Header"; DocType: Enum "Assembly Document Type")
    var
        PostedAsmLine: Record "Posted Assembly Line";
    begin
        InitAsmCopyHandling(false);
        TempAsmHeader.TransferFields(PostedAsmHeader);
        OnAfterTransferTempAsmHeader(TempAsmHeader, PostedAsmHeader);
        TempAsmHeader."Document Type" := DocType;
        TempAsmHeader.Insert();
        PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
        if PostedAsmLine.FindSet() then
            repeat
                TempAsmLine.TransferFields(PostedAsmLine);
                TempAsmLine."Document No." := TempAsmHeader."No.";
                TempAsmLine."Cost Amount" := PostedAsmLine.Quantity * PostedAsmLine."Unit Cost";
                TempAsmLine.Insert();
            until PostedAsmLine.Next() = 0;
    end;

    local procedure GetAsmDataFromSalesInvLine(DocType: Enum "Sales Document Type"): Boolean
    var
        ValueEntry: Record "Value Entry";
        ValueEntry2: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntry2: Record "Item Ledger Entry";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        Clear(PostedAsmHeader);
        if TempSalesInvLine.Type <> TempSalesInvLine.Type::Item then
            exit(false);
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", TempSalesInvLine."Document No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        ValueEntry.SetRange("Document Line No.", TempSalesInvLine."Line No.");
        if not ValueEntry.FindFirst() then
            exit(false);
        if not ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then
            exit(false);
        if ItemLedgerEntry."Document Type" <> ItemLedgerEntry."Document Type"::"Sales Shipment" then
            exit(false);
        SalesShipmentLine.Get(ItemLedgerEntry."Document No.", ItemLedgerEntry."Document Line No.");
        if not SalesShipmentLine.AsmToShipmentExists(PostedAsmHeader) then
            exit(false);
        if ValueEntry.Count > 1 then begin
            ValueEntry2.Copy(ValueEntry);
            ValueEntry2.SetFilter("Item Ledger Entry No.", '<>%1', ValueEntry."Item Ledger Entry No.");
            if ValueEntry2.FindSet() then
                repeat
                    ItemLedgerEntry2.Get(ValueEntry2."Item Ledger Entry No.");
                    if (ItemLedgerEntry2."Document Type" <> ItemLedgerEntry."Document Type") or
                       (ItemLedgerEntry2."Document No." <> ItemLedgerEntry."Document No.") or
                       (ItemLedgerEntry2."Document Line No." <> ItemLedgerEntry."Document Line No.")
                    then
                        Error(Text032, TempSalesInvLine."Document No.");
                until ValueEntry2.Next() = 0;
        end;
        GenerateAsmDataFromPosted(PostedAsmHeader, DocType);
        exit(true);
    end;

    procedure InitAsmCopyHandling(ResetQuantities: Boolean)
    begin
        if ResetQuantities then begin
            QtyToAsmToOrder := 0;
            QtyToAsmToOrderBase := 0;
        end;
        TempAsmHeader.DeleteAll();
        TempAsmLine.DeleteAll();
    end;

    local procedure RetrieveSalesInvLine(SalesLine: Record "Sales Line"; PosNo: Integer; LineCountsEqual: Boolean): Boolean
    begin
        if not LineCountsEqual then
            exit(false);
        TempSalesInvLine.FindSet();
        if PosNo > 1 then
            TempSalesInvLine.Next(PosNo - 1);
        exit((SalesLine.Type = TempSalesInvLine.Type) and (SalesLine."No." = TempSalesInvLine."No."));
    end;

    procedure InitialToAsmHeaderCheck(ToAsmHeader: Record "Assembly Header"; IncludeHeader: Boolean)
    begin
        ToAsmHeader.TestField("No.");
        if IncludeHeader then begin
            ToAsmHeader.TestField("Item No.", '');
            ToAsmHeader.TestField(Quantity, 0);
        end else begin
            ToAsmHeader.TestField("Item No.");
            ToAsmHeader.TestField(Quantity);
        end;
    end;

    local procedure GetAsmOrderType(SalesLineDocType: Enum "Sales Document Type"): Integer
    begin
        if SalesLineDocType in [SalesLineDocType::Quote, SalesLineDocType::Order, SalesLineDocType::"Blanket Order"] then
            exit(SalesLineDocType.AsInteger());
        exit(-1);
    end;

    local procedure ProcessToAsmHeader(var ToAsmHeader: Record "Assembly Header"; TempFromAsmHeader: Record "Assembly Header" temporary; ToSalesLine: Record "Sales Line"; BasicAsmOrderCopy: Boolean; AvailabilityCheck: Boolean)
    begin
        if AvailabilityCheck then begin
            ToAsmHeader."Item No." := TempFromAsmHeader."Item No.";
            ToAsmHeader."Location Code" := TempFromAsmHeader."Location Code";
            ToAsmHeader."Variant Code" := TempFromAsmHeader."Variant Code";
            ToAsmHeader."Unit of Measure Code" := TempFromAsmHeader."Unit of Measure Code";
        end else begin
            ToAsmHeader.Validate(ToAsmHeader."Item No.", TempFromAsmHeader."Item No.");
            ToAsmHeader.Validate(ToAsmHeader."Location Code", TempFromAsmHeader."Location Code");
            ToAsmHeader.Validate(ToAsmHeader."Variant Code", TempFromAsmHeader."Variant Code");
            ToAsmHeader.Validate(ToAsmHeader."Unit of Measure Code", TempFromAsmHeader."Unit of Measure Code");
        end;
        if BasicAsmOrderCopy then begin
            ToAsmHeader.Validate(ToAsmHeader."Due Date", TempFromAsmHeader."Due Date");
            ToAsmHeader.Quantity := TempFromAsmHeader.Quantity;
            ToAsmHeader."Quantity (Base)" := TempFromAsmHeader."Quantity (Base)";
        end else begin
            if ToSalesLine."Shipment Date" <> 0D then
                ToAsmHeader.Validate(ToAsmHeader."Due Date", ToSalesLine."Shipment Date");
            ToAsmHeader.Quantity := QtyToAsmToOrder;
            ToAsmHeader."Quantity (Base)" := QtyToAsmToOrderBase;
        end;
        OnProcessToAsmHeaderOnAfterValidateQty(ToAsmHeader, TempFromAsmHeader, ToSalesLine, BasicAsmOrderCopy, AvailabilityCheck);
        ToAsmHeader."Bin Code" := TempFromAsmHeader."Bin Code";
        ToAsmHeader."Unit Cost" := TempFromAsmHeader."Unit Cost";
        ToAsmHeader.RoundQty(ToAsmHeader.Quantity);
        ToAsmHeader.RoundQty(ToAsmHeader."Quantity (Base)");
        ToAsmHeader."Cost Amount" := Round(ToAsmHeader.Quantity * ToAsmHeader."Unit Cost");
        ToAsmHeader.InitRemainingQty();
        ToAsmHeader.InitQtyToAssemble();
        if not AvailabilityCheck then begin
            ToAsmHeader.Validate(ToAsmHeader."Quantity to Assemble");
            ToAsmHeader.Validate(ToAsmHeader."Planning Flexibility", TempFromAsmHeader."Planning Flexibility");
        end;
        CopyFromAsmOrderDimToHdr(ToAsmHeader, TempFromAsmHeader, ToSalesLine);
        ToAsmHeader.Modify();

        OnAfterProcessToAsmHeader(ToAsmHeader, TempFromAsmHeader, ToSalesLine, BasicAsmOrderCopy, AvailabilityCheck);
    end;

    local procedure CreateToAsmLines(ToAsmHeader: Record "Assembly Header"; var FromAsmLine: Record "Assembly Line"; var ToAssemblyLine: Record "Assembly Line"; ToSalesLine: Record "Sales Line"; BasicAsmOrderCopy: Boolean; AvailabilityCheck: Boolean)
    var
        AssemblyLineMgt: Codeunit "Assembly Line Management";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if FromAsmLine.FindSet() then
            repeat
                ToAssemblyLine.Init();
                ToAssemblyLine."Document Type" := ToAsmHeader."Document Type";
                ToAssemblyLine."Document No." := ToAsmHeader."No.";
                ToAssemblyLine."Line No." := AssemblyLineMgt.GetNextAsmLineNo(ToAssemblyLine, AvailabilityCheck);
                ToAssemblyLine.Insert(not AvailabilityCheck);
                if AvailabilityCheck then begin
                    ToAssemblyLine.Type := FromAsmLine.Type;
                    ToAssemblyLine."No." := FromAsmLine."No.";
                    ToAssemblyLine."Resource Usage Type" := FromAsmLine."Resource Usage Type";
                    ToAssemblyLine."Unit of Measure Code" := FromAsmLine."Unit of Measure Code";
                    ToAssemblyLine."Quantity per" := FromAsmLine."Quantity per";
                    ToAssemblyLine.Quantity := GetAppliedQuantityForAsmLine(BasicAsmOrderCopy, ToAsmHeader, FromAsmLine, ToSalesLine);
                end else begin
                    ToAssemblyLine.Validate(Type, FromAsmLine.Type);
                    ToAssemblyLine.Validate("No.", FromAsmLine."No.");
                    ToAssemblyLine.Validate("Resource Usage Type", FromAsmLine."Resource Usage Type");
                    ToAssemblyLine.Validate("Unit of Measure Code", FromAsmLine."Unit of Measure Code");
                    if ToAssemblyLine.Type <> ToAssemblyLine.Type::" " then
                        ToAssemblyLine.Validate("Quantity per", FromAsmLine."Quantity per");
                    ToAssemblyLine.Validate(Quantity, GetAppliedQuantityForAsmLine(BasicAsmOrderCopy, ToAsmHeader, FromAsmLine, ToSalesLine));
                end;
                OnCreateToAsmLinesOnAfterValidateQty(ToAsmHeader, FromAsmLine, ToAssemblyLine, ToSalesLine, BasicAsmOrderCopy, AvailabilityCheck);
                ToAssemblyLine.ValidateDueDate(ToAsmHeader, ToAsmHeader."Starting Date", false);
                ToAssemblyLine.ValidateLeadTimeOffset(ToAsmHeader, FromAsmLine."Lead-Time Offset", false);
                ToAssemblyLine.Description := FromAsmLine.Description;
                ToAssemblyLine."Description 2" := FromAsmLine."Description 2";
                ToAssemblyLine.Position := FromAsmLine.Position;
                ToAssemblyLine."Position 2" := FromAsmLine."Position 2";
                ToAssemblyLine."Position 3" := FromAsmLine."Position 3";
                if ToAssemblyLine.Type = ToAssemblyLine.Type::Item then
                    if AvailabilityCheck then begin
                        ToAssemblyLine."Location Code" := FromAsmLine."Location Code";
                        ToAssemblyLine."Variant Code" := FromAsmLine."Variant Code";
                    end else begin
                        ToAssemblyLine.Validate("Location Code", FromAsmLine."Location Code");
                        ToAssemblyLine.Validate("Variant Code", FromAsmLine."Variant Code");
                    end;
                if ToAssemblyLine.Type <> ToAssemblyLine.Type::" " then begin
                    if RecalculateLines then
                        ToAssemblyLine."Unit Cost" := ToAssemblyLine.GetUnitCost()
                    else
                        ToAssemblyLine."Unit Cost" := FromAsmLine."Unit Cost";
                    ToAssemblyLine."Cost Amount" := ToAssemblyLine.CalcCostAmount(ToAssemblyLine.Quantity, ToAssemblyLine."Unit Cost");
                    if AvailabilityCheck then begin
                        ToAssemblyLine."Quantity (Base)" :=
                          UOMMgt.CalcBaseQty(
                            ToAssemblyLine."No.", ToAssemblyLine."Variant Code", ToAssemblyLine."Unit of Measure Code",
                            ToAssemblyLine.Quantity, ToAssemblyLine."Qty. per Unit of Measure");
                        ToAssemblyLine."Remaining Quantity" := ToAssemblyLine."Quantity (Base)";
                        ToAssemblyLine.InitQtyToConsume();
                    end else begin
                        ToAssemblyLine.InitQtyToConsume();
                        ToAssemblyLine.Validate("Quantity to Consume");
                    end;
                end;
                CopyFromAsmOrderDimToLine(ToAssemblyLine, FromAsmLine, BasicAsmOrderCopy);
                OnCreateToAsmLinesOnBeforeToAssemblyLineModify(ToAsmHeader, ToAssemblyLine, FromAsmLine, ToSalesLine, BasicAsmOrderCopy, AvailabilityCheck);
                ToAssemblyLine.Modify(not AvailabilityCheck);
            until FromAsmLine.Next() = 0;
    end;

    local procedure CheckAsmOrderAvailability(ToAsmHeader: Record "Assembly Header"; var FromAsmLine: Record "Assembly Line"; ToSalesLine: Record "Sales Line")
    var
        TempToAsmHeader: Record "Assembly Header" temporary;
        TempToAsmLine: Record "Assembly Line" temporary;
        AsmLineOnDestinationOrder: Record "Assembly Line";
        AssemblyLineMgt: Codeunit "Assembly Line Management";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        LineNo: Integer;
    begin
        TempToAsmHeader := ToAsmHeader;
        TempToAsmHeader.Insert();
        CreateToAsmLines(TempToAsmHeader, FromAsmLine, TempToAsmLine, ToSalesLine, true, true);
        if TempToAsmLine.FindLast() then
            LineNo := TempToAsmLine."Line No.";
        Clear(TempToAsmLine);
        AsmLineOnDestinationOrder.SetRange("Document Type", ToAsmHeader."Document Type");
        AsmLineOnDestinationOrder.SetRange("Document No.", ToAsmHeader."No.");
        AsmLineOnDestinationOrder.SetRange(Type, AsmLineOnDestinationOrder.Type::Item);
        if AsmLineOnDestinationOrder.FindSet() then
            repeat
                TempToAsmLine := AsmLineOnDestinationOrder;
                LineNo += 10000;
                TempToAsmLine."Line No." := LineNo;
                TempToAsmLine.Insert();
            until AsmLineOnDestinationOrder.Next() = 0;
        if AssemblyLineMgt.ShowAvailability(false, TempToAsmHeader, TempToAsmLine) then
            ItemCheckAvail.RaiseUpdateInterruptedError();
        TempToAsmLine.DeleteAll();
    end;

    local procedure GetAppliedQuantityForAsmLine(BasicAsmOrderCopy: Boolean; ToAsmHeader: Record "Assembly Header"; TempFromAsmLine: Record "Assembly Line" temporary; ToSalesLine: Record "Sales Line"): Decimal
    begin
        if (TempFromAsmLine.Type = TempFromAsmLine.Type::Resource) and
           (TempFromAsmLine."Resource Usage Type" = TempFromAsmLine."Resource Usage Type"::Fixed)
        then
            exit(TempFromAsmLine."Quantity per");

        if BasicAsmOrderCopy then
            exit(ToAsmHeader.Quantity * TempFromAsmLine."Quantity per");
        case ToSalesLine."Document Type" of
            ToSalesLine."Document Type"::Order:
                exit(ToSalesLine."Qty. to Assemble to Order" * TempFromAsmLine."Quantity per");
            ToSalesLine."Document Type"::Quote,
          ToSalesLine."Document Type"::"Blanket Order":
                exit(ToSalesLine.Quantity * TempFromAsmLine."Quantity per");
        end;
    end;

    local procedure CopyFromArchSalesDocDimToHdr(var ToSalesHeader: Record "Sales Header"; FromSalesHeaderArchive: Record "Sales Header Archive")
    begin
        ToSalesHeader."Shortcut Dimension 1 Code" := FromSalesHeaderArchive."Shortcut Dimension 1 Code";
        ToSalesHeader."Shortcut Dimension 2 Code" := FromSalesHeaderArchive."Shortcut Dimension 2 Code";
        ToSalesHeader."Dimension Set ID" := FromSalesHeaderArchive."Dimension Set ID";
    end;

    local procedure CopyFromArchSalesDocDimToLine(var ToSalesLine: Record "Sales Line"; FromSalesLineArchive: Record "Sales Line Archive")
    begin
        if IncludeHeader then begin
            ToSalesLine."Shortcut Dimension 1 Code" := FromSalesLineArchive."Shortcut Dimension 1 Code";
            ToSalesLine."Shortcut Dimension 2 Code" := FromSalesLineArchive."Shortcut Dimension 2 Code";
            ToSalesLine."Dimension Set ID" := FromSalesLineArchive."Dimension Set ID";
        end;
    end;

    local procedure CopyFromArchPurchDocDimToHdr(var ToPurchHeader: Record "Purchase Header"; FromPurchHeaderArchive: Record "Purchase Header Archive")
    begin
        ToPurchHeader."Shortcut Dimension 1 Code" := FromPurchHeaderArchive."Shortcut Dimension 1 Code";
        ToPurchHeader."Shortcut Dimension 2 Code" := FromPurchHeaderArchive."Shortcut Dimension 2 Code";
        ToPurchHeader."Dimension Set ID" := FromPurchHeaderArchive."Dimension Set ID";
    end;

    local procedure CopyFromArchPurchDocDimToLine(var ToPurchLine: Record "Purchase Line"; FromPurchLineArchive: Record "Purchase Line Archive")
    begin
        if IncludeHeader then begin
            ToPurchLine."Shortcut Dimension 1 Code" := FromPurchLineArchive."Shortcut Dimension 1 Code";
            ToPurchLine."Shortcut Dimension 2 Code" := FromPurchLineArchive."Shortcut Dimension 2 Code";
            ToPurchLine."Dimension Set ID" := FromPurchLineArchive."Dimension Set ID";
        end;
    end;

    local procedure CopyFromAsmOrderDimToHdr(var ToAssemblyHeader: Record "Assembly Header"; FromAssemblyHeader: Record "Assembly Header"; ToSalesLine: Record "Sales Line")
    begin
        if RecalculateLines then begin
            ToAssemblyHeader."Dimension Set ID" := ToSalesLine."Dimension Set ID";
            ToAssemblyHeader."Shortcut Dimension 1 Code" := ToSalesLine."Shortcut Dimension 1 Code";
            ToAssemblyHeader."Shortcut Dimension 2 Code" := ToSalesLine."Shortcut Dimension 2 Code";
        end else begin
            ToAssemblyHeader."Dimension Set ID" := FromAssemblyHeader."Dimension Set ID";
            ToAssemblyHeader."Shortcut Dimension 1 Code" := FromAssemblyHeader."Shortcut Dimension 1 Code";
            ToAssemblyHeader."Shortcut Dimension 2 Code" := FromAssemblyHeader."Shortcut Dimension 2 Code";
        end;
    end;

    local procedure CopyFromAsmOrderDimToLine(var ToAssemblyLine: Record "Assembly Line"; FromAssemblyLine: Record "Assembly Line"; BasicAsmOrderCopy: Boolean)
    begin
        if RecalculateLines or BasicAsmOrderCopy then
            exit;

        ToAssemblyLine."Dimension Set ID" := FromAssemblyLine."Dimension Set ID";
        ToAssemblyLine."Shortcut Dimension 1 Code" := FromAssemblyLine."Shortcut Dimension 1 Code";
        ToAssemblyLine."Shortcut Dimension 2 Code" := FromAssemblyLine."Shortcut Dimension 2 Code";
    end;

    procedure SetArchDocVal(DocOccurrencyNo: Integer; DocVersionNo: Integer)
    begin
        FromDocOccurrenceNo := DocOccurrencyNo;
        FromDocVersionNo := DocVersionNo;
    end;

    procedure CopyArchSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeaderArchive: Record "Sales Header Archive"; var FromSalesLineArchive: Record "Sales Line Archive"; var NextLineNo: Integer; var LinesNotCopied: Integer; RecalculateAmount: Boolean): Boolean
    var
        LastInsertedSalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        FromSalesHeader: Record "Sales Header";
        FromSalesLine: Record "Sales Line";
        CopyThisLine: Boolean;
        IsHandled: Boolean;
        ShouldRecalculateAmount: Boolean;
    begin
        CopyThisLine := true;
        OnBeforeCopyArchSalesLine(ToSalesHeader, FromSalesHeaderArchive, FromSalesLineArchive, RecalculateLines, CopyThisLine);
        if not CopyThisLine then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        if ((ToSalesHeader."Language Code" <> FromSalesHeaderArchive."Language Code") or RecalculateLines) and
           FromSalesLineArchive.IsExtendedText()
        then
            exit(false);

        ToSalesLine.SetSalesHeader(ToSalesHeader);
        if RecalculateLines and not FromSalesLineArchive."System-Created Entry" then
            ToSalesLine.Init()
        else
            ToSalesLine.TransferFields(FromSalesLineArchive);
        NextLineNo := NextLineNo + 10000;
        OnCopyArchSalesLineOnAfterIncrementNextLineNo(ToSalesLine, FromSalesLineArchive, NextLineNo, ToSalesHeader);
        ToSalesLine."Document Type" := ToSalesHeader."Document Type";
        ToSalesLine."Document No." := ToSalesHeader."No.";
        ToSalesLine."Line No." := NextLineNo;
        ToSalesLine.Validate("Currency Code", FromSalesHeaderArchive."Currency Code");

        if RecalculateLines and not FromSalesLineArchive."System-Created Entry" then begin
            FromSalesHeader.TransferFields(FromSalesHeaderArchive, true);
            FromSalesLine.TransferFields(FromSalesLineArchive, true);
            RecalculateSalesLine(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, CopyThisLine);
        end else begin
            InitSalesLineFields(ToSalesLine);

            ToSalesLine.InitOutstanding();
            if ToSalesLine."Document Type" in
               [ToSalesLine."Document Type"::"Return Order", ToSalesLine."Document Type"::"Credit Memo"]
            then
                ToSalesLine.InitQtyToReceive()
            else
                ToSalesLine.InitQtyToShip();
            ToSalesLine."VAT Difference" := FromSalesLineArchive."VAT Difference";
            if not CreateToHeader then
                ToSalesLine."Shipment Date" := ToSalesHeader."Shipment Date";
            ToSalesLine."Appl.-from Item Entry" := 0;
            ToSalesLine."Appl.-to Item Entry" := 0;

            OnCopyArchSalesLineOnBeforeCleanSpecialOrderDropShipmentInSalesLine(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, CreateToHeader);

            CleanSpecialOrderDropShipmentInSalesLine(ToSalesLine);
            if RecalculateAmount and (FromSalesLineArchive."Appl.-from Item Entry" = 0) then begin
                ToSalesLine.Validate("Line Discount %", FromSalesLineArchive."Line Discount %");
                ToSalesLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromSalesLineArchive."Inv. Discount Amount", Currency."Amount Rounding Precision"));
                ToSalesLine.Validate("Unit Cost (LCY)", FromSalesLineArchive."Unit Cost (LCY)");
            end;
            if VATPostingSetup.Get(ToSalesLine."VAT Bus. Posting Group", ToSalesLine."VAT Prod. Posting Group") then
                ToSalesLine."VAT Identifier" := VATPostingSetup."VAT Identifier";

            ToSalesLine.UpdateWithWarehouseShip();
            if (ToSalesLine.Type = ToSalesLine.Type::Item) and (ToSalesLine."No." <> '') then begin
                GetItem(ToSalesLine."No.");
                if (Item."Costing Method" = Item."Costing Method"::Standard) and not ToSalesLine.IsShipment() then
                    ToSalesLine.GetUnitCost();
            end;
        end;

        ShouldRecalculateAmount := ExactCostRevMandatory and
           (FromSalesLineArchive.Type = FromSalesLineArchive.Type::Item) and
           (FromSalesLineArchive."Appl.-from Item Entry" <> 0) and
           not MoveNegLines;

        OnCopyArchSalesLineOnAfterCalcShouldRecalculateAmount(ToSalesLine, FromSalesLineArchive, ShouldRecalculateAmount);

        if ShouldRecalculateAmount then begin
            if RecalculateAmount then begin
                ToSalesLine.Validate("Unit Price", FromSalesLineArchive."Unit Price");
                ToSalesLine.Validate(
                  "Line Discount Amount",
                  Round(FromSalesLineArchive."Line Discount Amount", Currency."Amount Rounding Precision"));
                ToSalesLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromSalesLineArchive."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            end;
            ToSalesLine.Validate("Appl.-from Item Entry", FromSalesLineArchive."Appl.-from Item Entry");
            if not CreateToHeader then
                if ToSalesLine."Shipment Date" = 0D then
                    InitShipmentDateInLine(ToSalesHeader, ToSalesLine);
        end;

        if MoveNegLines and (ToSalesLine.Type <> ToSalesLine.Type::" ") then begin
            ToSalesLine.Validate(Quantity, -FromSalesLineArchive.Quantity);
            OnCopyArchSalesLineOnAfterValidateQuantityMoveNegLines(ToSalesLine, FromSalesLineArchive);
            ToSalesLine.Validate("Line Discount %", FromSalesLineArchive."Line Discount %");
            ToSalesLine."Appl.-to Item Entry" := FromSalesLineArchive."Appl.-to Item Entry";
            ToSalesLine."Appl.-from Item Entry" := FromSalesLineArchive."Appl.-from Item Entry";
        end;

        IsHandled := false;
        OnCopyArchSalesLineOnBeforeTransferExtendedText(ToSalesHeader, ToSalesLine, FromSalesHeaderArchive, FromSalesLineArchive, RecalculateLines, NextLineNo, TransferOldExtLines, IsHandled, MoveNegLines);
        if not IsHandled then
            if not ((ToSalesHeader."Language Code" <> FromSalesHeaderArchive."Language Code") or RecalculateLines) then begin
                if FromSalesLineArchive.IsExtendedText() then
                    ToSalesLine."Attached to Line No." :=
                        TransferOldExtLines.TransferExtendedText(
                          FromSalesLineArchive."Line No.", NextLineNo, FromSalesLineArchive."Attached to Line No.");
            end else
                if TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, false) then begin
                    TransferExtendedText.InsertSalesExtTextRetLast(ToSalesLine, LastInsertedSalesLine);
                    NextLineNo := LastInsertedSalesLine."Line No.";
                end;

        if CopyThisLine then begin
            OnCopyArchSalesLineOnBeforeToSalesLineInsert(ToSalesLine, FromSalesLineArchive, RecalculateLines, NextLineNo, TransferOldExtLines, ToSalesHeader);
            ToSalesLine.Insert();
            OnCopyArchSalesLineOnAfterToSalesLineInsert(ToSalesLine, FromSalesLineArchive, RecalculateLines, NextLineNo);
        end else
            LinesNotCopied := LinesNotCopied + 1;

        exit(CopyThisLine);
    end;

    procedure CopyArchPurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeaderArchive: Record "Purchase Header Archive"; var FromPurchLineArchive: Record "Purchase Line Archive"; var NextLineNo: Integer; var LinesNotCopied: Integer; RecalculateAmount: Boolean): Boolean
    var
        LastInsertedPurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        FromPurchHeader: Record "Purchase Header";
        FromPurchLine: Record "Purchase Line";
        CopyThisLine: Boolean;
        IsHandled: Boolean;
    begin
        CopyThisLine := true;
        OnBeforeCopyArchPurchLine(ToPurchHeader, FromPurchHeaderArchive, FromPurchLineArchive, RecalculateLines, CopyThisLine);
        if not CopyThisLine then begin
            LinesNotCopied := LinesNotCopied + 1;
            exit(false);
        end;

        if ((ToPurchHeader."Language Code" <> FromPurchHeaderArchive."Language Code") or RecalculateLines) and
           FromPurchLineArchive.IsExtendedText()
        then
            exit(false);

        if RecalculateLines and not FromPurchLineArchive."System-Created Entry" then
            ToPurchLine.Init()
        else
            ToPurchLine.TransferFields(FromPurchLineArchive);
        NextLineNo := NextLineNo + 10000;
        OnCopyArchPurchLineOnAfterSetNextLineNo(ToPurchLine, FromPurchLineArchive, NextLineNo);
        ToPurchLine."Document Type" := ToPurchHeader."Document Type";
        ToPurchLine."Document No." := ToPurchHeader."No.";
        ToPurchLine."Line No." := NextLineNo;
        ToPurchLine.Validate("Currency Code", FromPurchHeaderArchive."Currency Code");

        if RecalculateLines and not FromPurchLineArchive."System-Created Entry" then begin
            FromPurchHeader.TransferFields(FromPurchHeaderArchive, true);
            FromPurchLine.TransferFields(FromPurchLineArchive, true);
            RecalculatePurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, CopyThisLine);
            OnCopyArchPurchLineOnAfterRecalculatePurchLine(ToPurchLine, FromPurchLineArchive);
        end else begin
            InitPurchLineFields(ToPurchLine);

            ToPurchLine.InitOutstanding();
            if ToPurchLine."Document Type" in
               [ToPurchLine."Document Type"::"Return Order", ToPurchLine."Document Type"::"Credit Memo"]
            then
                ToPurchLine.InitQtyToShip()
            else
                ToPurchLine.InitQtyToReceive();
            ToPurchLine."VAT Difference" := FromPurchLineArchive."VAT Difference";
            ToPurchLine."Receipt No." := '';
            ToPurchLine."Receipt Line No." := 0;
            if not CreateToHeader then
                ToPurchLine."Expected Receipt Date" := ToPurchHeader."Expected Receipt Date";
            ToPurchLine."Appl.-to Item Entry" := 0;

            if FromPurchLineArchive."Drop Shipment" or FromPurchLineArchive."Special Order" then
                ToPurchLine."Purchasing Code" := '';

            OnCopyArchPurchLineOnBeforeCleanSpecialOrderDropShipmentInPurchLine(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, CreateToHeader);

            CleanSpecialOrderDropShipmentInPurchLine(ToPurchLine);

            if RecalculateAmount then begin
                ToPurchLine.Validate("Line Discount %", FromPurchLineArchive."Line Discount %");
                ToPurchLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromPurchLineArchive."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            end;
            if VATPostingSetup.Get(ToPurchLine."VAT Bus. Posting Group", ToPurchLine."VAT Prod. Posting Group") then
                ToPurchLine."VAT Identifier" := VATPostingSetup."VAT Identifier";

            ToPurchLine.UpdateWithWarehouseReceive();
            ToPurchLine."Pay-to Vendor No." := ToPurchHeader."Pay-to Vendor No.";
        end;

        OnCopyArchPurchLineOnBeforeCheckExactCostRevMandatory(ToPurchLine, FromPurchLineArchive);

        if ExactCostRevMandatory and
           (FromPurchLineArchive.Type = FromPurchLineArchive.Type::Item) and
           (FromPurchLineArchive."Appl.-to Item Entry" <> 0) and
           not MoveNegLines
        then begin
            if RecalculateAmount then begin
                ToPurchLine.Validate("Direct Unit Cost", FromPurchLineArchive."Direct Unit Cost");
                ToPurchLine.Validate(
                  "Line Discount Amount",
                  Round(FromPurchLineArchive."Line Discount Amount", Currency."Amount Rounding Precision"));
                ToPurchLine.Validate(
                  "Inv. Discount Amount",
                  Round(FromPurchLineArchive."Inv. Discount Amount", Currency."Amount Rounding Precision"));
            end;
            ToPurchLine.Validate("Appl.-to Item Entry", FromPurchLineArchive."Appl.-to Item Entry");
            if not CreateToHeader then
                if ToPurchLine."Expected Receipt Date" = 0D then
                    if ToPurchHeader."Expected Receipt Date" <> 0D then
                        ToPurchLine."Expected Receipt Date" := ToPurchHeader."Expected Receipt Date"
                    else
                        ToPurchLine."Expected Receipt Date" := WorkDate();
        end;

        if MoveNegLines and (ToPurchLine.Type <> ToPurchLine.Type::" ") then begin
            ToPurchLine.Validate(Quantity, -FromPurchLineArchive.Quantity);
            OnCopyArchPurchLineOnAfterValidateQuantityMoveNegLines(ToPurchLine, FromPurchLineArchive);
            ToPurchLine."Appl.-to Item Entry" := FromPurchLineArchive."Appl.-to Item Entry"
        end;

        IsHandled := false;
        OnCopyArchPurchLineOnBeforeCopyArchPurchLineExtText(ToPurchHeader, ToPurchLine, FromPurchHeaderArchive, FromPurchLineArchive, NextLineNo, RecalculateLines, IsHandled, TransferOldExtLines);
        if not IsHandled then
            if not ((ToPurchHeader."Language Code" <> FromPurchHeaderArchive."Language Code") or RecalculateLines) then begin
                if FromPurchLineArchive.IsExtendedText() then
                    ToPurchLine."Attached to Line No." :=
                        TransferOldExtLines.TransferExtendedText(
                          FromPurchLineArchive."Line No.", NextLineNo, FromPurchLineArchive."Attached to Line No.");
            end else
                if TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, false) then begin
                    TransferExtendedText.InsertPurchExtTextRetLast(ToPurchLine, LastInsertedPurchLine);
                    NextLineNo := LastInsertedPurchLine."Line No.";
                end;

        if CopyThisLine then begin
            OnCopyArchPurchLineOnBeforeToPurchLineInsert(ToPurchLine, FromPurchLineArchive, RecalculateLines, NextLineNo, TransferOldExtLines);
            ToPurchLine.Insert();
            OnCopyArchPurchLineOnAfterToPurchLineInsert(ToPurchLine, FromPurchLineArchive, RecalculateLines);
        end else
            LinesNotCopied := LinesNotCopied + 1;

        exit(CopyThisLine);
    end;

    local procedure CopyDocLines(RecalculateAmount: Boolean; var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line")
    begin
        if not RecalculateAmount then
            exit;
        if (ToPurchLine.Type <> ToPurchLine.Type::" ") and (ToPurchLine."No." <> '') then begin
            ToPurchLine.Validate("Line Discount %", FromPurchLine."Line Discount %");
            ToPurchLine.Validate(
              "Inv. Discount Amount",
              Round(FromPurchLine."Inv. Discount Amount", Currency."Amount Rounding Precision"));
        end;
    end;

    local procedure CheckCreditLimit(var FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCreditLimit(FromSalesHeader, ToSalesHeader, SkipTestCreditLimit, IsHandled, IncludeHeader, HideDialog, FromDocType);
        if IsHandled then
            exit;

        if SkipTestCreditLimit then
            exit;

        if IncludeHeader then
            CustCheckCreditLimit.SalesHeaderCheck(FromSalesHeader)
        else
            CustCheckCreditLimit.SalesHeaderCheck(ToSalesHeader);
    end;

    local procedure CheckUnappliedLines(SkippedLine: Boolean; var MissingExCostRevLink: Boolean)
    var
        IsHandled: Boolean;

    begin
        IsHandled := false;
        OnBeforeCheckUnappliedLines(SkippedLine, MissingExCostRevLink, WarningDone, IsHandled);
        if IsHandled then
            exit;

        if SkippedLine and MissingExCostRevLink then begin
            if not WarningDone then
                Message(Text030);
            MissingExCostRevLink := false;
            WarningDone := true;
        end;
    end;

    local procedure SetDefaultValuesToSalesLine(var ToSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line")
    var
        ShouldSetShipmentDate: Boolean;
    begin
        InitSalesLineFields(ToSalesLine);

        ClearSalesBlanketOrderFields(ToSalesLine, ToSalesHeader);
        ToSalesLine.InitOutstanding();
        if ToSalesLine."Document Type" in
           [ToSalesLine."Document Type"::"Return Order", ToSalesLine."Document Type"::"Credit Memo"]
        then
            ToSalesLine.InitQtyToReceive()
        else
            ToSalesLine.InitQtyToShip();
        ToSalesLine."VAT Difference" := FromSalesLine."VAT Difference";
        ToSalesLine."Shipment No." := '';
        ToSalesLine."Shipment Line No." := 0;
        ToSalesLine."Appl.-from Item Entry" := 0;
        ToSalesLine."Appl.-to Item Entry" := 0;
        ToSalesLine."Purchase Order No." := '';
        ToSalesLine."Purch. Order Line No." := 0;
        ToSalesLine."Special Order Purchase No." := '';
        ToSalesLine."Special Order Purch. Line No." := 0;
        ToSalesLine.Area := ToSalesHeader.Area;
        ToSalesLine."Exit Point" := ToSalesHeader."Exit Point";
        ToSalesLine."Transaction Specification" := ToSalesHeader."Transaction Specification";
        ToSalesLine."Transaction Type" := ToSalesHeader."Transaction Type";
        ToSalesLine."Transport Method" := ToSalesHeader."Transport Method";

        ShouldSetShipmentDate := (not CreateToHeader) and RecalculateLines;
        OnSetDefaultValuesToSalesLineOnBeforeSetShipmentDate(ToSalesHeader, ShouldSetShipmentDate);
        if ShouldSetShipmentDate then
            ToSalesLine."Shipment Date" := ToSalesHeader."Shipment Date";

        OnAfterSetDefaultValuesToSalesLine(ToSalesLine, ToSalesHeader, CreateToHeader, RecalculateLines, FromSalesLine);
    end;

    local procedure ClearSalesBlanketOrderFields(var ToSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        OnBeforeClearSalesBlanketOrderFields(ToSalesLine, ToSalesHeader, IsHandled);
        if IsHandled then
            exit;
        if ToSalesLine."Document Type" in
           [ToSalesLine."Document Type"::"Blanket Order",
            ToSalesLine."Document Type"::"Return Order"]
        then begin
            ToSalesLine."Blanket Order No." := '';
            ToSalesLine."Blanket Order Line No." := 0;
        end;
    end;

    local procedure SetDefaultValuesToPurchLine(var ToPurchLine: Record "Purchase Line"; ToPurchHeader: Record "Purchase Header"; VATDifference: Decimal)
    begin
        InitPurchLineFields(ToPurchLine);

        ClearPurchaseBlanketOrderFields(ToPurchLine, ToPurchHeader);
        ToPurchLine.InitOutstanding();
        if ToPurchLine."Document Type" in
           [ToPurchLine."Document Type"::"Return Order", ToPurchLine."Document Type"::"Credit Memo"]
        then
            ToPurchLine.InitQtyToShip()
        else
            ToPurchLine.InitQtyToReceive();
        ToPurchLine."VAT Difference" := VATDifference;
        ToPurchLine."Receipt No." := '';
        ToPurchLine."Receipt Line No." := 0;
        if not CreateToHeader then
            ToPurchLine."Expected Receipt Date" := ToPurchHeader."Expected Receipt Date";
        ToPurchLine."Appl.-to Item Entry" := 0;

        ToPurchLine."Sales Order No." := '';
        ToPurchLine."Sales Order Line No." := 0;
        ToPurchLine."Special Order Sales No." := '';
        ToPurchLine."Special Order Sales Line No." := 0;

        ToPurchLine.Area := ToPurchHeader.Area;
        ToPurchLine."Entry Point" := ToPurchHeader."Entry Point";
        ToPurchLine."Transaction Specification" := ToPurchHeader."Transaction Specification";
        ToPurchLine."Transaction Type" := ToPurchHeader."Transaction Type";
        ToPurchLine."Transport Method" := ToPurchHeader."Transport Method";

        OnAfterSetDefaultValuesToPurchLine(ToPurchLine, ToPurchHeader, CreateToHeader, RecalculateLines);
    end;

    local procedure ClearPurchaseBlanketOrderFields(var ToPurchLine: Record "Purchase Line"; ToPurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        OnBeforeClearPurchaseBlanketOrderFields(ToPurchLine, ToPurchHeader, IsHandled);
        if IsHandled then
            exit;
        if ToPurchLine."Document Type" in
           [ToPurchLine."Document Type"::"Blanket Order",
            ToPurchLine."Document Type"::"Return Order"]
        then begin
            ToPurchLine."Blanket Order No." := '';
            ToPurchLine."Blanket Order Line No." := 0;
        end;
    end;

    local procedure CopyItemTrackingEntries(SalesLine: Record "Sales Line"; var PurchLine: Record "Purchase Line"; SalesPricesIncludingVAT: Boolean; PurchPricesIncludingVAT: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TrackingSpecification: Record "Tracking Specification";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MissingExCostRevLink: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyItemTrackingEntries(SalesLine, PurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchasesPayablesSetup.Get();
        FindTrackingEntries(
          TempItemLedgerEntry, DATABASE::"Sales Line", TrackingSpecification."Source Subtype"::"5",
          SalesLine."Document No.", '', 0, SalesLine."Line No.", SalesLine."No.");
        ItemTrackingMgt.CopyItemLedgEntryTrkgToPurchLn(
          TempItemLedgerEntry, PurchLine, PurchasesPayablesSetup."Exact Cost Reversing Mandatory", MissingExCostRevLink,
          SalesPricesIncludingVAT, PurchPricesIncludingVAT, true);
    end;

    local procedure FindTrackingEntries(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; ItemNo: Code[20])
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.SetCurrentKey("Source ID", "Source Type", "Source Subtype", "Source Batch Name",
            "Source Prod. Order Line", "Source Ref. No.");
        TrackingSpecification.SetRange("Source ID", ID);
        TrackingSpecification.SetRange("Source Ref. No.", RefNo);
        TrackingSpecification.SetRange("Source Type", Type);
        TrackingSpecification.SetRange("Source Subtype", Subtype);
        TrackingSpecification.SetRange("Source Batch Name", BatchName);
        TrackingSpecification.SetRange("Source Prod. Order Line", ProdOrderLine);
        TrackingSpecification.SetRange("Item No.", ItemNo);
        if TrackingSpecification.FindSet() then
            repeat
                AddItemLedgerEntry(TempItemLedgerEntry, TrackingSpecification);
            until TrackingSpecification.Next() = 0;
    end;

    local procedure AddItemLedgerEntry(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; TrackingSpecification: Record "Tracking Specification")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if not TrackingSpecification.TrackingExists() then
            exit;

        if not ItemLedgerEntry.Get(TrackingSpecification."Entry No.") then
            exit;

        TempItemLedgerEntry := ItemLedgerEntry;
        if TempItemLedgerEntry.Insert() then;
    end;

    procedure CopyFieldsFromOldSalesHeader(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header")
    begin
        OnBeforeCopyFieldsFromOldSalesHeader(ToSalesHeader, OldSalesHeader);

        ToSalesHeader."No. Series" := OldSalesHeader."No. Series";
        ToSalesHeader."Posting Description" := OldSalesHeader."Posting Description";
        ToSalesHeader."Posting No." := OldSalesHeader."Posting No.";
        ToSalesHeader."Posting No. Series" := OldSalesHeader."Posting No. Series";
        ToSalesHeader."Shipping No." := OldSalesHeader."Shipping No.";
        ToSalesHeader."Shipping No. Series" := OldSalesHeader."Shipping No. Series";
        ToSalesHeader."Return Receipt No." := OldSalesHeader."Return Receipt No.";
        ToSalesHeader."Return Receipt No. Series" := OldSalesHeader."Return Receipt No. Series";
        ToSalesHeader."Prepayment No. Series" := OldSalesHeader."Prepayment No. Series";
        ToSalesHeader."Prepayment No." := OldSalesHeader."Prepayment No.";
        ToSalesHeader."Prepmt. Posting Description" := OldSalesHeader."Prepmt. Posting Description";
        ToSalesHeader."Prepmt. Cr. Memo No. Series" := OldSalesHeader."Prepmt. Cr. Memo No. Series";
        ToSalesHeader."Prepmt. Cr. Memo No." := OldSalesHeader."Prepmt. Cr. Memo No.";
        ToSalesHeader."Prepmt. Posting Description" := OldSalesHeader."Prepmt. Posting Description";
        SetSalespersonPurchaserCode(ToSalesHeader."Salesperson Code");
        ToSalesHeader."Area" := OldSalesHeader.Area;
        ToSalesHeader."Exit Point" := OldSalesHeader."Exit Point";
        ToSalesHeader."Transaction Type" := OldSalesHeader."Transaction Type";
    end;

    procedure CopyFieldsFromOldPurchHeader(var ToPurchHeader: Record "Purchase Header"; OldPurchHeader: Record "Purchase Header")
    begin
        OnBeforeCopyFieldsFromOldPurchHeader(ToPurchHeader, OldPurchHeader, IncludeHeader, MoveNegLines);

        ToPurchHeader."No. Series" := OldPurchHeader."No. Series";
        ToPurchHeader."Posting Description" := OldPurchHeader."Posting Description";
        ToPurchHeader."Posting No." := OldPurchHeader."Posting No.";
        ToPurchHeader."Posting No. Series" := OldPurchHeader."Posting No. Series";
        ToPurchHeader."Receiving No." := OldPurchHeader."Receiving No.";
        ToPurchHeader."Receiving No. Series" := OldPurchHeader."Receiving No. Series";
        ToPurchHeader."Return Shipment No." := OldPurchHeader."Return Shipment No.";
        ToPurchHeader."Return Shipment No. Series" := OldPurchHeader."Return Shipment No. Series";
        ToPurchHeader."Prepayment No. Series" := OldPurchHeader."Prepayment No. Series";
        ToPurchHeader."Prepayment No." := OldPurchHeader."Prepayment No.";
        ToPurchHeader."Prepmt. Posting Description" := OldPurchHeader."Prepmt. Posting Description";
        ToPurchHeader."Prepmt. Cr. Memo No. Series" := OldPurchHeader."Prepmt. Cr. Memo No. Series";
        ToPurchHeader."Prepmt. Cr. Memo No." := OldPurchHeader."Prepmt. Cr. Memo No.";
        ToPurchHeader."Prepmt. Posting Description" := OldPurchHeader."Prepmt. Posting Description";
        SetSalespersonPurchaserCode(ToPurchHeader."Purchaser Code");
        ToPurchHeader."Area" := OldPurchHeader.Area;
        ToPurchHeader."Entry Point" := OldPurchHeader."Entry Point";

        OnAfterCopyFieldsFromOldPurchHeaderProcedure(ToPurchHeader, OldPurchHeader);
    end;

    local procedure CheckFromSalesHeader(SalesHeaderFrom: Record "Sales Header"; SalesHeaderTo: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFromSalesHeader(SalesHeaderFrom, SalesHeaderTo, ISHandled);
        if IsHandled then
            exit;

        SalesHeaderFrom.TestField("Sell-to Customer No.", SalesHeaderTo."Sell-to Customer No.");
        SalesHeaderFrom.TestField("Bill-to Customer No.", SalesHeaderTo."Bill-to Customer No.");
        SalesHeaderFrom.TestField("Customer Posting Group", SalesHeaderTo."Customer Posting Group");
        SalesHeaderFrom.TestField("Gen. Bus. Posting Group", SalesHeaderTo."Gen. Bus. Posting Group");
        SalesHeaderFrom.TestField("Currency Code", SalesHeaderTo."Currency Code");
        SalesHeaderFrom.TestField("Prices Including VAT", SalesHeaderTo."Prices Including VAT");

        OnAfterCheckFromSalesHeader(SalesHeaderFrom, SalesHeaderTo);
    end;

    local procedure CheckFromSalesShptHeader(SalesShipmentHeaderFrom: Record "Sales Shipment Header"; SalesHeaderTo: Record "Sales Header")
    begin
        SalesShipmentHeaderFrom.TestField("Sell-to Customer No.", SalesHeaderTo."Sell-to Customer No.");
        SalesShipmentHeaderFrom.TestField("Bill-to Customer No.", SalesHeaderTo."Bill-to Customer No.");
        SalesShipmentHeaderFrom.TestField("Customer Posting Group", SalesHeaderTo."Customer Posting Group");
        SalesShipmentHeaderFrom.TestField("Gen. Bus. Posting Group", SalesHeaderTo."Gen. Bus. Posting Group");
        SalesShipmentHeaderFrom.TestField("Currency Code", SalesHeaderTo."Currency Code");
        SalesShipmentHeaderFrom.TestField("Prices Including VAT", SalesHeaderTo."Prices Including VAT");

        OnAfterCheckFromSalesShptHeader(SalesShipmentHeaderFrom, SalesHeaderTo);
    end;

    local procedure CheckFromSalesInvHeader(SalesInvoiceHeaderFrom: Record "Sales Invoice Header"; SalesHeaderTo: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFromSalesInvHeader(SalesInvoiceHeaderFrom, SalesHeaderTo, IsHandled);
        if IsHandled then
            exit;

        SalesInvoiceHeaderFrom.TestField("Sell-to Customer No.", SalesHeaderTo."Sell-to Customer No.");
        SalesInvoiceHeaderFrom.TestField("Bill-to Customer No.", SalesHeaderTo."Bill-to Customer No.");
        SalesInvoiceHeaderFrom.TestField("Customer Posting Group", SalesHeaderTo."Customer Posting Group");
        SalesInvoiceHeaderFrom.TestField("Gen. Bus. Posting Group", SalesHeaderTo."Gen. Bus. Posting Group");
        SalesInvoiceHeaderFrom.TestField("Currency Code", SalesHeaderTo."Currency Code");
        SalesInvoiceHeaderFrom.TestField("Prices Including VAT", SalesHeaderTo."Prices Including VAT");

        OnAfterCheckFromSalesInvHeader(SalesInvoiceHeaderFrom, SalesHeaderTo);
    end;

    local procedure CheckFromSalesReturnRcptHeader(ReturnReceiptHeaderFrom: Record "Return Receipt Header"; SalesHeaderTo: Record "Sales Header")
    begin
        ReturnReceiptHeaderFrom.TestField("Sell-to Customer No.", SalesHeaderTo."Sell-to Customer No.");
        ReturnReceiptHeaderFrom.TestField("Bill-to Customer No.", SalesHeaderTo."Bill-to Customer No.");
        ReturnReceiptHeaderFrom.TestField("Customer Posting Group", SalesHeaderTo."Customer Posting Group");
        ReturnReceiptHeaderFrom.TestField("Gen. Bus. Posting Group", SalesHeaderTo."Gen. Bus. Posting Group");
        ReturnReceiptHeaderFrom.TestField("Currency Code", SalesHeaderTo."Currency Code");
        ReturnReceiptHeaderFrom.TestField("Prices Including VAT", SalesHeaderTo."Prices Including VAT");

        OnAfterCheckFromSalesReturnRcptHeader(ReturnReceiptHeaderFrom, SalesHeaderTo);
    end;

    local procedure CheckFromSalesCrMemoHeader(SalesCrMemoHeaderFrom: Record "Sales Cr.Memo Header"; SalesHeaderTo: Record "Sales Header")
    begin
        SalesCrMemoHeaderFrom.TestField("Sell-to Customer No.", SalesHeaderTo."Sell-to Customer No.");
        SalesCrMemoHeaderFrom.TestField("Bill-to Customer No.", SalesHeaderTo."Bill-to Customer No.");
        SalesCrMemoHeaderFrom.TestField("Customer Posting Group", SalesHeaderTo."Customer Posting Group");
        SalesCrMemoHeaderFrom.TestField("Gen. Bus. Posting Group", SalesHeaderTo."Gen. Bus. Posting Group");
        SalesCrMemoHeaderFrom.TestField("Currency Code", SalesHeaderTo."Currency Code");
        SalesCrMemoHeaderFrom.TestField("Prices Including VAT", SalesHeaderTo."Prices Including VAT");

        OnAfterCheckFromSalesCrMemoHeader(SalesCrMemoHeaderFrom, SalesHeaderTo);
    end;

    local procedure CheckFromPurchaseHeader(PurchaseHeaderFrom: Record "Purchase Header"; PurchaseHeaderTo: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFromPurchaseHeader(PurchaseHeaderFrom, PurchaseHeaderTo, IsHandled);
        if not IsHandled then begin
            PurchaseHeaderFrom.TestField("Buy-from Vendor No.", PurchaseHeaderTo."Buy-from Vendor No.");
            PurchaseHeaderFrom.TestField("Pay-to Vendor No.", PurchaseHeaderTo."Pay-to Vendor No.");
            PurchaseHeaderFrom.TestField("Vendor Posting Group", PurchaseHeaderTo."Vendor Posting Group");
            PurchaseHeaderFrom.TestField("Gen. Bus. Posting Group", PurchaseHeaderTo."Gen. Bus. Posting Group");
            PurchaseHeaderFrom.TestField("Currency Code", PurchaseHeaderTo."Currency Code");
        end;
        OnAfterCheckFromPurchaseHeader(PurchaseHeaderFrom, PurchaseHeaderTo);
    end;

    local procedure CheckFromPurchaseRcptHeader(PurchRcptHeaderFrom: Record "Purch. Rcpt. Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
        PurchRcptHeaderFrom.TestField("Buy-from Vendor No.", PurchaseHeaderTo."Buy-from Vendor No.");
        PurchRcptHeaderFrom.TestField("Pay-to Vendor No.", PurchaseHeaderTo."Pay-to Vendor No.");
        PurchRcptHeaderFrom.TestField("Vendor Posting Group", PurchaseHeaderTo."Vendor Posting Group");
        PurchRcptHeaderFrom.TestField("Gen. Bus. Posting Group", PurchaseHeaderTo."Gen. Bus. Posting Group");
        PurchRcptHeaderFrom.TestField("Currency Code", PurchaseHeaderTo."Currency Code");

        OnAfterCheckFromPurchaseRcptHeader(PurchRcptHeaderFrom, PurchaseHeaderTo);
    end;

    local procedure CheckFromPurchaseInvHeader(PurchInvHeaderFrom: Record "Purch. Inv. Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
        PurchInvHeaderFrom.TestField("Buy-from Vendor No.", PurchaseHeaderTo."Buy-from Vendor No.");
        PurchInvHeaderFrom.TestField("Pay-to Vendor No.", PurchaseHeaderTo."Pay-to Vendor No.");
        PurchInvHeaderFrom.TestField("Vendor Posting Group", PurchaseHeaderTo."Vendor Posting Group");
        PurchInvHeaderFrom.TestField("Gen. Bus. Posting Group", PurchaseHeaderTo."Gen. Bus. Posting Group");
        PurchInvHeaderFrom.TestField("Currency Code", PurchaseHeaderTo."Currency Code");

        OnAfterCheckFromPurchaseInvHeader(PurchInvHeaderFrom, PurchaseHeaderTo);
    end;

    local procedure CheckFromPurchaseReturnShptHeader(ReturnShipmentHeaderFrom: Record "Return Shipment Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
        ReturnShipmentHeaderFrom.TestField("Buy-from Vendor No.", PurchaseHeaderTo."Buy-from Vendor No.");
        ReturnShipmentHeaderFrom.TestField("Pay-to Vendor No.", PurchaseHeaderTo."Pay-to Vendor No.");
        ReturnShipmentHeaderFrom.TestField("Vendor Posting Group", PurchaseHeaderTo."Vendor Posting Group");
        ReturnShipmentHeaderFrom.TestField("Gen. Bus. Posting Group", PurchaseHeaderTo."Gen. Bus. Posting Group");
        ReturnShipmentHeaderFrom.TestField("Currency Code", PurchaseHeaderTo."Currency Code");

        OnAfterCheckFromPurchaseReturnShptHeader(ReturnShipmentHeaderFrom, PurchaseHeaderTo);
    end;

    local procedure CheckFromPurchaseCrMemoHeader(PurchCrMemoHdrFrom: Record "Purch. Cr. Memo Hdr."; PurchaseHeaderTo: Record "Purchase Header")
    begin
        PurchCrMemoHdrFrom.TestField("Buy-from Vendor No.", PurchaseHeaderTo."Buy-from Vendor No.");
        PurchCrMemoHdrFrom.TestField("Pay-to Vendor No.", PurchaseHeaderTo."Pay-to Vendor No.");
        PurchCrMemoHdrFrom.TestField("Vendor Posting Group", PurchaseHeaderTo."Vendor Posting Group");
        PurchCrMemoHdrFrom.TestField("Gen. Bus. Posting Group", PurchaseHeaderTo."Gen. Bus. Posting Group");
        PurchCrMemoHdrFrom.TestField("Currency Code", PurchaseHeaderTo."Currency Code");

        OnAfterCheckFromPurchaseCrMemoHeader(PurchCrMemoHdrFrom, PurchaseHeaderTo);
    end;

    local procedure CopyDeferrals(DeferralDocType: Enum "Deferral Document Type"; FromDocType: Integer;
                                                       FromDocNo: Code[20];
                                                       FromLineNo: Integer;
                                                       ToDocType: Integer;
                                                       ToDocNo: Code[20];
                                                       ToLineNo: Integer) StartDate: Date
    var
        FromDeferralHeader: Record "Deferral Header";
        FromDeferralLine: Record "Deferral Line";
        ToDeferralHeader: Record "Deferral Header";
        ToDeferralLine: Record "Deferral Line";
        SalesCommentLine: Record "Sales Comment Line";
    begin
        StartDate := 0D;
        if FromDeferralHeader.Get(
             DeferralDocType, '', '',
             FromDocType, FromDocNo, FromLineNo)
        then begin
            RemoveDefaultDeferralCode(DeferralDocType, ToDocType, ToDocNo, ToLineNo);
            ToDeferralHeader.Init();
            ToDeferralHeader.TransferFields(FromDeferralHeader);
            ToDeferralHeader."Document Type" := ToDocType;
            ToDeferralHeader."Document No." := ToDocNo;
            ToDeferralHeader."Line No." := ToLineNo;
            ToDeferralHeader.Insert();
            FromDeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
            FromDeferralLine.SetRange("Gen. Jnl. Template Name", '');
            FromDeferralLine.SetRange("Gen. Jnl. Batch Name", '');
            FromDeferralLine.SetRange("Document Type", FromDocType);
            FromDeferralLine.SetRange("Document No.", FromDocNo);
            FromDeferralLine.SetRange("Line No.", FromLineNo);
            if FromDeferralLine.FindSet() then
                repeat
                    ToDeferralLine.Init();
                    ToDeferralLine.TransferFields(FromDeferralLine);
                    ToDeferralLine."Document Type" := ToDocType;
                    ToDeferralLine."Document No." := ToDocNo;
                    ToDeferralLine."Line No." := ToLineNo;
                    ToDeferralLine.Insert();
                until FromDeferralLine.Next() = 0;
            if ToDocType = SalesCommentLine."Document Type"::"Return Order".AsInteger() then
                StartDate := FromDeferralHeader."Start Date"
        end;

        OnAfterCopyDeferrals(DeferralDocType, FromDocType, FromDocNo, FromLineNo, ToDocType, ToDocNo, ToLineNo, StartDate);
    end;

    local procedure CopyPostedDeferrals(DeferralDocType: Enum "Deferral Document Type"; FromDocType: Integer;
                                                             FromDocNo: Code[20];
                                                             FromLineNo: Integer;
                                                             ToDocType: Integer;
                                                             ToDocNo: Code[20];
                                                             ToLineNo: Integer) StartDate: Date
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostedDeferralLine: Record "Posted Deferral Line";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
        SalesCommentLine: Record "Sales Comment Line";
        InitialAmountToDefer: Decimal;
    begin
        StartDate := 0D;
        if PostedDeferralHeader.Get(DeferralDocType, '', '',
             FromDocType, FromDocNo, FromLineNo)
        then begin
            RemoveDefaultDeferralCode(DeferralDocType, ToDocType, ToDocNo, ToLineNo);
            InitialAmountToDefer := 0;
            DeferralHeader.Init();
            DeferralHeader.TransferFields(PostedDeferralHeader);
            DeferralHeader."Document Type" := ToDocType;
            DeferralHeader."Document No." := ToDocNo;
            DeferralHeader."Line No." := ToLineNo;
            OnCopyPostedDeferralsOnBeforeDeferralHeaderInsert(DeferralHeader, PostedDeferralHeader);
            DeferralHeader.Insert();
            PostedDeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
            PostedDeferralLine.SetRange("Gen. Jnl. Document No.", '');
            PostedDeferralLine.SetRange("Account No.", '');
            PostedDeferralLine.SetRange("Document Type", FromDocType);
            PostedDeferralLine.SetRange("Document No.", FromDocNo);
            PostedDeferralLine.SetRange("Line No.", FromLineNo);
            if PostedDeferralLine.FindSet() then
                repeat
                    DeferralLine.Init();
                    DeferralLine.TransferFields(PostedDeferralLine);
                    DeferralLine."Document Type" := ToDocType;
                    DeferralLine."Document No." := ToDocNo;
                    DeferralLine."Line No." := ToLineNo;
                    if PostedDeferralLine."Amount (LCY)" <> 0.0 then
                        InitialAmountToDefer := InitialAmountToDefer + PostedDeferralLine."Amount (LCY)"
                    else
                        InitialAmountToDefer := InitialAmountToDefer + PostedDeferralLine.Amount;
                    OnCopyPostedDeferralsOnBeforeDeferralLineInsert(DeferralLine, PostedDeferralLine);
                    DeferralLine.Insert();
                until PostedDeferralLine.Next() = 0;
            if ToDocType = SalesCommentLine."Document Type"::"Return Order".AsInteger() then
                StartDate := PostedDeferralHeader."Start Date";
            if DeferralHeader.Get(DeferralDocType, '', '', ToDocType, ToDocNo, ToLineNo) then begin
                DeferralHeader."Initial Amount to Defer" := InitialAmountToDefer;
                OnCopyPostedDeferralsOnBeforeDeferralHeaderModify(DeferralHeader);
                DeferralHeader.Modify();
            end;
        end;

        OnAfterCopyPostedDeferrals(DeferralDocType, FromDocType, FromDocNo, FromLineNo, ToDocType, ToDocNo, ToLineNo, StartDate);
    end;

    local procedure IsDeferralToBeCopied(DeferralDocType: Enum "Deferral Document Type"; ToDocType: Option;
                                                              FromCommentDocType: Option) Result: Boolean
    var
        SalesLine: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
        PurchLine: Record "Purchase Line";
        PurchCommentLine: Record "Purch. Comment Line";
        DeferralHeader: Record "Deferral Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsDeferralToBeCopied(DeferralDocType, ToDocType, FromCommentDocType, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if DeferralDocType = DeferralHeader."Deferral Doc. Type"::Sales then
            case ToDocType of
                SalesLine."Document Type"::Order.AsInteger(),
                SalesLine."Document Type"::Invoice.AsInteger(),
                SalesLine."Document Type"::"Credit Memo".AsInteger(),
                SalesLine."Document Type"::"Return Order".AsInteger():
                    case FromCommentDocType of
                        SalesCommentLine."Document Type"::Order.AsInteger(),
                        SalesCommentLine."Document Type"::Invoice.AsInteger(),
                        SalesCommentLine."Document Type"::"Credit Memo".AsInteger(),
                        SalesCommentLine."Document Type"::"Return Order".AsInteger(),
                        SalesCommentLine."Document Type"::"Posted Invoice".AsInteger(),
                        SalesCommentLine."Document Type"::"Posted Credit Memo".AsInteger():
                            exit(true)
                    end;
            end
        else
            if DeferralDocType = DeferralHeader."Deferral Doc. Type"::Purchase then
                case ToDocType of
                    PurchLine."Document Type"::Order.AsInteger(),
                    PurchLine."Document Type"::Invoice.AsInteger(),
                    PurchLine."Document Type"::"Credit Memo".AsInteger(),
                    PurchLine."Document Type"::"Return Order".AsInteger():
                        case FromCommentDocType of
                            PurchCommentLine."Document Type"::Order.AsInteger(),
                            PurchCommentLine."Document Type"::Invoice.AsInteger(),
                            PurchCommentLine."Document Type"::"Credit Memo".AsInteger(),
                            PurchCommentLine."Document Type"::"Return Order".AsInteger(),
                            PurchCommentLine."Document Type"::"Posted Invoice".AsInteger(),
                            PurchCommentLine."Document Type"::"Posted Credit Memo".AsInteger():
                                exit(true)
                        end;
                end;

        exit(false);
    end;

    local procedure IsDeferralToBeDefaulted(DeferralDocType: Enum "Deferral Document Type"; ToDocType: Option;
                                                                 FromCommentDocType: Option) Result: Boolean
    var
        SalesLine: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
        PurchLine: Record "Purchase Line";
        PurchCommentLine: Record "Purch. Comment Line";
        DeferralHeader: Record "Deferral Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsDeferralToBeDefaulted(DeferralDocType, ToDocType, FromCommentDocType, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if DeferralDocType = DeferralHeader."Deferral Doc. Type"::Sales then
            case ToDocType of
                SalesLine."Document Type"::Order.AsInteger(),
                SalesLine."Document Type"::Invoice.AsInteger(),
                SalesLine."Document Type"::"Credit Memo".AsInteger(),
                SalesLine."Document Type"::"Return Order".AsInteger():
                    case FromCommentDocType of
                        SalesCommentLine."Document Type"::Quote.AsInteger(),
                        SalesCommentLine."Document Type"::"Blanket Order".AsInteger(),
                        SalesCommentLine."Document Type"::Shipment.AsInteger(),
                        SalesCommentLine."Document Type"::"Posted Return Receipt".AsInteger():
                            exit(true)
                    end;
            end
        else
            if DeferralDocType = DeferralHeader."Deferral Doc. Type"::Purchase then
                case ToDocType of
                    PurchLine."Document Type"::Order.AsInteger(),
                    PurchLine."Document Type"::Invoice.AsInteger(),
                    PurchLine."Document Type"::"Credit Memo".AsInteger(),
                    PurchLine."Document Type"::"Return Order".AsInteger():
                        case FromCommentDocType of
                            PurchCommentLine."Document Type"::Quote.AsInteger(),
                            PurchCommentLine."Document Type"::"Blanket Order".AsInteger(),
                            PurchCommentLine."Document Type"::Receipt.AsInteger(),
                            PurchCommentLine."Document Type"::"Posted Return Shipment".AsInteger():
                                exit(true)
                        end;
                end;

        exit(false);
    end;

    local procedure IsDeferralPosted(DeferralDocType: Enum "Deferral Document Type"; FromCommentDocType: Option): Boolean
    var
        SalesCommentLine: Record "Sales Comment Line";
        PurchCommentLine: Record "Purch. Comment Line";
        DeferralHeader: Record "Deferral Header";
    begin
        if DeferralDocType = DeferralHeader."Deferral Doc. Type"::Sales then
            case FromCommentDocType of
                SalesCommentLine."Document Type"::Shipment.AsInteger(),
                SalesCommentLine."Document Type"::"Posted Invoice".AsInteger(),
                SalesCommentLine."Document Type"::"Posted Credit Memo".AsInteger(),
                SalesCommentLine."Document Type"::"Posted Return Receipt".AsInteger():
                    exit(true);
            end
        else
            if DeferralDocType = DeferralHeader."Deferral Doc. Type"::Purchase then
                case FromCommentDocType of
                    PurchCommentLine."Document Type"::Receipt.AsInteger(),
                    PurchCommentLine."Document Type"::"Posted Invoice".AsInteger(),
                    PurchCommentLine."Document Type"::"Posted Credit Memo".AsInteger(),
                    PurchCommentLine."Document Type"::"Posted Return Shipment".AsInteger():
                        exit(true);
                end;

        exit(false);
    end;

    local procedure InitSalesDeferralCode(var ToSalesLine: Record "Sales Line")
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Resource: Record Resource;
    begin
        if ToSalesLine."No." = '' then
            exit;

        case ToSalesLine."Document Type" of
            ToSalesLine."Document Type"::Order,
            ToSalesLine."Document Type"::Invoice,
            ToSalesLine."Document Type"::"Credit Memo",
            ToSalesLine."Document Type"::"Return Order":
                case ToSalesLine.Type of
                    ToSalesLine.Type::"G/L Account":
                        begin
                            GLAccount.Get(ToSalesLine."No.");
                            ToSalesLine.Validate("Deferral Code", GLAccount."Default Deferral Template Code");
                        end;
                    ToSalesLine.Type::Item:
                        begin
                            Item.Get(ToSalesLine."No.");
                            ToSalesLine.Validate("Deferral Code", Item."Default Deferral Template Code");
                        end;
                    ToSalesLine.Type::Resource:
                        begin
                            Resource.Get(ToSalesLine."No.");
                            ToSalesLine.Validate("Deferral Code", Resource."Default Deferral Template Code");
                        end;
                end;
        end;
    end;

    local procedure InitFromSalesLine(var FromSalesLine2: Record "Sales Line"; var FromSalesLineBuf: Record "Sales Line")
    begin
        // Empty buffer fields
        FromSalesLine2 := FromSalesLineBuf;
        FromSalesLine2."Shipment No." := '';
        FromSalesLine2."Shipment Line No." := 0;
        FromSalesLine2."Return Receipt No." := '';
        FromSalesLine2."Return Receipt Line No." := 0;

        OnAfterInitFromSalesLine(FromSalesLine2, FromSalesLineBuf);
    end;

    local procedure CleanSpecialOrderDropShipmentInSalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine."Purchase Order No." := '';
        SalesLine."Purch. Order Line No." := 0;
        SalesLine."Special Order Purchase No." := '';
        SalesLine."Special Order Purch. Line No." := 0;

        OnAfterCleanSpecialOrderDropShipmentInSalesLine(SalesLine);
    end;

    local procedure CleanSpecialOrderDropShipmentInPurchLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine."Sales Order No." := '';
        PurchaseLine."Sales Order Line No." := 0;
        PurchaseLine."Special Order Sales No." := '';
        PurchaseLine."Special Order Sales Line No." := 0;
        PurchaseLine."Drop Shipment" := false;
        PurchaseLine."Special Order" := false;
    end;

    local procedure RemoveDefaultDeferralCode(DeferralDocType: Enum "Deferral Document Type"; DocType: Integer;
                                                                   DocNo: Code[20];
                                                                   LineNo: Integer)
    var
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        if DeferralHeader.Get(DeferralDocType, '', '', DocType, DocNo, LineNo) then
            DeferralHeader.Delete();

        DeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", DocType);
        DeferralLine.SetRange("Document No.", DocNo);
        DeferralLine.SetRange("Line No.", LineNo);
        DeferralLine.DeleteAll();
    end;

    procedure DeferralTypeForSalesDoc(DocType: Option): Integer
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        case DocType of
            "Sales Document Type From"::Quote.AsInteger():
                exit(SalesCommentLine."Document Type"::Quote.AsInteger());
            "Sales Document Type From"::"Blanket Order".AsInteger():
                exit(SalesCommentLine."Document Type"::"Blanket Order".AsInteger());
            "Sales Document Type From"::Order.AsInteger():
                exit(SalesCommentLine."Document Type"::Order.AsInteger());
            "Sales Document Type From"::Invoice.AsInteger():
                exit(SalesCommentLine."Document Type"::Invoice.AsInteger());
            "Sales Document Type From"::"Return Order".AsInteger():
                exit(SalesCommentLine."Document Type"::"Return Order".AsInteger());
            "Sales Document Type From"::"Credit Memo".AsInteger():
                exit(SalesCommentLine."Document Type"::"Credit Memo".AsInteger());
            "Sales Document Type From"::"Posted Shipment".AsInteger():
                exit(SalesCommentLine."Document Type"::Shipment.AsInteger());
            "Sales Document Type From"::"Posted Invoice".AsInteger():
                exit(SalesCommentLine."Document Type"::"Posted Invoice".AsInteger());
            "Sales Document Type From"::"Posted Return Receipt".AsInteger():
                exit(SalesCommentLine."Document Type"::"Posted Return Receipt".AsInteger());
            "Sales Document Type From"::"Posted Credit Memo".AsInteger():
                exit(SalesCommentLine."Document Type"::"Posted Credit Memo".AsInteger());
        end;
    end;

    procedure DeferralTypeForPurchDoc(DocType: Option): Integer
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        case DocType of
            "Purchase Document Type From"::Quote.AsInteger():
                exit(PurchCommentLine."Document Type"::Quote.AsInteger());
            "Purchase Document Type From"::"Blanket Order".AsInteger():
                exit(PurchCommentLine."Document Type"::"Blanket Order".AsInteger());
            "Purchase Document Type From"::Order.AsInteger():
                exit(PurchCommentLine."Document Type"::Order.AsInteger());
            "Purchase Document Type From"::Invoice.AsInteger():
                exit(PurchCommentLine."Document Type"::Invoice.AsInteger());
            "Purchase Document Type From"::"Return Order".AsInteger():
                exit(PurchCommentLine."Document Type"::"Return Order".AsInteger());
            "Purchase Document Type From"::"Credit Memo".AsInteger():
                exit(PurchCommentLine."Document Type"::"Credit Memo".AsInteger());
            "Purchase Document Type From"::"Posted Receipt".AsInteger():
                exit(PurchCommentLine."Document Type"::Receipt.AsInteger());
            "Purchase Document Type From"::"Posted Invoice".AsInteger():
                exit(PurchCommentLine."Document Type"::"Posted Invoice".AsInteger());
            "Purchase Document Type From"::"Posted Return Shipment".AsInteger():
                exit(PurchCommentLine."Document Type"::"Posted Return Shipment".AsInteger());
            "Purchase Document Type From"::"Posted Credit Memo".AsInteger():
                exit(PurchCommentLine."Document Type"::"Posted Credit Memo".AsInteger());
        end;
    end;

    local procedure InitPurchDeferralCode(var ToPurchLine: Record "Purchase Line")
    begin
        if ToPurchLine."No." = '' then
            exit;

        case ToPurchLine."Document Type" of
            ToPurchLine."Document Type"::Order,
          ToPurchLine."Document Type"::Invoice,
          ToPurchLine."Document Type"::"Credit Memo",
          ToPurchLine."Document Type"::"Return Order":
                ToPurchLine.InitDeferralCode();
        end;
    end;

    local procedure CopySalesPostedDeferrals(ToSalesLine: Record "Sales Line"; DeferralDocType: Enum "Deferral Document Type"; FromDocType: Integer;
                                                                                                    FromDocNo: Code[20];
                                                                                                    FromLineNo: Integer;
                                                                                                    ToDocType: Integer;
                                                                                                    ToDocNo: Code[20];
                                                                                                    ToLineNo: Integer)
    begin
        ToSalesLine."Returns Deferral Start Date" :=
            CopyPostedDeferrals(
                DeferralDocType, FromDocType, FromDocNo, FromLineNo, ToDocType, ToDocNo, ToLineNo);
        ToSalesLine.Modify();
    end;

    local procedure CopyPurchPostedDeferrals(ToPurchaseLine: Record "Purchase Line"; DeferralDocType: Enum "Deferral Document Type"; FromDocType: Integer;
                                                                                                          FromDocNo: Code[20];
                                                                                                          FromLineNo: Integer;
                                                                                                          ToDocType: Integer;
                                                                                                          ToDocNo: Code[20];
                                                                                                          ToLineNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyPurchPostedDeferrals(ToPurchaseLine, IsHandled);
        if IsHandled then
            exit;

        ToPurchaseLine."Returns Deferral Start Date" :=
            CopyPostedDeferrals(
                DeferralDocType, FromDocType, FromDocNo, FromLineNo, ToDocType, ToDocNo, ToLineNo);
        ToPurchaseLine.Modify();
    end;

    procedure CheckDateOrder(PostingNo: Code[20]; PostingNoSeries: Code[20]; OldPostingDate: Date; NewPostingDate: Date): Boolean
    var
        NoSeries: Record "No. Series";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if IncludeHeader then
            if (PostingNo <> '') and (OldPostingDate <> NewPostingDate) then
                if NoSeries.Get(PostingNoSeries) then
                    if NoSeries."Date Order" then
                        exit(ConfirmManagement.GetResponseOrDefault(DiffPostDateOrderQst, true));
        exit(true)
    end;

    local procedure CheckSalesDocItselfCopy(FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header")
    begin
        if (FromSalesHeader."Document Type" = ToSalesHeader."Document Type") and
           (FromSalesHeader."No." = ToSalesHeader."No.")
        then
            Error(Text001, ToSalesHeader."Document Type", ToSalesHeader."No.");
    end;

    local procedure CheckPurchDocItselfCopy(FromPurchHeader: Record "Purchase Header"; ToPurchHeader: Record "Purchase Header")
    begin
        if (FromPurchHeader."Document Type" = ToPurchHeader."Document Type") and
           (FromPurchHeader."No." = ToPurchHeader."No.")
        then
            Error(Text001, ToPurchHeader."Document Type", ToPurchHeader."No.");
    end;

    procedure UpdateCustLedgerEntry(var ToSalesHeader: Record "Sales Header"; FromDocType: Enum "Gen. Journal Document Type"; FromDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCustLedgEntry(ToSalesHeader, CustLedgEntry, IsHandled, FromDocType, FromDocNo);
        if IsHandled then
            exit;

        CustLedgEntry.SetCurrentKey("Document No.");
        if FromDocType = "Sales Document Type From"::"Posted Invoice" then
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice)
        else
            CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
        CustLedgEntry.SetRange("Document No.", FromDocNo);
        CustLedgEntry.SetRange("Customer No.", ToSalesHeader."Bill-to Customer No.");
        CustLedgEntry.SetRange(Open, true);
        if CustLedgEntry.FindFirst() then begin
            ToSalesHeader."Bal. Account No." := '';
            if FromDocType = "Sales Document Type From"::"Posted Invoice" then begin
                ToSalesHeader."Applies-to Doc. Type" := ToSalesHeader."Applies-to Doc. Type"::Invoice;
                ToSalesHeader."Applies-to Doc. No." := FromDocNo;
            end else begin
                ToSalesHeader."Applies-to Doc. Type" := ToSalesHeader."Applies-to Doc. Type"::"Credit Memo";
                ToSalesHeader."Applies-to Doc. No." := FromDocNo;
            end;
            CustLedgEntry.CalcFields("Remaining Amount");
            CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount";
            CustLedgEntry."Accepted Payment Tolerance" := 0;
            CustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
        end;

        OnAfterUpdateCustLedgerEntry(ToSalesHeader, FromDocType, FromDocNo, CustLedgEntry);
    end;

    procedure UpdateVendLedgEntry(var ToPurchHeader: Record "Purchase Header"; FromDocType: Enum "Gen. Journal Document Type"; FromDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateVendLedgEntry(ToPurchHeader, VendLedgEntry, IsHandled);
        if not IsHandled then begin
            VendLedgEntry.SetCurrentKey("Document No.");
            if FromDocType = "Purchase Document Type From"::"Posted Invoice" then
                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice)
            else
                VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
            VendLedgEntry.SetRange("Document No.", FromDocNo);
            VendLedgEntry.SetRange("Vendor No.", ToPurchHeader."Pay-to Vendor No.");
            VendLedgEntry.SetRange(Open, true);
            if VendLedgEntry.FindFirst() then begin
                if FromDocType = "Purchase Document Type From"::"Posted Invoice" then begin
                    ToPurchHeader."Applies-to Doc. Type" := ToPurchHeader."Applies-to Doc. Type"::Invoice;
                    ToPurchHeader."Applies-to Doc. No." := FromDocNo;
                end else begin
                    ToPurchHeader."Applies-to Doc. Type" := ToPurchHeader."Applies-to Doc. Type"::"Credit Memo";
                    ToPurchHeader."Applies-to Doc. No." := FromDocNo;
                end;
                VendLedgEntry.CalcFields("Remaining Amount");
                VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
                VendLedgEntry."Accepted Payment Tolerance" := 0;
                VendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
            end;
        end;

        OnAfterUpdateVendLedgEntry(ToPurchHeader, FromDocNo);
    end;

    local procedure UpdatePurchCreditMemoHeader(var PurchaseHeader: Record "Purchase Header")
    var
        PaymentTerms: Record "Payment Terms";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchCreditMemoHeader(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        PurchaseHeader."Expected Receipt Date" := 0D;
        GLSetup.Get();
        PurchaseHeader.Correction := GLSetup."Mark Cr. Memos as Corrections";
        if (PurchaseHeader."Payment Terms Code" <> '') and (PurchaseHeader."Document Date" <> 0D) then
            PaymentTerms.Get(PurchaseHeader."Payment Terms Code")
        else
            Clear(PaymentTerms);
        if not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
            PurchaseHeader."Payment Discount %" := 0;
            PurchaseHeader."Pmt. Discount Date" := 0D;
        end;

        OnAfterUpdatePurchCreditMemoHeader(PurchaseHeader);
    end;

    local procedure UpdateSalesCreditMemoHeader(var SalesHeader: Record "Sales Header")
    var
        PaymentTerms: Record "Payment Terms";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesCreditMemoHeader(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        SalesHeader.Correction := GLSetup."Mark Cr. Memos as Corrections";

        IsHandled := false;
        OnUpdateSalesCreditMemoHeaderOnBeforeSetShipmentDate(SalesHeader, IsHandled);
        if not IsHandled then
            SalesHeader."Shipment Date" := 0D;

        if (SalesHeader."Payment Terms Code" <> '') and (SalesHeader."Document Date" <> 0D) then
            PaymentTerms.Get(SalesHeader."Payment Terms Code")
        else
            Clear(PaymentTerms);
        if not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
            SalesHeader."Payment Discount %" := 0;
            SalesHeader."Pmt. Discount Date" := 0D;
        end;
    end;

    local procedure UpdateSalesInvoiceDiscountValue(var SalesHeader: Record "Sales Header")
    begin
        if IncludeHeader and RecalculateLines then begin
            SalesHeader.CalcFields(Amount);
            if SalesHeader."Invoice Discount Value" > SalesHeader.Amount then begin
                SalesHeader."Invoice Discount Value" := SalesHeader.Amount;
                SalesHeader.Modify();
            end;
        end;
    end;

    local procedure UpdatePurchaseInvoiceDiscountValue(var PurchaseHeader: Record "Purchase Header")
    begin
        if IncludeHeader and RecalculateLines then begin
            PurchaseHeader.CalcFields(Amount);
            if PurchaseHeader."Invoice Discount Value" > PurchaseHeader.Amount then begin
                PurchaseHeader."Invoice Discount Value" := PurchaseHeader.Amount;
                PurchaseHeader.Modify();
            end;
        end;
    end;

    local procedure ExtTxtAttachedToPosSalesLine(SalesHeader: Record "Sales Header"; MoveNegLines: Boolean; SalesLine: Record "Sales Line"): Boolean
    var
        AttachedToSalesLine: Record "Sales Line";
    begin
        if MoveNegLines then
            if SalesLine.IsExtendedText() then
                if AttachedToSalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Attached to Line No.") then
                    if AttachedToSalesLine.Quantity >= 0 then
                        exit(true);

        exit(false);
    end;

    local procedure ExtTxtAttachedToPosPurchLine(PurchHeader: Record "Purchase Header"; MoveNegLines: Boolean; PurchLine: Record "Purchase Line"): Boolean
    var
        AttachedToPurchLine: Record "Purchase Line";
    begin
        if MoveNegLines then
            if PurchLine.IsExtendedText() then
                if AttachedToPurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", PurchLine."Attached to Line No.") then
                    if AttachedToPurchLine.Quantity >= 0 then
                        exit(true);

        exit(false);
    end;

    local procedure SalesDocCanReceiveTracking(SalesHeader: Record "Sales Header"): Boolean
    begin
        exit(
          (SalesHeader."Document Type" <> SalesHeader."Document Type"::Quote) and
          (SalesHeader."Document Type" <> SalesHeader."Document Type"::"Blanket Order"));
    end;

    local procedure PurchaseDocCanReceiveTracking(PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        exit(
          (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Quote) and
          (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::"Blanket Order"));
    end;

    local procedure CheckFirstLineShipped(DocNo: Code[20]; ShipmentLineNo: Integer; var SalesCombDocLineNo: Integer; var NextLineNo: Integer; var FirstLineShipped: Boolean)
    begin
        if (DocNo = '') and (ShipmentLineNo = 0) and FirstLineShipped then begin
            FirstLineShipped := false;
            SalesCombDocLineNo := NextLineNo;
            NextLineNo := NextLineNo + 10000;
        end;
    end;

    local procedure SetTempSalesInvLine(FromSalesInvLine: Record "Sales Invoice Line"; var TempSalesInvLine: Record "Sales Invoice Line" temporary; var SalesInvLineCount: Integer; var NextLineNo: Integer; var FirstLineText: Boolean)
    begin
        if FromSalesInvLine.Type = FromSalesInvLine.Type::Item then begin
            SalesInvLineCount += 1;
            TempSalesInvLine := FromSalesInvLine;
            TempSalesInvLine.Insert();
            if FirstLineText then begin
                NextLineNo := NextLineNo + 10000;
                FirstLineText := false;
            end;
        end else
            if FromSalesInvLine.Type = FromSalesInvLine.Type::" " then
                FirstLineText := true;
    end;

    procedure InitAndCheckSalesDocuments(FromDocType: Option; FromDocNo: Code[20]; var FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesShipmentHeader: Record "Sales Shipment Header"; var FromSalesInvoiceHeader: Record "Sales Invoice Header"; var FromReturnReceiptHeader: Record "Return Receipt Header"; var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var FromSalesHeaderArchive: Record "Sales Header Archive") Result: Boolean
    var
        FromDocType2: Enum "Sales Document Type From";
        IsHandled: Boolean;
    begin
        FromDocType2 := "Sales Document Type From".FromInteger(FromDocType);

        IsHandled := false;
        OnBeforeInitAndCheckSalesDocuments(FromDocType2, FromDocNo, FromDocOccurrenceNo, FromDocVersionNo, FromSalesHeader, ToSalesHeader, ToSalesLine, MoveNegLines, IncludeHeader, RecalculateLines, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case FromDocType2 of
            "Sales Document Type From"::Quote,
            "Sales Document Type From"::"Blanket Order",
            "Sales Document Type From"::Order,
            "Sales Document Type From"::Invoice,
            "Sales Document Type From"::"Return Order",
            "Sales Document Type From"::"Credit Memo":
                begin
                    FromSalesHeader.Get(GetSalesDocumentType(FromDocType2), FromDocNo);
                    if not CheckDateOrder(
                         ToSalesHeader."Posting No.", ToSalesHeader."Posting No. Series",
                         ToSalesHeader."Posting Date", FromSalesHeader."Posting Date")
                    then
                        exit(false);
                    if MoveNegLines then begin
                        DeleteSalesLinesWithNegQty(FromSalesHeader, true);
                        OnInitAndCheckSalesDocumentsOnAfterDelNegLines(ToSalesHeader, FromSalesHeader);
                    end;
                    CheckSalesDocItselfCopy(ToSalesHeader, FromSalesHeader);

                    OnInitAndCheckSalesDocumentsOnAfterCheckSalesDocItselfCopy(ToSalesHeader, FromSalesHeader);

                    if ToSalesHeader."Document Type".AsInteger() <= ToSalesHeader."Document Type"::Invoice.AsInteger() then begin
                        FromSalesHeader.CalcFields("Amount Including VAT");
                        ToSalesHeader."Amount Including VAT" := FromSalesHeader."Amount Including VAT";

                        IsHandled := false;
                        OnInitAndCheckSalesDocumentsOnBeforeCheckCreditLimit(FromSalesHeader, ToSalesHeader, IsHandled);
                        if not IsHandled then
                            CheckCreditLimit(FromSalesHeader, ToSalesHeader, FromDocType2);
                    end;
                    CheckCopyFromSalesHeaderAvail(FromSalesHeader, ToSalesHeader);

                    if not IncludeHeader and not RecalculateLines then
                        CheckFromSalesHeader(FromSalesHeader, ToSalesHeader);
                end;
            "Sales Document Type From"::"Posted Shipment":
                begin
                    FromSalesShipmentHeader.Get(FromDocNo);
                    if not CheckDateOrder(
                         ToSalesHeader."Posting No.", ToSalesHeader."Posting No. Series",
                         ToSalesHeader."Posting Date", FromSalesShipmentHeader."Posting Date")
                    then
                        exit(false);
                    CheckCopyFromSalesShptAvail(FromSalesShipmentHeader, ToSalesHeader);

                    if not IncludeHeader and not RecalculateLines then
                        CheckFromSalesShptHeader(FromSalesShipmentHeader, ToSalesHeader);
                end;
            "Sales Document Type From"::"Posted Invoice":
                begin
                    FromSalesInvoiceHeader.Get(FromDocNo);
                    FromSalesInvoiceHeader.TestField("Prepayment Invoice", false);
                    WarnSalesInvoicePmtDisc(ToSalesHeader, FromDocType2, FromDocNo);
                    if not CheckDateOrder(
                         ToSalesHeader."Posting No.", ToSalesHeader."Posting No. Series",
                         ToSalesHeader."Posting Date", FromSalesInvoiceHeader."Posting Date")
                    then
                        exit(false);
                    if ToSalesHeader."Document Type".AsInteger() <= ToSalesHeader."Document Type"::Invoice.AsInteger() then begin
                        FromSalesInvoiceHeader.CalcFields("Amount Including VAT");
                        ToSalesHeader."Amount Including VAT" := FromSalesInvoiceHeader."Amount Including VAT";
                        if IncludeHeader then
                            FromSalesHeader.TransferFields(FromSalesInvoiceHeader);
                        CheckCreditLimit(FromSalesHeader, ToSalesHeader, FromDocType2);
                    end;
                    CheckCopyFromSalesInvoiceAvail(FromSalesInvoiceHeader, ToSalesHeader);

                    if not IncludeHeader and not RecalculateLines then
                        CheckFromSalesInvHeader(FromSalesInvoiceHeader, ToSalesHeader);
                end;
            "Sales Document Type From"::"Posted Return Receipt":
                begin
                    FromReturnReceiptHeader.Get(FromDocNo);
                    if not CheckDateOrder(
                         ToSalesHeader."Posting No.", ToSalesHeader."Posting No. Series",
                         ToSalesHeader."Posting Date", FromReturnReceiptHeader."Posting Date")
                    then
                        exit(false);
                    CheckCopyFromSalesRetRcptAvail(FromReturnReceiptHeader, ToSalesHeader);

                    if not IncludeHeader and not RecalculateLines then
                        CheckFromSalesReturnRcptHeader(FromReturnReceiptHeader, ToSalesHeader);
                end;
            "Sales Document Type From"::"Posted Credit Memo":
                begin
                    FromSalesCrMemoHeader.Get(FromDocNo);
                    FromSalesCrMemoHeader.TestField("Prepayment Credit Memo", false);
                    WarnSalesInvoicePmtDisc(ToSalesHeader, FromDocType2, FromDocNo);
                    if not CheckDateOrder(
                         ToSalesHeader."Posting No.", ToSalesHeader."Posting No. Series",
                         ToSalesHeader."Posting Date", FromSalesCrMemoHeader."Posting Date")
                    then
                        exit(false);
                    if ToSalesHeader."Document Type".AsInteger() <= ToSalesHeader."Document Type"::Invoice.AsInteger() then begin
                        FromSalesCrMemoHeader.CalcFields("Amount Including VAT");
                        ToSalesHeader."Amount Including VAT" := FromSalesCrMemoHeader."Amount Including VAT";
                        if IncludeHeader then
                            FromSalesHeader.TransferFields(FromSalesCrMemoHeader);
                        CheckCreditLimit(FromSalesHeader, ToSalesHeader, FromDocType2);
                    end;
                    CheckCopyFromSalesCrMemoAvail(FromSalesCrMemoHeader, ToSalesHeader);

                    if not IncludeHeader and not RecalculateLines then
                        CheckFromSalesCrMemoHeader(FromSalesCrMemoHeader, ToSalesHeader);
                end;
            "Sales Document Type From"::"Arch. Quote",
            "Sales Document Type From"::"Arch. Order",
            "Sales Document Type From"::"Arch. Blanket Order",
            "Sales Document Type From"::"Arch. Return Order":
                begin
                    FromSalesHeaderArchive.Get(GetSalesDocumentType(FromDocType2), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo);
                    if FromDocType2.AsInteger() <= "Sales Document Type From"::Invoice.AsInteger() then begin
                        FromSalesHeaderArchive.CalcFields("Amount Including VAT");
                        ToSalesHeader."Amount Including VAT" := FromSalesHeaderArchive."Amount Including VAT";
                        CustCheckCreditLimit.SalesHeaderCheck(ToSalesHeader);
                    end;

                    CheckCopyFromSalesHeaderArchiveAvail(FromSalesHeaderArchive, ToSalesHeader);

                    if not IncludeHeader and not RecalculateLines then begin
                        FromSalesHeaderArchive.TestField("Sell-to Customer No.", ToSalesHeader."Sell-to Customer No.");
                        FromSalesHeaderArchive.TestField("Bill-to Customer No.", ToSalesHeader."Bill-to Customer No.");
                        FromSalesHeaderArchive.TestField("Customer Posting Group", ToSalesHeader."Customer Posting Group");
                        FromSalesHeaderArchive.TestField("Gen. Bus. Posting Group", ToSalesHeader."Gen. Bus. Posting Group");
                        FromSalesHeaderArchive.TestField("Currency Code", ToSalesHeader."Currency Code");
                        FromSalesHeaderArchive.TestField("Prices Including VAT", ToSalesHeader."Prices Including VAT");
                    end;
                end;
        end;

        OnAfterInitAndCheckSalesDocuments(
          FromDocType, FromDocNo, FromDocOccurrenceNo, FromDocVersionNo,
          FromSalesHeader, ToSalesHeader, ToSalesLine,
          FromSalesShipmentHeader, FromSalesInvoiceHeader, FromReturnReceiptHeader, FromSalesCrMemoHeader, FromSalesHeaderArchive,
          IncludeHeader, RecalculateLines);

        exit(true);
    end;

    procedure InitAndCheckPurchaseDocuments(FromDocType: Option; FromDocNo: Code[20]; var FromPurchaseHeader: Record "Purchase Header"; var ToPurchaseHeader: Record "Purchase Header"; var FromPurchRcptHeader: Record "Purch. Rcpt. Header"; var FromPurchInvHeader: Record "Purch. Inv. Header"; var FromReturnShipmentHeader: Record "Return Shipment Header"; var FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var FromPurchaseHeaderArchive: Record "Purchase Header Archive"): Boolean
    var
        FromDocType2: Enum "Purchase Document Type From";
    begin
        FromDocType2 := "Purchase Document Type From".FromInteger(FromDocType);
        case FromDocType2 of
            "Purchase Document Type From"::Quote,
            "Purchase Document Type From"::"Blanket Order",
            "Purchase Document Type From"::Order,
            "Purchase Document Type From"::Invoice,
            "Purchase Document Type From"::"Return Order",
            "Purchase Document Type From"::"Credit Memo":
                begin
                    FromPurchaseHeader.Get(GetPurchaseDocumentType(FromDocType2), FromDocNo);
                    if not CheckDateOrder(
                         ToPurchaseHeader."Posting No.", ToPurchaseHeader."Posting No. Series",
                         ToPurchaseHeader."Posting Date", FromPurchaseHeader."Posting Date")
                    then
                        exit(false);
                    if MoveNegLines then begin
                        DeletePurchLinesWithNegQty(FromPurchaseHeader, true);
                        OnInitAndCheckPurchaseDocumentsOnAfterDelNegLines(ToPurchaseHeader, FromPurchaseHeader);
                    end;
                    CheckPurchDocItselfCopy(ToPurchaseHeader, FromPurchaseHeader);

                    OnInitAndCheckPurchaseDocumentsOnAfterCheckPurchDocItselfCopy(ToPurchaseHeader, FromPurchaseHeader);

                    if not IncludeHeader and not RecalculateLines then
                        CheckFromPurchaseHeader(FromPurchaseHeader, ToPurchaseHeader);
                end;
            "Purchase Document Type From"::"Posted Receipt":
                begin
                    FromPurchRcptHeader.Get(FromDocNo);
                    if not CheckDateOrder(
                         ToPurchaseHeader."Posting No.", ToPurchaseHeader."Posting No. Series",
                         ToPurchaseHeader."Posting Date", FromPurchRcptHeader."Posting Date")
                    then
                        exit(false);
                    if not IncludeHeader and not RecalculateLines then
                        CheckFromPurchaseRcptHeader(FromPurchRcptHeader, ToPurchaseHeader);
                end;
            "Purchase Document Type From"::"Posted Invoice":
                begin
                    FromPurchInvHeader.Get(FromDocNo);
                    if not CheckDateOrder(
                         ToPurchaseHeader."Posting No.", ToPurchaseHeader."Posting No. Series",
                         ToPurchaseHeader."Posting Date", FromPurchInvHeader."Posting Date")
                    then
                        exit(false);
                    FromPurchInvHeader.TestField("Prepayment Invoice", false);
                    WarnPurchInvoicePmtDisc(ToPurchaseHeader, FromDocType2, FromDocNo);
                    if not IncludeHeader and not RecalculateLines then
                        CheckFromPurchaseInvHeader(FromPurchInvHeader, ToPurchaseHeader);
                end;
            "Purchase Document Type From"::"Posted Return Shipment":
                begin
                    FromReturnShipmentHeader.Get(FromDocNo);
                    if not CheckDateOrder(
                         ToPurchaseHeader."Posting No.", ToPurchaseHeader."Posting No. Series",
                         ToPurchaseHeader."Posting Date", FromReturnShipmentHeader."Posting Date")
                    then
                        exit(false);
                    if not IncludeHeader and not RecalculateLines then
                        CheckFromPurchaseReturnShptHeader(FromReturnShipmentHeader, ToPurchaseHeader);
                end;
            "Purchase Document Type From"::"Posted Credit Memo":
                begin
                    FromPurchCrMemoHdr.Get(FromDocNo);
                    if not CheckDateOrder(
                         ToPurchaseHeader."Posting No.", ToPurchaseHeader."Posting No. Series",
                         ToPurchaseHeader."Posting Date", FromPurchCrMemoHdr."Posting Date")
                    then
                        exit(false);
                    FromPurchCrMemoHdr.TestField("Prepayment Credit Memo", false);
                    WarnPurchInvoicePmtDisc(ToPurchaseHeader, FromDocType2, FromDocNo);
                    if not IncludeHeader and not RecalculateLines then
                        CheckFromPurchaseCrMemoHeader(FromPurchCrMemoHdr, ToPurchaseHeader);
                end;
            "Purchase Document Type From"::"Arch. Order",
            "Purchase Document Type From"::"Arch. Quote",
            "Purchase Document Type From"::"Arch. Blanket Order",
            "Purchase Document Type From"::"Arch. Return Order":
                begin
                    FromPurchaseHeaderArchive.Get(GetPurchaseDocumentType(FromDocType2), FromDocNo, FromDocOccurrenceNo, FromDocVersionNo);
                    if not IncludeHeader and not RecalculateLines then begin
                        FromPurchaseHeaderArchive.TestField("Buy-from Vendor No.", ToPurchaseHeader."Buy-from Vendor No.");
                        FromPurchaseHeaderArchive.TestField("Pay-to Vendor No.", ToPurchaseHeader."Pay-to Vendor No.");
                        FromPurchaseHeaderArchive.TestField("Vendor Posting Group", ToPurchaseHeader."Vendor Posting Group");
                        FromPurchaseHeaderArchive.TestField("Gen. Bus. Posting Group", ToPurchaseHeader."Gen. Bus. Posting Group");
                        FromPurchaseHeaderArchive.TestField("Currency Code", ToPurchaseHeader."Currency Code");
                    end;
                end;
        end;

        OnAfterInitAndCheckPurchaseDocuments(
          FromDocType, FromDocNo, FromDocOccurrenceNo, FromDocVersionNo,
          FromPurchaseHeader, ToPurchaseHeader,
          FromPurchRcptHeader, FromPurchInvHeader, FromReturnShipmentHeader, FromPurchCrMemoHdr, FromPurchaseHeaderArchive,
          IncludeHeader, RecalculateLines);

        exit(true);
    end;

    procedure InitSalesLineFields(var ToSalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeInitSalesLineFields(ToSalesLine);

        if ToSalesLine."Document Type" <> ToSalesLine."Document Type"::Order then begin
            ToSalesLine."Prepayment %" := 0;
            ToSalesLine."Prepayment VAT %" := 0;
            ToSalesLine."Prepmt. VAT Calc. Type" := "Tax Calculation Type"::"Normal VAT";
            ToSalesLine."Prepayment VAT Identifier" := '';
            ToSalesLine."Prepayment VAT %" := 0;
            ToSalesLine."Prepayment Tax Group Code" := '';
            ToSalesLine."Prepmt. Line Amount" := 0;
            ToSalesLine."Prepmt. Amt. Incl. VAT" := 0;
        end;
        ToSalesLine."Prepmt. Amt. Inv." := 0;
        ToSalesLine."Prepmt. Amount Inv. (LCY)" := 0;
        ToSalesLine."Prepayment Amount" := 0;
        ToSalesLine."Prepmt. VAT Base Amt." := 0;
        ToSalesLine."Prepmt Amt to Deduct" := 0;
        ToSalesLine."Prepmt Amt Deducted" := 0;
        ToSalesLine."Prepmt. Amount Inv. Incl. VAT" := 0;
        ToSalesLine."Prepayment VAT Difference" := 0;
        ToSalesLine."Prepmt VAT Diff. to Deduct" := 0;
        ToSalesLine."Prepmt VAT Diff. Deducted" := 0;
        ToSalesLine."Prepmt. Amt. Incl. VAT" := 0;
        ToSalesLine."Prepmt. VAT Amount Inv. (LCY)" := 0;

        IsHandled := false;
        OnInitSalesLineFieldsOnBeforeInitQty(ToSalesLine, IsHandled);
        if not IsHandled then begin
            ToSalesLine."Quantity Shipped" := 0;
            ToSalesLine."Qty. Shipped (Base)" := 0;
            ToSalesLine."Return Qty. Received" := 0;
            ToSalesLine."Return Qty. Received (Base)" := 0;
            ToSalesLine."Quantity Invoiced" := 0;
            ToSalesLine."Qty. Invoiced (Base)" := 0;
        end;

        ToSalesLine."Reserved Quantity" := 0;
        ToSalesLine."Reserved Qty. (Base)" := 0;
        ToSalesLine."Qty. to Ship" := 0;
        ToSalesLine."Qty. to Ship (Base)" := 0;
        ToSalesLine."Return Qty. to Receive" := 0;
        ToSalesLine."Return Qty. to Receive (Base)" := 0;
        ToSalesLine."Qty. to Invoice" := 0;
        ToSalesLine."Qty. to Invoice (Base)" := 0;
        ToSalesLine."Qty. Shipped Not Invoiced" := 0;
        ToSalesLine."Return Qty. Rcd. Not Invd." := 0;
        ToSalesLine."Shipped Not Invoiced" := 0;
        ToSalesLine."Return Rcd. Not Invd." := 0;
        ToSalesLine."Qty. Shipped Not Invd. (Base)" := 0;
        ToSalesLine."Ret. Qty. Rcd. Not Invd.(Base)" := 0;
        ToSalesLine."Shipped Not Invoiced (LCY)" := 0;
        ToSalesLine."Return Rcd. Not Invd. (LCY)" := 0;
        InitJobFieldsForSalesLine(ToSalesLine);

        OnAfterInitSalesLineFields(ToSalesLine);
    end;

    procedure InitJobFieldsForSalesLine(var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitJobFieldsForSalesLine(SalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine."Job No." := '';
        SalesLine."Job Task No." := '';
        SalesLine."Job Contract Entry No." := 0;
    end;

    procedure InitPurchLineFields(var ToPurchLine: Record "Purchase Line")
    begin
        OnBeforeInitPurchLineFields(ToPurchLine);

        if ToPurchLine."Document Type" <> ToPurchLine."Document Type"::Order then begin
            ToPurchLine."Prepayment %" := 0;
            ToPurchLine."Prepayment VAT %" := 0;
            ToPurchLine."Prepmt. VAT Calc. Type" := "Tax Calculation Type"::"Normal VAT";
            ToPurchLine."Prepayment VAT Identifier" := '';
            ToPurchLine."Prepayment VAT %" := 0;
            ToPurchLine."Prepayment Tax Group Code" := '';
            ToPurchLine."Prepmt. Line Amount" := 0;
            ToPurchLine."Prepmt. Amt. Incl. VAT" := 0;
        end;
        ToPurchLine."Prepmt. Amt. Inv." := 0;
        ToPurchLine."Prepmt. Amount Inv. (LCY)" := 0;
        ToPurchLine."Prepayment Amount" := 0;
        ToPurchLine."Prepmt. VAT Base Amt." := 0;
        ToPurchLine."Prepmt Amt to Deduct" := 0;
        ToPurchLine."Prepmt Amt Deducted" := 0;
        ToPurchLine."Prepmt. Amount Inv. Incl. VAT" := 0;
        ToPurchLine."Prepayment VAT Difference" := 0;
        ToPurchLine."Prepmt VAT Diff. to Deduct" := 0;
        ToPurchLine."Prepmt VAT Diff. Deducted" := 0;
        ToPurchLine."Prepmt. Amt. Incl. VAT" := 0;
        ToPurchLine."Prepmt. VAT Amount Inv. (LCY)" := 0;
        ToPurchLine."Quantity Received" := 0;
        ToPurchLine."Qty. Received (Base)" := 0;
        ToPurchLine."Return Qty. Shipped" := 0;
        ToPurchLine."Return Qty. Shipped (Base)" := 0;
        ToPurchLine."Quantity Invoiced" := 0;
        ToPurchLine."Qty. Invoiced (Base)" := 0;
        ToPurchLine."Reserved Quantity" := 0;
        ToPurchLine."Reserved Qty. (Base)" := 0;
        ToPurchLine."Qty. Rcd. Not Invoiced" := 0;
        ToPurchLine."Qty. Rcd. Not Invoiced (Base)" := 0;
        ToPurchLine."Return Qty. Shipped Not Invd." := 0;
        ToPurchLine."Ret. Qty. Shpd Not Invd.(Base)" := 0;
        ToPurchLine."Qty. to Receive" := 0;
        ToPurchLine."Qty. to Receive (Base)" := 0;
        ToPurchLine."Return Qty. to Ship" := 0;
        ToPurchLine."Return Qty. to Ship (Base)" := 0;
        ToPurchLine."Qty. to Invoice" := 0;
        ToPurchLine."Qty. to Invoice (Base)" := 0;
        ToPurchLine."Amt. Rcd. Not Invoiced" := 0;
        ToPurchLine."Amt. Rcd. Not Invoiced (LCY)" := 0;
        ToPurchLine."Return Shpd. Not Invd." := 0;
        ToPurchLine."Return Shpd. Not Invd. (LCY)" := 0;

        OnAfterInitPurchLineFields(ToPurchLine);
    end;

    local procedure CopySalesJobFields(var ToSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopySalesJobFields(ToSalesLine, FromSalesLine, IsHandled);
        if IsHandled then
            exit;

        ToSalesLine."Job No." := FromSalesLine."Job No.";
        ToSalesLine."Job Task No." := FromSalesLine."Job Task No.";
        if ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::Invoice then
            ToSalesLine."Job Contract Entry No." :=
              CreateJobPlanningLine(ToSalesHeader, ToSalesLine, FromSalesLine."Job Contract Entry No.")
        else
            ToSalesLine."Job Contract Entry No." := FromSalesLine."Job Contract Entry No.";
    end;

    local procedure CopySalesLineExtText(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; DocLineNo: Integer; var NextLineNo: Integer)
    var
        LastInsertedSalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopySalesLineExtText(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, DocLineNo, NextLineNo, IsHandled, RecalculateLines, CopyExtText, TransferOldExtLines);
        if IsHandled then
            exit;

        if (ToSalesHeader."Language Code" <> FromSalesHeader."Language Code") or RecalculateLines or CopyExtText then
            if TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, false) then begin
                TransferExtendedText.InsertSalesExtTextRetLast(ToSalesLine, LastInsertedSalesLine);
                NextLineNo := LastInsertedSalesLine."Line No.";
                exit;
            end;

        ToSalesLine."Attached to Line No." :=
          TransferOldExtLines.TransferExtendedText(DocLineNo, NextLineNo, FromSalesLine."Attached to Line No.");

        OnAfterCopySalesLineExtText(ToSalesHeader, ToSalesLine, FromSalesHeader, FromSalesLine, DocLineNo, NextLineNo, TransferOldExtLines, RecalculateLines);
    end;

    procedure CopySalesLinesToDoc(FromDocType: Option; ToSalesHeader: Record "Sales Header"; var FromSalesShipmentLine: Record "Sales Shipment Line"; var FromSalesInvoiceLine: Record "Sales Invoice Line"; var FromReturnReceiptLine: Record "Return Receipt Line"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopySalesLinesToDoc(
          FromDocType, ToSalesHeader, FromSalesShipmentLine, FromSalesInvoiceLine, FromReturnReceiptLine, FromSalesCrMemoLine,
          LinesNotCopied, MissingExCostRevLink, IsHandled);
        if not IsHandled then begin
            CopyExtText := true;
            case FromDocType of
                "Sales Document Type From"::"Posted Shipment".AsInteger():
                    CopySalesShptLinesToDoc(ToSalesHeader, FromSalesShipmentLine, LinesNotCopied, MissingExCostRevLink);
                "Sales Document Type From"::"Posted Invoice".AsInteger():
                    CopySalesInvLinesToDoc(ToSalesHeader, FromSalesInvoiceLine, LinesNotCopied, MissingExCostRevLink);
                "Sales Document Type From"::"Posted Return Receipt".AsInteger():
                    CopySalesReturnRcptLinesToDoc(ToSalesHeader, FromReturnReceiptLine, LinesNotCopied, MissingExCostRevLink);
                "Sales Document Type From"::"Posted Credit Memo".AsInteger():
                    CopySalesCrMemoLinesToDoc(ToSalesHeader, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
            end;
            CopyExtText := false;
        end;
        OnAfterCopySalesLinesToDoc(
          FromDocType, ToSalesHeader, FromSalesShipmentLine, FromSalesInvoiceLine, FromReturnReceiptLine, FromSalesCrMemoLine,
          LinesNotCopied, MissingExCostRevLink, RecalculateLines, IncludeHeader);
    end;

    local procedure CopyPurchaseJobFields(var ToPurchLine: Record "Purchase Line"; FromPurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyPurchaseJobFields(ToPurchLine, FromPurchLine, IsHandled, RecalculateLines);
        if IsHandled then
            exit;

        ToPurchLine.Validate("Job No.", FromPurchLine."Job No.");
        ToPurchLine.Validate("Job Task No.", FromPurchLine."Job Task No.");
        ToPurchLine.Validate("Job Planning Line No.", FromPurchLine."Job Planning Line No.");
    end;

    local procedure CopyPurchLineExtText(ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; FromPurchHeader: Record "Purchase Header"; FromPurchLine: Record "Purchase Line"; DocLineNo: Integer; var NextLineNo: Integer)
    var
        LastInsertedPurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyPurchLineExtText(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, DocLineNo, NextLineNo, IsHandled, RecalculateLines, CopyExtText);
        if not IsHandled then begin
            if (ToPurchHeader."Language Code" <> FromPurchHeader."Language Code") or RecalculateLines or CopyExtText then
                if TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, false) then begin
                    TransferExtendedText.InsertPurchExtTextRetLast(ToPurchLine, LastInsertedPurchLine);
                    NextLineNo := LastInsertedPurchLine."Line No.";
                    exit;
                end;

            ToPurchLine."Attached to Line No." :=
              TransferOldExtLines.TransferExtendedText(DocLineNo, NextLineNo, FromPurchLine."Attached to Line No.");
        end;
        OnAfterCopyPurchLineExtText(ToPurchHeader, ToPurchLine, FromPurchHeader, FromPurchLine, DocLineNo, NextLineNo, TransferOldExtLines, RecalculateLines);
    end;

    procedure CopyPurchaseLinesToDoc(FromDocType: Option; ToPurchaseHeader: Record "Purchase Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line"; var FromPurchInvLine: Record "Purch. Inv. Line"; var FromReturnShipmentLine: Record "Return Shipment Line"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyPurchaseLinesToDoc(
          FromDocType, ToPurchaseHeader, FromPurchRcptLine, FromPurchInvLine, FromReturnShipmentLine, FromPurchCrMemoLine,
          LinesNotCopied, MissingExCostRevLink, IsHandled);
        if IsHandled then
            exit;
        CopyExtText := true;
        case FromDocType of
            "Purchase Document Type From"::"Posted Receipt".AsInteger():
                CopyPurchRcptLinesToDoc(ToPurchaseHeader, FromPurchRcptLine, LinesNotCopied, MissingExCostRevLink);
            "Purchase Document Type From"::"Posted Invoice".AsInteger():
                CopyPurchInvLinesToDoc(ToPurchaseHeader, FromPurchInvLine, LinesNotCopied, MissingExCostRevLink);
            "Purchase Document Type From"::"Posted Return Shipment".AsInteger():
                CopyPurchReturnShptLinesToDoc(ToPurchaseHeader, FromReturnShipmentLine, LinesNotCopied, MissingExCostRevLink);
            "Purchase Document Type From"::"Posted Credit Memo".AsInteger():
                CopyPurchCrMemoLinesToDoc(ToPurchaseHeader, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink);
        end;
        CopyExtText := false;
        OnAfterCopyPurchaseLinesToDoc(
          FromDocType, ToPurchaseHeader, FromPurchRcptLine, FromPurchInvLine, FromReturnShipmentLine, FromPurchCrMemoLine,
          LinesNotCopied, MissingExCostRevLink, RecalculateLines, IncludeHeader);
    end;

    local procedure CopyShiptoCodeFromInvToCrMemo(var ToSalesHeader: Record "Sales Header"; FromSalesInvHeader: Record "Sales Invoice Header"; FromDocType: Enum "Sales Document Type From")
    begin
        if (FromDocType = "Sales Document Type From"::"Posted Invoice") and
           (FromSalesInvHeader."Ship-to Code" <> '') and
           (ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::"Credit Memo")
        then
            ToSalesHeader."Ship-to Code" := FromSalesInvHeader."Ship-to Code";

        OnAfterCopyShiptoCodeFromInvToCrMemo(ToSalesHeader, FromSalesInvHeader, FromDocType);
    end;

    local procedure TransferFieldsFromCrMemoToInv(var ToSalesHeader: Record "Sales Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferFieldsFromCrMemoToInv(ToSalesHeader, FromSalesCrMemoHeader, IsHandled);
        if not IsHandled then begin
            ToSalesHeader.Validate("Sell-to Customer No.", FromSalesCrMemoHeader."Sell-to Customer No.");
            OnTransferFieldsFromCrMemoToInvOnBeforeTransferFields(ToSalesHeader, FromSalesCrMemoHeader);
            ToSalesHeader.TransferFields(FromSalesCrMemoHeader, false);
            if (ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::Invoice) and IncludeHeader then begin
                ToSalesHeader.CopySellToAddressToShipToAddress();
                ToSalesHeader.Validate("Ship-to Code", FromSalesCrMemoHeader."Ship-to Code");
            end;
            SetReceivedFromCountryCode(ToSalesHeader);
        end;

        OnAfterTransferFieldsFromCrMemoToInv(ToSalesHeader, FromSalesCrMemoHeader, CopyJobData);
    end;

    procedure CopyShippingInfoPurchOrder(var ToPurchaseHeader: Record "Purchase Header"; FromPurchaseHeader: Record "Purchase Header")
    begin
        if (ToPurchaseHeader."Document Type" = ToPurchaseHeader."Document Type"::Order) and
           (FromPurchaseHeader."Document Type" = FromPurchaseHeader."Document Type"::Order)
        then begin
            ToPurchaseHeader."Ship-to Address" := FromPurchaseHeader."Ship-to Address";
            ToPurchaseHeader."Ship-to Address 2" := FromPurchaseHeader."Ship-to Address 2";
            ToPurchaseHeader."Ship-to City" := FromPurchaseHeader."Ship-to City";
            ToPurchaseHeader."Ship-to Country/Region Code" := FromPurchaseHeader."Ship-to Country/Region Code";
            ToPurchaseHeader."Ship-to County" := FromPurchaseHeader."Ship-to County";
            ToPurchaseHeader."Ship-to Name" := FromPurchaseHeader."Ship-to Name";
            ToPurchaseHeader."Ship-to Name 2" := FromPurchaseHeader."Ship-to Name 2";
            ToPurchaseHeader."Ship-to Post Code" := FromPurchaseHeader."Ship-to Post Code";
            ToPurchaseHeader."Ship-to Contact" := FromPurchaseHeader."Ship-to Contact";
            ToPurchaseHeader."Inbound Whse. Handling Time" := FromPurchaseHeader."Inbound Whse. Handling Time";
        end;
    end;

    local procedure SetSalespersonPurchaserCode(var SalespersonPurchaserCode: Code[20])
    begin
        if SalespersonPurchaserCode <> '' then
            if SalespersonPurchaser.Get(SalespersonPurchaserCode) then
                if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
                    SalespersonPurchaserCode := ''
    end;

    local procedure SetReceivedFromCountryCode(FromDocType: Enum "Sales Document Type From"; var ToSalesHeader: Record "Sales Header")
    begin
        if not ToSalesHeader.IsCreditDocType() then
            ToSalesHeader."Rcvd.-from Count./Region Code" := '';
        if not (FromDocType in [FromDocType::"Credit Memo", FromDocType::"Return Order"]) then
            ToSalesHeader."Rcvd.-from Count./Region Code" := '';
    end;

    local procedure SetReceivedFromCountryCode(FromSalesHeaderArchive: Record "Sales Header Archive"; var ToSalesHeader: Record "Sales Header")
    begin
        if not ToSalesHeader.IsCreditDocType() then
            ToSalesHeader."Rcvd.-from Count./Region Code" := '';
        if not (FromSalesHeaderArchive."Document Type" in [FromSalesHeaderArchive."Document Type"::"Return Order"]) then
            ToSalesHeader."Rcvd.-from Count./Region Code" := '';
    end;

    local procedure SetReceivedFromCountryCode(FromSalesShipmentHeader: Record "Sales Shipment Header"; var ToSalesHeader: Record "Sales Header")
    begin
        if not ToSalesHeader.IsCreditDocType() then
            ToSalesHeader."Rcvd.-from Count./Region Code" := ''
        else
            ToSalesHeader."Rcvd.-from Count./Region Code" := FromSalesShipmentHeader."Ship-to Country/Region Code";
    end;

    local procedure SetReceivedFromCountryCode(SalesInvoiceHeader: Record "Sales Invoice Header"; var ToSalesHeader: Record "Sales Header")
    begin
        if not ToSalesHeader.IsCreditDocType() then
            ToSalesHeader."Rcvd.-from Count./Region Code" := ''
        else
            ToSalesHeader."Rcvd.-from Count./Region Code" := SalesInvoiceHeader."Ship-to Country/Region Code";
    end;

    local procedure UpdateShipToAddress(var ToSalesHeader: Record "Sales Header")
    begin
        if not ToSalesHeader.IsCreditDocType() then
            exit;
        ToSalesHeader.UpdateShipToAddress();
    end;

    local procedure SetReceivedFromCountryCode(var ToSalesHeader: Record "Sales Header")
    begin
        if not ToSalesHeader.IsCreditDocType() then
            ToSalesHeader."Rcvd.-from Count./Region Code" := '';
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCopySalesDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyItemTrackingEntries(SalesLine: Record "Sales Line"; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignDescriptionsFromSalesLine(var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesLine(var ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; RecalculateAmount: Boolean; var CopyThisLine: Boolean; MoveNegLines: Boolean; var Result: Boolean; var IsHandled: Boolean; DocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesDocSalesLineArchive(FromSalesHeaderArchive: Record "Sales Header Archive"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesDocSalesLine(FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyArchSalesLine(var ToSalesHeader: Record "Sales Header"; FromSalesHeaderArchive: Record "Sales Header Archive"; FromSalesLineArchive: Record "Sales Line Archive"; RecalculateAmount: Boolean; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCopyPurchaseDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchLine(var ToPurchHeader: Record "Purchase Header"; FromPurchHeader: Record "Purchase Header"; FromPurchLine: Record "Purchase Line"; RecalculateAmount: Boolean; var CopyThisLine: Boolean; ToPurchLine: Record "Purchase Line"; MoveNegLines: Boolean; var RoundingLineInserted: Boolean; var Result: Boolean; var IsHandled: Boolean; FromPurchDocType: Enum "Purchase Document Type From"; DocLineNo: Integer;
                                                                                                                                                                                                                                                                                                                                                                                                  RecalculateLines: Boolean; var LinesNotCopied: Integer; var CopyPostedDeferral: Boolean; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchRcptLinesToDoc(ToPurchHeader: Record "Purchase Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyArchPurchLine(var ToPurchHeader: Record "Purchase Header"; FromPurchHeaderArchive: Record "Purchase Header Archive"; FromPurchLineArchive: Record "Purchase Line Archive"; RecalculateAmount: Boolean; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesHeader(var ToSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20]; IncludeHeader: Boolean; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer; RecalculateLines: Boolean; FromSalesHeader: Record "Sales Header"; FromSalesInvoiceHeader: Record "Sales Invoice Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; OldSalesHeader: Record "Sales Header")
    begin
    end;

    local procedure AddSalesDocLine(var TempDocSalesLine: Record "Sales Line" temporary; BufferLineNo: Integer; DocumentNo: Code[20]; DocumentLineNo: Integer)
    begin
        OnBeforeAddSalesDocLine(TempDocSalesLine, BufferLineNo, DocumentNo, DocumentLineNo);

        TempDocSalesLine."Document No." := DocumentNo;
        TempDocSalesLine."Line No." := DocumentLineNo;
        TempDocSalesLine."Shipment Line No." := BufferLineNo;
        TempDocSalesLine.Insert();
    end;

    local procedure GetSalesLineNo(var TempDocSalesLine: Record "Sales Line" temporary; BufferLineNo: Integer): Integer
    begin
        TempDocSalesLine.SetRange("Shipment Line No.", BufferLineNo);
        if not TempDocSalesLine.FindFirst() then
            exit(0);
        exit(TempDocSalesLine."Line No.");
    end;

    local procedure GetSalesDocNo(var TempDocSalesLine: Record "Sales Line" temporary; BufferLineNo: Integer): Code[20]
    begin
        TempDocSalesLine.SetRange("Shipment Line No.", BufferLineNo);
        if not TempDocSalesLine.FindFirst() then
            exit('');
        exit(TempDocSalesLine."Document No.");
    end;

    local procedure AddPurchDocLine(var TempDocPurchaseLine: Record "Purchase Line" temporary; BufferLineNo: Integer; DocumentNo: Code[20]; DocumentLineNo: Integer)
    begin
        OnBeforeAddPurchDocLine(TempDocPurchaseLine, BufferLineNo, DocumentNo, DocumentLineNo);

        TempDocPurchaseLine."Document No." := DocumentNo;
        TempDocPurchaseLine."Line No." := DocumentLineNo;
        TempDocPurchaseLine."Receipt Line No." := BufferLineNo;
        TempDocPurchaseLine.Insert();
    end;

    local procedure GetPurchLineNo(var TempDocPurchaseLine: Record "Purchase Line" temporary; BufferLineNo: Integer): Integer
    begin
        TempDocPurchaseLine.SetRange("Receipt Line No.", BufferLineNo);
        if not TempDocPurchaseLine.FindFirst() then
            exit(0);
        exit(TempDocPurchaseLine."Line No.");
    end;

    local procedure GetPurchDocNo(var TempDocPurchaseLine: Record "Purchase Line" temporary; BufferLineNo: Integer): Code[20]
    begin
        TempDocPurchaseLine.SetRange("Receipt Line No.", BufferLineNo);
        if not TempDocPurchaseLine.FindFirst() then
            exit('');
        exit(TempDocPurchaseLine."Document No.");
    end;

    local procedure SetTrackingOnAssemblyReservation(AssemblyHeader: Record "Assembly Header"; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        QtyToAddAsBlank: Decimal;
    begin
        TempItemLedgerEntry.SetFilter("Lot No.", '<>%1', '');
        if TempItemLedgerEntry.IsEmpty() then
            exit;

        ReservationEntry.SetRange("Source Type", DATABASE::"Assembly Header");
        ReservationEntry.SetRange("Source Subtype", AssemblyHeader."Document Type");
        ReservationEntry.SetRange("Source ID", AssemblyHeader."No.");
        ReservationEntry.SetRange("Source Ref. No.", 0);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        if ReservationEntry.FindSet() then
            repeat
                TempReservationEntry := ReservationEntry;
                TempReservationEntry.Insert();
            until ReservationEntry.Next() = 0;

        if TempItemLedgerEntry.FindSet() then
            repeat
                TempTrackingSpecification."Entry No." += 1;
                TempTrackingSpecification."Item No." := TempItemLedgerEntry."Item No.";
                TempTrackingSpecification."Location Code" := TempItemLedgerEntry."Location Code";
                TempTrackingSpecification."Quantity (Base)" := TempItemLedgerEntry.Quantity;
                TempTrackingSpecification.CopyTrackingFromItemledgEntry(TempItemLedgerEntry);
                TempTrackingSpecification."Warranty Date" := TempItemLedgerEntry."Warranty Date";
                TempTrackingSpecification."Expiration Date" := TempItemLedgerEntry."Expiration Date";
                OnSetTrackingOnAssemblyReservationOnBeforeTempTrackingSpecificationInsert(TempTrackingSpecification, TempItemLedgerEntry);
                TempTrackingSpecification.Insert();
            until TempItemLedgerEntry.Next() = 0;

        if TempTrackingSpecification.FindSet() then
            repeat
                if GetItemTrackingCode(ItemTrackingCode, TempTrackingSpecification."Item No.") then
                    ReservationEngineMgt.AddItemTrackingToTempRecSet(
                        TempReservationEntry, TempTrackingSpecification, TempTrackingSpecification."Quantity (Base)",
                        QtyToAddAsBlank, ItemTrackingCode);
            until TempTrackingSpecification.Next() = 0;
    end;

    local procedure GetItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; ItemNo: Code[20]): Boolean
    begin
        if not Item.Get(ItemNo) then
            exit(false);

        if Item."Item Tracking Code" = '' then
            exit(false);

        ItemTrackingCode.Get(Item."Item Tracking Code");
        exit(true);
    end;

    local procedure CheckSalesVATBusPostingGroup(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line")
    var
        CheckVATBusGroup: Boolean;
    begin
        CheckVATBusGroup := (not RecalculateLines) and (ToSalesLine."No." <> '');
        OnCopySalesLineOnBeforeCheckVATBusGroup(ToSalesLine, CheckVATBusGroup);
        if CheckVATBusGroup then
            ToSalesLine.TestField("VAT Bus. Posting Group", ToSalesHeader."VAT Bus. Posting Group");
    end;

    local procedure CheckPurchVATBusPostingGroup(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line")
    var
        CheckVATBusGroup: Boolean;
    begin
        CheckVATBusGroup := (not RecalculateLines) and (ToPurchLine."No." <> '');
        OnCopyPurchLineOnBeforeCheckVATBusGroup(ToPurchLine, CheckVATBusGroup);
        if CheckVATBusGroup then
            ToPurchLine.TestField("VAT Bus. Posting Group", ToPurchHeader."VAT Bus. Posting Group");
    end;

    procedure SetPropertiesForCorrectiveCreditMemo(NewSkipCopyFromDescription: Boolean)
    begin
        SetProperties(true, false, false, false, true, true, false);
        SkipOldInvoiceDesc := NewSkipCopyFromDescription;
    end;

    local procedure SkipOldInvoiceDescription(RcptOrShipLineExist: Boolean)
    begin
        if SkipOldInvoiceDesc and RcptOrShipLineExist then
            SkipCopyFromDescription := true;
    end;

    procedure SetCopyExtendedText(CopyExtendedText: Boolean)
    begin
        CopyExtText := CopyExtendedText;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddPurchDocLine(var TempDocPurchaseLine: Record "Purchase Line" temporary; BufferLineNo: Integer; DocumentNo: Code[20]; DocumentLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddSalesDocLine(var TempDocSalesLine: Record "Sales Line" temporary; BufferLineNo: Integer; DocumentNo: Code[20]; DocumentLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyAsmOrderToAsmOrderProcedure(var TempFromAsmHeader: Record "Assembly Header" temporary; var TempFromAsmLine: Record "Assembly Line" temporary; ToSalesLine: Record "Sales Line"; ToAsmHeaderDocType: Option; ToAsmHeaderDocNo: Code[20]; InclAsmHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchLines(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchInvLines(var TempDocPurchaseLine: Record "Purchase Line" temporary; var ToPurchHeader: Record "Purchase Header"; var FromPurchInvLine: Record "Purch. Inv. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchCrMemoLinesToDoc(var TempDocPurchaseLine: Record "Purchase Line" temporary; var ToPurchHeader: Record "Purchase Header"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchaseLinesToDoc(FromDocType: Option; var ToPurchaseHeader: Record "Purchase Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line"; var FromPurchInvLine: Record "Purch. Inv. Line"; var FromReturnShipmentLine: Record "Return Shipment Line"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchReturnShptLinesToDoc(var TempDocPurchaseLine: Record "Purchase Line" temporary; var ToPurchHeader: Record "Purchase Header"; var FromReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchaseJobFields(var ToPurchaseLine: Record "Purchase Line"; FromPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchLineExtText(ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; FromPurchHeader: Record "Purchase Header"; FromPurchLine: Record "Purchase Line"; DocLineNo: Integer; var NextLineNo: Integer; var IsHandled: Boolean; RecalculateLines: Boolean; CopyExtText: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesShptLinesToDoc(var TempDocSalesLine: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; var FromSalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesShptLinesToBuffer(var FromSalesLine: Record "Sales Line"; var FromSalesShptLine: Record "Sales Shipment Line"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleZeroAmountPostedInvoices(var FromSalesInvoiceHeader: Record "Sales Invoice Header"; var ToSalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From"; FromDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnCopySalesShptLinesToDocOnAfterSplitPstdSalesLinesPerILE(var FromSalesLineBuf: Record "Sales Line" temporary; var FromSalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchSalesLineOnAfterIncrementNextLineNo(var ToSalesLine: Record "Sales Line"; var FromSalesLineArchive: Record "Sales Line Archive"; var NextLineNo: Integer; ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchPurchLineOnAfterRecalculatePurchLine(var ToPurchaseLine: Record "Purchase Line"; var FromPurchaseLineArchive: Record "Purchase Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchRcptLinesToDocOnBeforeCheckInsertDocNoLine(var ToPurchaseHeader: Record "Purchase Header"; FromPurchRcptLine: Record "Purch. Rcpt. Line"; FromPurchaseHeader: Record "Purchase Header"; var NextLineNo: Integer; var InsertDocNoLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchInvLinesToDocOnAfterCalcShouldInsertOldPurchDocNoLine(var ToPurchaseHeader: Record "Purchase Header"; FromPurchInvHeader: Record "Purch. Inv. Header"; FromPurchaseHeader: Record "Purchase Header"; var NextLineNo: Integer; var OldInvDocNo: Code[20]; var OldRcptDocNo: Code[20]; var ShouldInsertOldPurchDocNoLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesInvLines(var TempDocSalesLine: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; var FromSalesInvLine: Record "Sales Invoice Line"; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesInvLinesToDoc(var ToSalesHeader: Record "Sales Header"; var FromSalesInvLine: Record "Sales Invoice Line"; var CopyJobData: Boolean; RecalculateLines: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitJobFieldsForSalesLine(var ToSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesInvLinesToBuffer(var FromSalesLine: Record "Sales Line"; var FromSalesInvLine: Record "Sales Invoice Line"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesCrMemoLinesToDoc(var TempDocSalesLine: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesCrMemoLinesToBuffer(var FromSalesLine: Record "Sales Line"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesReturnRcptLinesToDoc(var TempDocSalesLine: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; var FromReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesReturnRcptLinesToBuffer(var FromSalesLine: Record "Sales Line"; var FromReturnReceiptLine: Record "Return Receipt Line"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesToPurchDoc(var ToPurchLine: Record "Purchase Line"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesLinesToDoc(FromDocType: Option; var ToSalesHeader: Record "Sales Header"; var FromSalesShipmentLine: Record "Sales Shipment Line"; var FromSalesInvoiceLine: Record "Sales Invoice Line"; var FromReturnReceiptLine: Record "Return Receipt Line"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesJobFields(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesLineExtText(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; DocLineNo: Integer; var NextLineNo: Integer; var IsHandled: Boolean; RecalculateLines: Boolean; CopyExtText: Boolean; var TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesDocForInvoiceCancelling(var ToSalesHeader: Record "Sales Header"; FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesDocForCrMemoCancelling(var ToSalesHeader: Record "Sales Header"; FromDocNo: Code[20]; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchaseDocForInvoiceCancelling(var ToPurchaseHeader: Record "Purchase Header"; FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchaseDocForCrMemoCancelling(var ToPurchaseHeader: Record "Purchase Header"; FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchHeaderFromPurchHeader(FromDocType: Enum "Purchase Document Type From"; FromPurchHeader: Record "Purchase Header";
                                                                            OldPurchHeader: Record "Purchase Header"; var ToPurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteNegSalesLines(FromDocType: Option; FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJobPlanningLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var JobContractEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsEntityBlocked(TableNo: Integer; CreditDocType: Boolean; Type: Option; EntityNo: Code[20]; var EntityIsBlocked: Boolean; var IsHandled: Boolean; EntityCode: Code[10]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsDeferralToBeCopied(DeferralDocType: Enum "Deferral Document Type"; ToDocType: Option;
                                                                      FromDocType: Option; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsDeferralToBeDefaulted(DeferralDocType: Enum "Deferral Document Type"; ToDocType: Option;
                                                                         FromDocType: Option; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetShipmentDateInLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitPstdSalesLinesPerILE(ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; var TempSalesLineBuf: Record "Sales Line" temporary; FromShptOrRcpt: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransfldsFromSalesToPurchLine(var FromSalesLine: Record "Sales Line"; var ToPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromSalesDocType: Option; var CopyPostedDeferral: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchHeader(var ToPurchHeader: Record "Purchase Header"; FromDocType: Option; FromDocNo: Code[20]; IncludeHeader: Boolean; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer; RecalculateLines: Boolean; FromPurchaseHeader: Record "Purchase Header"; FromPurchInvHeader: Record "Purch. Inv. Header"; FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; OldPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var CopyThisLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromPurchDocType: Option; var CopyPostedDeferral: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchHeaderWhenCopyFromPurchHeader(var PurchaseHeader: Record "Purchase Header"; OriginalPurchaseHeader: Record "Purchase Header"; FromDocType: Enum "Purchase Document Type From"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchCreditMemoHeader(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePurchLineDiscountFields(FromPurchHeader: Record "Purchase Header"; ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var InvDiscountAmount: Decimal; var IsHandled: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromSalesHeader(SalesHeaderFrom: Record "Sales Header"; SalesHeaderTo: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromSalesShptHeader(SalesShipmentHeaderFrom: Record "Sales Shipment Header"; SalesHeaderTo: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromSalesInvHeader(SalesInvoiceHeaderFrom: Record "Sales Invoice Header"; SalesHeaderTo: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromSalesCrMemoHeader(SalesCrMemoHeaderFrom: Record "Sales Cr.Memo Header"; SalesHeaderTo: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromSalesReturnRcptHeader(ReturnReceiptHeaderFrom: Record "Return Receipt Header"; SalesHeaderTo: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromPurchaseHeader(PurchaseHeaderFrom: Record "Purchase Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromPurchaseRcptHeader(PurchRcptHeaderFrom: Record "Purch. Rcpt. Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromPurchaseInvHeader(PurchInvHeaderFrom: Record "Purch. Inv. Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromPurchaseCrMemoHeader(PurchCrMemoHdrFrom: Record "Purch. Cr. Memo Hdr."; PurchaseHeaderTo: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFromPurchaseReturnShptHeader(ReturnShipmentHeaderFrom: Record "Return Shipment Header"; PurchaseHeaderTo: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesDocForInvoiceCancelling(FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header"; IncludeHeader: Boolean; RecalculateLines: Boolean; MoveNegLines: Boolean; CreateToHeader: Boolean; HideDialog: Boolean; ExactCostRevMandatory: Boolean; ApplyFully: Boolean; SkipTestCreditLimit: Boolean; SkipCopyFromDescription: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesDocForCrMemoCancelling(FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header"; IncludeHeader: Boolean; RecalculateLines: Boolean; MoveNegLines: Boolean; CreateToHeader: Boolean; HideDialog: Boolean; ExactCostRevMandatory: Boolean; ApplyFully: Boolean; SkipTestCreditLimit: Boolean; SkipCopyFromDescription: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchLineExtText(ToPurchaseHeader: Record "Purchase Header"; var ToPurchaseLine: Record "Purchase Line"; FromPurchaseHeader: Record "Purchase Header"; FromPurchaseLine: Record "Purchase Line"; DocLineNo: Integer; var NextLineNo: Integer; var TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchCrMemoLinesToDoc(ToPurchaseHeader: Record "Purchase Header"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchReturnShptLinesToDoc(ToPurchaseHeader: Record "Purchase Header"; var FromReturnShipmentLine: Record "Return Shipment Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchRcptLinesToDoc(ToPurchaseHeader: Record "Purchase Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchInvLinesToDoc(ToPurchaseHeader: Record "Purchase Header"; var FromPurchInvLine: Record "Purch. Inv. Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesDocInvLine(FromSalesInvoiceHeader: Record "Sales Invoice Header"; ToSalesHeader: Record "Sales Header"; var FromSalesInvoiceLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesCrMemoLinesToDoc(var ToSalesHeader: Record "Sales Header"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesInvLinesToDoc(var ToSalesHeader: Record "Sales Header"; var FromSalesInvoiceLine: Record "Sales Invoice Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesReturnRcptLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromReturnReceiptLine: Record "Return Receipt Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesShptLinesToDoc(ToSalesHeader: Record "Sales Header"; var FromSalesShipmentLine: Record "Sales Shipment Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesDocSalesLineArchive(FromSalesHeaderArchive: Record "Sales Header Archive"; var ToSalesHeader: Record "Sales Header"; ToSalesLine: Record "Sales Line"; var TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromPurchDocAssgntToLine(var ToPurchaseLine: Record "Purchase Line"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSalesDocAssgntToLine(var ToSalesLine: Record "Sales Line"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyArchSalesLine(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesLineArchive: Record "Sales Line Archive"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyArchPurchLine(ToPurchHeader: Record "Purchase Header"; var ToPurchaseLine: Record "Purchase Line"; FromPurchaseLineArchive: Record "Purchase Line Archive"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFieldsFromOldPurchHeaderProcedure(var PurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostedReceipt(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostedShipment(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; FromSalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostedPurchInvoice(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostedReturnReceipt(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; ReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostedReturnShipment(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToSalesHeader: Record "Sales Header"; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer; IncludeHeader: Boolean; RecalculateLines: Boolean; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesHeaderArchive(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; FromSalesHeaderArchive: Record "Sales Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesHeaderDone(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; FromSalesShipmentHeader: Record "Sales Shipment Header"; FromSalesInvoiceHeader: Record "Sales Invoice Header"; FromReturnReceiptHeader: Record "Return Receipt Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; FromSalesHeaderArchive: Record "Sales Header Archive"; FromDocType: Enum "Sales Document Type From")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteSalesLinesWithNegQty(FromSalesLine: Record "Sales Line"; OnlyTest: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesHeaderDone(var ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From"; OldSalesHeader: Record "Sales Header";
                                                                                                                                                   FromSalesShipmentHeader: Record "Sales Shipment Header";
                                                                                                                                                   FromSalesInvoiceHeader: Record "Sales Invoice Header";
                                                                                                                                                   FromReturnReceiptHeader: Record "Return Receipt Header";
                                                                                                                                                   FromSalesCrMemoHeader: Record "Sales Cr.Memo Header";
                                                                                                                                                   FromSalesHeaderArchive: Record "Sales Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySalesHeaderFromPostedInvoice(var ToSalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesCrMemoLine(var TempDocSalesLine: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; var FromSalesLineBuf: Record "Sales Line"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesInvLine(var TempDocSalesLine: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; var FromSalesLineBuf: Record "Sales Line"; var FromSalesInvLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLinesToBufferFields(var TempSalesLine: Record "Sales Line" temporary; FromSalesLine: Record "Sales Line"; FromSalesLineParam: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLinesToDoc(FromDocType: Option; var ToSalesHeader: Record "Sales Header"; var FromSalesShipmentLine: Record "Sales Shipment Line"; var FromSalesInvoiceLine: Record "Sales Invoice Line"; var FromReturnReceiptLine: Record "Return Receipt Line"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean; var RecalculateLines: Boolean; var IncludeHeader: Boolean)
    begin
    end;

#if not CLEAN24
    internal procedure RunOnAfterCopyServContractLines(ToServiceContractHeader: Record "Service Contract Header"; FromDocType: Option; FromDocNo: Code[20]; var FormServiceContractLine: Record "Service Contract Line")
    begin
        OnAfterCopyServContractLines(ToServiceContractHeader, FromDocType, FromDocNo, FormServiceContractLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by event OnGetServiceContractTypeCaseElse in codeunit Copy Service Contract Mgt.', '24.0')]
    local procedure OnAfterCopyServContractLines(ToServiceContractHeader: Record "Service Contract Header"; FromDocType: Option; FromDocNo: Code[20]; var FormServiceContractLine: Record "Service Contract Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchHeaderFromPostedCreditMemo(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchaseDocument(FromDocumentType: Option; FromDocumentNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header"; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer; IncludeHeader: Boolean; RecalculateLines: Boolean; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchHeaderArchive(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchaseHeaderArchive: Record "Purchase Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchHeaderDone(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchaseHeader: Record "Purchase Header"; FromPurchRcptHeader: Record "Purch. Rcpt. Header"; FromPurchInvHeader: Record "Purch. Inv. Header"; ReturnShipmentHeader: Record "Return Shipment Header"; FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; FromPurchaseHeaderArchive: Record "Purchase Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchHeaderDone(var ToPurchaseHeader: Record "Purchase Header"; FromPurchaseHeader: Record "Purchase Header"; FromDocType: Enum "Purchase Document Type From"; OldPurchaseHeader: Record "Purchase Header";
                                                                                                                                                               FromPurchRcptHeader: Record "Purch. Rcpt. Header";
                                                                                                                                                               FromPurchInvHeader: Record "Purch. Inv. Header";
                                                                                                                                                               FromReturnShipmentHeader: Record "Return Shipment Header";
                                                                                                                                                               FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                                                                                                                                                               FromPurchaseHeaderArchive: Record "Purchase Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchInvLines(var TempDocPurchaseLine: Record "Purchase Line" temporary; var ToPurchHeader: Record "Purchase Header"; var FromPurchLineBuf: Record "Purchase Line"; var FromPurchInvLine: Record "Purch. Inv. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchInvLine(FromPurchInvLine: Record "Purch. Inv. Line"; var ToPurchaseLine: Record "Purchase Line"; ToPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchLinesToBufferFields(var TempPurchaseLine: Record "Purchase Line" temporary; FromPurchaseLine: Record "Purchase Line"; FromPurchLine: Record "Purchase Line"; ToPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchaseLinesToDoc(FromDocType: Option; var ToPurchaseHeader: Record "Purchase Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line"; var FromPurchInvLine: Record "Purch. Inv. Line"; var FromReturnShipmentLine: Record "Return Shipment Line"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean; var RecalculateLines: Boolean; var IncludeHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchCrMemoLine(FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var ToPurchaseLine: Record "Purchase Line"; ToPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchRcptLine(FromPurchRcptLine: Record "Purch. Rcpt. Line"; var ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyReturnShptLine(FromReturnShipmentLine: Record "Return Shipment Line"; var ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSalesLine(var FromSalesLine2: Record "Sales Line"; var FromSalesLineBuf: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitShipmentDateInLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleAsmAttachedToSalesLine(var ToSalesLine: Record "Sales Line");
    begin
    end;

#if not CLEAN24
    internal procedure RunOnAfterProcessServContractLine(var ToServContractLine: Record "Service Contract Line"; FromServContractLine: Record "Service Contract Line")
    begin
        OnAfterProcessServContractLine(ToServContractLine, FromServContractLine);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by event OnAfterProcessServiceContractLine in codeunit Copy Service Contract Mgt.', '24.0')]
    local procedure OnAfterProcessServContractLine(var ToServContractLine: Record "Service Contract Line"; FromServContractLine: Record "Service Contract Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessToAsmHeader(var ToAsmHeader: Record "Assembly Header"; TempFromAsmHeader: Record "Assembly Header" temporary; ToSalesLine: Record "Sales Line"; BasicAsmOrderCopy: Boolean; AvailabilityCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculatePurchLine(var PurchaseLine: Record "Purchase Line"; var ToPurchHeader: Record "Purchase Header"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultValuesToSalesLine(var ToSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header"; CreateToHeader: Boolean; RecalculateLines: Boolean; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultValuesToPurchLine(var ToPurchaseLine: Record "Purchase Line"; ToPurchHeader: Record "Purchase Header"; CreateToHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldSkipCopyFromDescription(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldsFromCrMemoToInv(var ToSalesHeader: Record "Sales Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferTempAsmHeader(var TempAssemblyHeader: Record "Assembly Header" temporary; PostedAssemblyHeader: Record "Posted Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromSalesDocType: Option; var CopyPostedDeferral: Boolean; ExactCostRevMandatory: Boolean; MoveNegLines: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchCreditMemoHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean; RecalculateAmount: Boolean; FromPurchDocType: Option; var CopyPostedDeferral: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateRevSalesLineAmount(var SalesLine: Record "Sales Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVendLedgEntry(var PurchaseHeader: Record "Purchase Header"; FromDocumentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLine(var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnAfterSetReserve(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line"; FromSalesDocType: Enum "Sales Document Type From")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchLine(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnAfterCalcShouldGetUnitCost(var Item: Record Item; var ShouldGetUnitCost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocWithHeader(FromDocType: Option; FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header"; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer; var FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPostedDeferralsOnBeforeDeferralHeaderInsert(var DeferralHeader: Record "Deferral Header"; PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPostedDeferralsOnBeforeDeferralHeaderModify(var DeferralHeader: Record "Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPostedDeferralsOnBeforeDeferralLineInsert(var DeferralLine: Record "Deferral Line"; PostedDeferralLine: Record "Posted Deferral Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocWithHeader(FromDocType: Option; FromDocNo: Code[20]; var ToPurchHeader: Record "Purchase Header"; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransfldsFromSalesToPurchLine(var FromSalesLine: Record "Sales Line"; var ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitAndCheckSalesDocuments(FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; var FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesShipmentHeader: Record "Sales Shipment Header"; var FromSalesInvoiceHeader: Record "Sales Invoice Header"; var FromReturnReceiptHeader: Record "Return Receipt Header"; var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var FromSalesHeaderArchive: Record "Sales Header Archive"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitAndCheckPurchaseDocuments(FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; var FromPurchaseHeader: Record "Purchase Header"; var ToPurchaseHeader: Record "Purchase Header"; var FromPurchRcptHeader: Record "Purch. Rcpt. Header"; var FromPurchInvHeader: Record "Purch. Inv. Header"; var FromReturnShipmentHeader: Record "Return Shipment Header"; var FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var FromPurchaseHeaderArchive: Record "Purchase Header Archive"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSalesLineFields(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPurchLineFields(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitToSalesLine(var ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSalesLineFields(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPurchLineFields(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertToSalesLine(var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line"; FromDocType: Option; RecalcLines: Boolean; var ToSalesHeader: Record "Sales Header"; DocLineNo: Integer; var NextLineNo: Integer; RecalculateAmount: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertOldSalesDocNoLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; OldDocType: Option; OldDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFromSalesInvHeader(SalesInvoiceHeaderFrom: Record "Sales Invoice Header"; SalesHeaderTo: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCopyFromSalesHeaderArchiveAvail(FromSalesHeaderArchive: Record "Sales Header Archive"; ToSalesHeader: Record "Sales Header"; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUnappliedLines(SkippedLine: Boolean; var MissingExCostRevLink: Boolean; var WarningDone: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOldSalesCombDocNoLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; CopyFromInvoice: Boolean; OldDocNo: Code[20]; OldDocNo2: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOldSalesCombDocNoLineProcedure(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; CopyFromInvoice: Boolean; OldDocNo: Code[20]; OldDocNo2: Code[20]; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitToPurchLine(var ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertToPurchLine(var ToPurchLine: Record "Purchase Line"; FromPurchLine: Record "Purchase Line"; FromDocType: Option; RecalcLines: Boolean; var ToPurchHeader: Record "Purchase Header"; DocLineNo: Integer; var NexLineNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertOldPurchDocNoLine(ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; OldDocType: Option; OldDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOldPurchCombDocNoLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; CopyFromInvoice: Boolean; OldDocNo: Code[20]; OldDocNo2: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPurchDoc(var ToPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSalesDoc(var ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustLedgEntry(var ToSalesHeader: Record "Sales Header"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean; FromDocType: Enum "Gen. Journal Document Type"; FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVendLedgEntry(var ToPurchaseHeader: Record "Purchase Header"; VendorLedgerEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertToSalesLine(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line"; RecalculateLines: Boolean; DocLineNo: Integer; FromSalesDocType: Enum "Sales Document Type From"; FromSalesHeader: Record "Sales Header"; var NextLineNo: Integer; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesToPurchDoc(var ToPurchLine: Record "Purchase Line"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertToPurchLine(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line"; RecalculateLines: Boolean; DocLineNo: Integer; FromPurchDocType: Enum "Purchase Document Type From"; var ToPurchHeader: Record "Purchase Header"; MoveNegLines: Boolean; FromPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesHeader(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCleanSpecialOrderDropShipmentInSalesLine(var SalesLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchaseHeader(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLineFromSalesDocSalesLine(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line"; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLineFromSalesLineBuffer(var ToSalesLine: Record "Sales Line"; FromSalesInvLine: Record "Sales Invoice Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line" temporary; ToSalesHeader: Record "Sales Header"; var FromSalesLineBuf: Record "Sales Line"; var FromSalesLine2: Record "Sales Line"; FromSalesLine: Record "Sales Line"; ExactCostRevMandatory: Boolean; FromSalesInvHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLineFromSalesCrMemoLineBuffer(var ToSalesLine: Record "Sales Line"; FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line" temporary; ToSalesHeader: Record "Sales Header"; FromSalesLineBuf: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLineFromSalesShptLineBuffer(var ToSalesLine: Record "Sales Line"; FromSalesShipmentLine: Record "Sales Shipment Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line" temporary; ToSalesHeader: Record "Sales Header"; FromSalesLineBuf: Record "Sales Line"; ExactCostRevMandatory: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLineFromReturnRcptLineBuffer(var ToSalesLine: Record "Sales Line"; FromReturnReceiptLine: Record "Return Receipt Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line" temporary; ToSalesHeader: Record "Sales Header"; FromSalesLineBuf: Record "Sales Line"; CopyItemTrkg: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchLineFromPurchLineBuffer(var ToPurchLine: Record "Purchase Line"; FromPurchInvLine: Record "Purch. Inv. Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocPurchaseLine: Record "Purchase Line" temporary; ToPurchHeader: Record "Purchase Header"; FromPurchLineBuf: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchLineFromPurchCrMemoLineBuffer(var ToPurchaseLine: Record "Purchase Line"; FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocPurchLine: Record "Purchase Line" temporary; ToPurchHeader: Record "Purchase Header"; FromPurchLineBuf: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchLineFromPurchRcptLineBuffer(var ToPurchaseLine: Record "Purchase Line"; FromPurchRcptLine: Record "Purch. Rcpt. Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocPurchLine: Record "Purchase Line" temporary; ToPurchHeader: Record "Purchase Header"; FromPurchLineBuf: Record "Purchase Line"; CopyItemTrkg: Boolean; NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchLineFromReturnShptLineBuffer(var ToPurchaseLine: Record "Purchase Line"; FromReturnShipmentLine: Record "Return Shipment Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocPurchLine: Record "Purchase Line" temporary; ToPurchHeader: Record "Purchase Header"; FromPurchLineBuf: Record "Purchase Line"; CopyItemTrkg: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFieldsFromOldSalesHeader(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; MoveNegLines: Boolean; IncludeHeader: Boolean; FromDocType: Enum "Sales Document Type From"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFieldsFromOldPurchHeader(var ToPurchHeader: Record "Purchase Header"; OldPurchHeader: Record "Purchase Header"; MoveNegLines: Boolean; IncludeHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSalesToPurchDoc(FromSalesHeader: Record "Sales Header"; var ToPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateRevPurchLineAmount(var PurchaseLine: Record "Purchase Line"; OrgQtyBase: Decimal; FromPricesInclVAT: Boolean; ToPricesInclVAT: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcReversibleQtyBaseSalesDoc(FromSalesLine: Record "Sales Line"; var ItemLedgEntry: record "Item Ledger Entry"; var ReversibleQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFromSalesHeader(SalesHeaderFrom: Record "Sales Header"; SalesHeaderTo: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUpdateOldDocumentNoFromSalesShptLine(FromSalesShptLine: Record "Sales Shipment Line"; var OldDocNo: Code[20]; var InsertDocNoLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUpdateOldDocumentNoFromPurchRcptLine(FromPurchRcptLine: Record "Purch. Rcpt. Line"; var OldDocNo: Code[20]; var InsertDocNoLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUpdateOldDocumentNoFromReturnRcptLine(FromReturnRcptLine: Record "Return Receipt Line"; var OldDocNo: Code[20]; var InsertDocNoLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUpdateOldDocumentNoFromReturnShptLine(FromReturnShptLine: Record "Return Shipment Line"; var OldDocNo: Code[20]; var InsertDocNoLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearPurchaseBlanketOrderFields(var ToPurchaseLine: Record "Purchase Line"; ToPurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearPurchLastNoSFields(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearInvoiceAndShip(var ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearSalesBlanketOrderFields(var ToSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCreditLimit(var FromSalesHeader: Record "Sales Header"; var ToSalesHeader: record "Sales Header"; var SkipTestCreditLimit: Boolean; var IsHandled: Boolean; IncludeHeader: Boolean; HideDialog: Boolean; FromDocType: Enum "Sales Document Type From")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsCopyItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; var CopyItemTrkg: Boolean; var FillExactCostRevLink: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitAndCheckSalesDocuments(FromDocType: enum "Sales Document Type From"; FromDocNo: Code[20];
                                                                        FromDocOccurrenceNo: Integer;
                                                                        FromDocVersionNo: Integer; var FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; MoveNegLines: boolean; IncludeHeader: Boolean; RecalculateLines: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsPurchFillExactCostRevLink(ToPurchHeader: Record "Purchase Header"; FromDocType: Option "Purchase Receipt","Purchase Invoice","Purchase Return Shipment","Purchase Credit Memo"; CurrencyCode: Code[10]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsSalesFillExactCostRevLink(ToSalesHeader: Record "Sales Header"; FromDocType: Option "Sales Shipment","Sales Invoice","Sales Return Receipt","Sales Credit Memo"; CurrencyCode: Code[10]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculatePurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateSalesLineAmounts(FromSalesLine: Record "Sales Line"; var ToSalesLine: Record "Sales Line"; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateAndApplySalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line"; Currency: Record Currency; var ExactCostRevMandatory: Boolean; var RecalculateAmount: Boolean; var CreateToHeader: Boolean; MoveNegLines: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateAndApplyPurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line"; Currency: Record Currency; var ExactCostRevMandatory: Boolean; var RecalculateAmount: Boolean; var CreateToHeader: Boolean; MoveNegLines: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLineQtyBaseFromReversibleQtyBase(var FromSalesLine: Record "Sales Line"; var SalesLineBuffer: record "Sales Line"; ReversibleQtyBase: decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesHeaderWhenCopyFromSalesHeader(var SalesHeader: Record "Sales Header"; OriginalSalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesHeaderAvailOnAfterCheckItemAvailability(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header"; IncludeHeader: Boolean; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesHeaderAvailOnAfterSetFilters(var FromSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesHeaderArchiveAvailOnAfterCheckItemAvailability(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesHeaderArchive: Record "Sales Header Archive"; FromSalesLineArchive: Record "Sales Line Archive"; IncludeHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesHeaderArchiveAvailOnAfterSetFilters(var FromSalesLineArchive: Record "Sales Line Archive"; FromSalesHeaderArchive: Record "Sales Header Archive"; ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesRetRcptAvailOnAfterCheckItemAvailability(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromReturnReceiptHeader: Record "Return Receipt Header"; IncludeHeader: Boolean; FromReturnRcptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesRetRcptAvailOnAfterSetFilters(var FromReturnReceiptLine: Record "Return Receipt Line"; FromReturnReceiptHeader: Record "Return Receipt Header"; ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesCrMemoAvailOnAfterCheckItemAvailability(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; IncludeHeader: Boolean; FromSalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesCrMemoAvailOnAfterSetFilters(var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesCrMemoAvailOnBeforeCheckItemAvailability(var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesInvoiceAvailOnAfterCheckItemAvailability(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesInvoiceHeader: Record "Sales Invoice Header"; IncludeHeader: Boolean; FromSalesInvLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesInvoiceAvailOnAfterSetFilters(var FromSalesInvoiceLine: Record "Sales Invoice Line"; FromSalesInvoiceHeader: Record "Sales Invoice Header"; ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesShptAvailOnAfterCheckItemAvailability(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesShipmentHeader: Record "Sales Shipment Header"; IncludeHeader: Boolean; FromSalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCopyFromSalesShptAvailOnAfterSetFilters(var FromSalesShipmentLine: Record "Sales Shipment Line"; FromSalesShipmentHeader: Record "Sales Shipment Header"; ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemAvailabilityOnBeforeRunSalesLineCheck(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchSalesLineOnAfterToSalesLineInsert(var ToSalesLine: Record "Sales Line"; FromSalesLineArchive: Record "Sales Line Archive"; RecalculateLines: Boolean; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchSalesLineOnBeforeToSalesLineInsert(var ToSalesLine: Record "Sales Line"; FromSalesLineArchive: Record "Sales Line Archive"; RecalculateLines: Boolean; var NextLineNo: Integer; var TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines"; ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchPurchLineOnAfterToPurchLineInsert(var ToPurchLine: Record "Purchase Line"; FromPurchLineArchive: Record "Purchase Line Archive"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchPurchLineOnBeforeToPurchLineInsert(var ToPurchLine: Record "Purchase Line"; FromPurchLineArchive: Record "Purchase Line Archive"; RecalculateLines: Boolean; var NextLineNo: Integer; var TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromPurchDocAssgntToLineOnAfterSetFilters(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromPurchDocAssgntToLineOnBeforeInsert(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; RecalculateLines: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesDocAssgntToLineOnAfterSetFilters(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesDocAssgntToLineOnBeforeInsert(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; RecalculateLines: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesToPurchDocOnAfterCalcShouldCopyItemTracking(ToPurchLine: Record "Purchase Line"; var ShouldCopyItemTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesToPurchDocOnAfterSetFilters(var FromSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesToPurchDocOnBeforeToPurchHeaderModify(var ToPurchHeader: Record "Purchase Header"; FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesToPurchDocOnBeforePurchaseHeaderInsert(var ToPurchaseHeader: Record "Purchase Header"; FromSalesHeader: Record "Sales Header"; VendorNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchLineOnBeforeCheckVATBusGroup(PurchaseLine: Record "Purchase Line"; var CheckVATBusGroup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailability(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var HideDialog: Boolean; var IsHandled: Boolean; RecalculateLines: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCopyFromSalesInvoiceAvail(var FromSalesInvHeader: Record "Sales Invoice Header"; var ToSalesHeader: Record "Sales Header"; var FromSalesInvLine: Record "Sales Invoice Line"; var ToSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchSalesLineOnAfterValidateQuantityMoveNegLines(var ToSalesLine: Record "Sales Line"; FromSalesLineArchive: Record "Sales Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchSalesLineOnBeforeCleanSpecialOrderDropShipmentInSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; CreateToHeader: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchPurchLineOnAfterValidateQuantityMoveNegLines(var ToPurchLine: Record "Purchase Line"; FromPurchLineArchive: Record "Purchase Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchPurchLineOnBeforeCleanSpecialOrderDropShipmentInPurchLine(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; CreateToHeader: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchCrMemoLinesToDocOnAfterTransferFields(var FromPurchaseLine: Record "Purchase Line"; var FromPurchaseHeader: Record "Purchase Header"; var ToPurchaseHeader: Record "Purchase Header"; var FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchCrMemoLinesToDocOnAfterFromPurchCrMemoLineLoop(var TempDocPurchaseLine: Record "Purchase Line" temporary; var ToPurchHeader: Record "Purchase Header"; var FromPurchLineBuf: Record "Purchase Line"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; SplitLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteSalesLinesWithNegQty(FromSalesHeader: Record "Sales Header"; OnlyTest: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchInvLinesToDocOnAfterTransferFields(var FromPurchaseLine: Record "Purchase Line"; var FromPurchaseHeader: Record "Purchase Header"; var ToPurchaseHeader: Record "Purchase Header"; FromPurchInvHeader: Record "Purch. Inv. Header"; var FromPurchInvLine: Record "Purch. Inv. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchRcptLinesToDocOnAfterTransferFields(var FromPurchaseLine: Record "Purchase Line"; var FromPurchaseHeader: Record "Purchase Header"; var ToPurchaseHeader: Record "Purchase Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchReturnShptLinesToDocOnAfterTransferFields(var FromPurchaseLine: Record "Purchase Line"; var FromPurchaseHeader: Record "Purchase Header"; var ToPurchaseHeader: Record "Purchase Header"; var FromReturnShipmentHeader: Record "Return Shipment Header"; var FromReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnAfterCopyPurchDocLines(FromDocType: Option; FromDocNo: Code[20]; FromPurchaseHeader: Record "Purchase Header"; IncludeHeader: Boolean; var ToPurchHeader: Record "Purchase Header"; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeCopyPurchDocRcptLine(var FromPurchRcptHeader: Record "Purch. Rcpt. Header"; var ToPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeCopyPurchDocInvLine(var FromPurchInvHeader: Record "Purch. Inv. Header"; var ToPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeCopyPurchDocReturnShptLine(var FromReturnShipmentHeader: Record "Return Shipment Header"; var ToPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeCopyPurchDocCrMemoLine(var FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ToPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeToPurchHeaderInsert(var ToPurchaseHeader: Record "Purchase Header"; FromPurchaseHeader: Record "Purchase Header"; MovNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeUpdatePurchInvoiceDiscountValue(var ToPurchaseHeader: Record "Purchase Header"; FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; RecalculateLines: Boolean; FromPurchHeader: Record "Purchase Header"; LinesNotCopied: Integer; NextLineNo: Integer; MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocUpdateHeaderOnBeforeUpdateVendLedgerEntry(var ToPurchaseHeader: Record "Purchase Header"; FromDocType: Option; FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocWithoutHeader(var ToPurchaseHeader: Record "Purchase Header"; FromDocType: Option; FromDocNo: Code[20]; FromOccurenceNo: Integer; FromVersionNo: Integer; FromPurchInvHeader: Record "Purch. Inv. Header"; FromPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCopySalesDocOnBeforeCopyLines(FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean; FromDocType: Enum "Sales Document Type From")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnAfterCopySalesDocLines(FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; FromSalesHeader: Record "Sales Header"; IncludeHeader: Boolean; var ToSalesHeader: Record "Sales Header"; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeCopySalesDocShptLine(var FromSalesShipmentHeader: Record "Sales Shipment Header"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeCopySalesDocInvLine(var FromSalesInvoiceHeader: Record "Sales Invoice Header"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeCopySalesDocCrMemoLine(var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeCopySalesDocReturnRcptLine(var FromReturnReceiptHeader: Record "Return Receipt Header"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeToSalesHeaderInsert(var ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header"; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeToSalesLineDeleteAll(ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeTransferPostedShipmentFields(var ToSalesHeader: Record "Sales Header"; SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFieldsFromCrMemoToInv(var ToSalesHeader: Record "Sales Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnAfterTransferPostedInvoiceFields(var ToSalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header"; OldSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnAfterTransferArchSalesHeaderFields(var ToSalesHeader: Record "Sales Header"; FromSalesHeaderArchive: Record "Sales Header Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeTransferPostedInvoiceFields(var ToSalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header"; var CopyJobData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeTransferPostedReturnReceiptFields(var ToSalesHeader: Record "Sales Header"; ReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeUpdateSalesInvoiceDiscountValue(var ToSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20]; FromDocOccurrenceNo: Integer; FromDocVersionNo: Integer; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocInvLineOnAfterSetFilters(var ToSalesHeader: Record "Sales Header"; var FromSalesInvoiceHeader: Record "Sales Invoice Header"; var FromSalesInvoiceLine: Record "Sales Invoice Line"; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocCrMemoLineOnAfterSetFilters(var ToSalesHeader: Record "Sales Header"; var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line"; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocShptLineOnAfterSetFilters(var ToSalesHeader: Record "Sales Header"; var FromSalesShipmentHeader: Record "Sales Shipment Header"; var FromSalesShipmentLine: Record "Sales Shipment Line"; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocRcptLineOnAfterSetFilters(var ToPurchHeader: Record "Purchase Header"; var FromPurchRcptHeader: Record "Purch. Rcpt. Header"; var FromPurchRcptLine: Record "Purch. Rcpt. Line"; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocInvLineOnAfterSetFilters(var ToPurchHeader: Record "Purchase Header"; var FromPurchInvLine: Record "Purch. Inv. Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocCrMemoLineOnAfterSetFilters(var ToPurchHeader: Record "Purchase Header"; var FromPurchCrMemoLine: Record "Purch. Cr. Memo Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocReturnShptLineOnAfterSetFilters(var ToPurchHeader: Record "Purchase Header"; var FromReturnShptLine: Record "Return Shipment Line"; var LinesNotCopied: Integer; var MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocPurchLineArchiveOnAfterSetFilters(var ToPurchHeader: Record "Purchase Header"; ToPurchLine: Record "Purchase Line"; FromPurchHeaderArchive: Record "Purchase Header Archive"; var FromPurchLineArchive: Record "Purchase Line Archive"; var NextLineNo: Integer; var LinesNotCopied: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocReturnRcptLineOnAfterSetFilters(var ToSalesHeader: Record "Sales Header"; var FromReturnReceiptHeader: Record "Return Receipt Header"; var FromReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocSalesLineOnAfterSetFilters(FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var ToSalesHeader: Record "Sales Header"; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocSalesLineOnAfterCalcShouldRunIteration(FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; var ShouldRunIteration: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocPurchLineOnAfterSetFilters(FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var ToPurchHeader: Record "Purchase Header"; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocPurchLineOnAfterCopyPurchLine(ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; IncludeHeader: Boolean; RecalculateLines: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocSalesLineArchiveOnAfterSetFilters(FromSalesHeaderArchive: Record "Sales Header Archive"; var FromSalesLineArchive: Record "Sales Line Archive"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocUpdateHeaderOnBeforeUpdateCustLedgerEntry(var ToSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20]; OldSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocUpdateHeaderOnBeforeValidateLocationCode(var ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocUpdateHeaderOnAfterSetStatusOpen(var ToSalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; var ShouldValidateDimensionsAndLocation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocWithoutHeader(var ToSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20]; FromOccurenceNo: Integer; FromVersionNo: Integer; FromSalesInvoiceHeader: Record "Sales Invoice Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnAfterCopySalesDocUpdateHeader(var ToSalesHeader: Record "Sales Header"; var FromSalesInvHeader: Record "Sales Invoice Header"; FromDocType: Enum "Sales Document Type From")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesLineOnAfterTransferFieldsToSalesLine(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesReturnRcptLinesToDocOnAfterFromSalesHeaderTransferFields(FromReturnRcptHeader: Record "Return Receipt Header"; var FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesReturnRcptLinesToDocOnBeforeFromSalesHeaderTransferFields(FromReturnRcptHeader: Record "Return Receipt Header"; var FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header"; var FromReturnRcptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesReturnRcptLinesToDocOnBeforeCopySalesDocLine(ToSalesHeader: Record "Sales Header"; var FromSalesLineBuf: Record "Sales Line"; var CoptItemTrkg: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesReturnRcptLinesToDocOnAfterCalcNextLineNo(var ToSalesHeader: Record "Sales Header"; FromReturnRcptLine: Record "Return Receipt Line"; FromSalesHeader: Record "Sales Header"; var NextLineNo: Integer; var InsertDocNoLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesReturnRcptLinesToDocOnAfterCopySalesDocLine(FromReturnRcptLine: Record "Return Receipt Line"; ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchRcptLinesToDocOnBeforeCopyPurchLine(ToPurchaseHeader: Record "Purchase Header"; var FromPurchaseLine: Record "Purchase Line"; var CopyItemTrkg: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchInvLinesToDocOnBeforeCopyPurchLine(ToPurchaseHeader: Record "Purchase Header"; var FromPurchaseLine: Record "Purchase Line"; FromPurchaseLineBuf: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchCrMemoLinesToDocOnBeforeCopyPurchLine(ToPurchaseHeader: Record "Purchase Header"; var FromPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchReturnShptLinesToDocOnBeforeCopyPurchLine(ToPurchaseHeader: Record "Purchase Header"; var FromPurchaseLine: Record "Purchase Line"; var CopyItemTrkg: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchReturnShptLinesToDocOnAfterCalcNextLineNo(var ToPurchaseHeader: Record "Purchase Header"; FromReturnShptLine: Record "Return Shipment Line"; FromPurchHeader: Record "Purchase Header"; var NextLineNo: Integer; var InsertDocNoLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesShptLinesToDocOnAfterFromSalesHeaderTransferFields(FromSalesShptHeader: Record "Sales Shipment Header"; var FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesShptLinesToDocOnBeforeFromSalesHeaderTransferFields(FromSalesShipmentHeader: Record "Sales Shipment Header"; var FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header"; var FromSalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesShptLinesToDocOnBeforeCopySalesLine(var ToSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; FromSalesShptLine: record "Sales Shipment Line"; var CopyItemTrkg: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesShptLinesToDocOnAfterCalcNextLineNo(var ToSalesHeader: Record "Sales Header"; FromSalesShptLine: Record "Sales Shipment Line"; FromSalesHeader: Record "Sales Header"; var NextLineNo: Integer; var InsertDocNoLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesShptLinesToDocOnBeforeSplitPstdSalesLinesPerILE(var ItemLedgEntry: record "Item Ledger Entry"; FromSalesShptLine: record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesShptLinesToDocOnAfterCopySalesShptLineToSalesLine(FromSalesShptLine: Record "Sales Shipment Line"; ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnAfterCalcShouldInsertOldSalesDocNoLine(var TempSalesLineBuf: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; var ShouldInsertOldSalesDocNoLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnBeforeCopySalesLine(ToSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var TempSalesLineBuf: Record "Sales Line" temporary; var ToSalesLine: Record "Sales Line"; FromSalesInvLine: Record "Sales Invoice Line"; IncludeHeader: Boolean; RecalculateLines: Boolean; var TempDocSalesLine: Record "Sales Line" temporary; var FromSalesLine1: Record "Sales Line"; ExactCostRevMandatory: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnBeforeFromSalesHeaderTransferFields(var FromSalesHeader: Record "Sales Header"; FromSalesInvoiceHeader: Record "Sales Invoice Header"; ToSalesHeader: Record "Sales Header"; var FromSalesInvoiceLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnAfterCheckFirstLineShipped(ToSalesHeader: Record "Sales Header"; OldDocType: Integer; ShptDocNo: Code[20]; var OldShptDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnAfterGetFromSalesInvHeader(var ToSalesHeader: Record "Sales Header"; FromSalesInvHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnAfterInsertOldSalesDocNoLine(ToSalesHeader: Record "Sales Header"; var SkipCopyFromDescription: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnBeforeInsertOldSalesDocNoLine(ToSalesHeader: Record "Sales Header"; var SkipCopyFromDescription: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnAfterFromSalesHeaderTransferFields(var FromSalesHeader: Record "Sales Header"; FromSalesInvHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesCrMemoLinesToDocOnAfterFromSalesHeaderTransferFields(FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesCrMemoLinesToDocOnBeforeFromSalesHeaderTransferFields(FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesCrMemoLinesToDocOnBeforeCopySalesLine(ToSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; FromSalesLineBuf: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesCrMemoLinesToDocOnAfterCalcShouldCopyItemTracking(ToSalesHeader: Record "Sales Header"; var ShouldCopyItemTracking: Boolean; var ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesLineOnBeforeCheckVATBusGroup(SalesLine: Record "Sales Line"; var CheckVATBusGroup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesLinesToBufferTransferFields(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempSalesLineBuf: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesLineOnAfterSetDimensions(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchLineOnAfterSetDimensions(var ToPurchaseLine: Record "Purchase Line"; FromPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchaseDocumentTypeCaseElse(FromDocType: Enum "Purchase Document Type From"; var ToDocType: Enum "Purchase Document Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesDocumentTypeCaseElse(FromDocType: Enum "Sales Document Type From"; var ToDocType: Enum "Sales Document Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesLinesWithNegQtyOnAfterSetFilters(var FromSalesLine: Record "Sales Line"; OnlyTest: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsSplitItemLedgEntryOnAfterItemLedgEntrySetFilters(var ItemLedgEntry: Record "Item Ledger Entry"; OrgItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitPstdSalesLinesPerILETransferFields(var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var TempSalesLineBuf: Record "Sales Line" temporary; var ToSalesHeader: Record "Sales Header"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitPstdSalesLinesPerILEOnBeforeItemLedgEntryLoop(var ItemLedgEntry: record "Item Ledger Entry"; FromSalesLine: record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitPstdSalesLinesPerILEOnAfterAssignShipmentLineNo(var ItemLedgerEntry: Record "Item Ledger Entry"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitPstdPurchLinesPerILEOnBeforeCheckUnappliedLines(PurchaseHeader: Record "Purchase Header"; SkippedLine: Boolean; MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitPstdSalesLinesPerILEOnBeforeCheckUnappliedLines(SalesHeader: Record "Sales Header"; SkippedLine: Boolean; MissingExCostRevLink: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransfldsFromSalesToPurchLineOnBeforeValidateQuantity(FromSalesLine: Record "Sales Line"; var ToPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnAfterRecalculateSalesLine(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnBeforeRecalculateSalesLine(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnBeforeClearDropShipmentAndSpecialOrder(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesLineItemChargeAssignOnAfterValueEntryLoop(FromSalesHeader: Record "Sales Header"; ToSalesLine: Record "Sales Line"; ValueEntry: Record "Value Entry"; var TempToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)" temporary; var ToItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; var ItemChargeAssgntNextLineNo: Integer; var SumQtyToAssign: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromPurchLineItemChargeAssignOnAfterValueEntryLoop(FromPurchHeader: Record "Purchase Header"; ToPurchLine: Record "Purchase Line"; ValueEntry: Record "Value Entry"; var TempToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)" temporary; var ToItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var ItemChargeAssgntNextLineNo: Integer; var SumQtyToAssign: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkJobPlanningLineOnAfterJobPlanningLineModify(var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitPstdPurchLinesPerILEOnBeforeCheckJobNo(FromPurchLine: Record "Purchase Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchCrMemoLinesToDocOnAfterFilterEntryType(var FromPurchLineBuf: Record "Purchase Line" temporary; var ItemLedgEntryBuf: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchLineOnAfterValidateQuantityMoveNegLines(var ToPurchLine: Record "Purchase Line"; FromPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchLineOnBeforeValidateQuantity(var ToPurchLine: Record "Purchase Line"; RecalculateLines: Boolean; FromPurchaseLine: Record "Purchase Line"; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculatePurchLineOnAfterValidateQuantity(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessToAsmHeaderOnAfterValidateQty(var ToAsmHeader: Record "Assembly Header"; TempFromAsmHeader: Record "Assembly Header" temporary; ToSalesLine: Record "Sales Line"; BasicAsmOrderCopy: Boolean; AvailabilityCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculateSalesLineOnAfterValidateQuantity(var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculateSalesLineOnAfterValidateLineDiscountAmount(var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitPstdPurchLinesPerILEOnBeforeFromPurchLineBufInsert(var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var FromPurchLineBuf: Record "Purchase Line"; var ToPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitSalesDocLinesPerItemTrkgOnAfterCalcSignFactor(FromSalesLine: Record "Sales Line"; var SignFactor: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitSalesDocLinesPerItemTrkgOnAfterInitSalesLineBuf1(var SalesLineBuf1: Record "Sales Line" temporary; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetTrackingOnAssemblyReservationOnBeforeTempTrackingSpecificationInsert(var TempTrackingSpecification: Record "Tracking Specification" temporary; TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateToAsmLinesOnBeforeToAssemblyLineModify(ToAsmHeader: Record "Assembly Header"; var ToAssemblyLine: Record "Assembly Line"; var FromAsmLine: Record "Assembly Line"; ToSalesLine: Record "Sales Line"; BasicAsmOrderCopy: Boolean; AvailabilityCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateToAsmLinesOnAfterValidateQty(ToAsmHeader: Record "Assembly Header"; FromAsmLine: Record "Assembly Line"; var ToAssemblyLine: Record "Assembly Line"; ToSalesLine: Record "Sales Line"; BasicAsmOrderCopy: Boolean; AvailabilityCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesLineExtText(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; DocLineNo: Integer; var NextLineNo: Integer; var TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocLineOnAfterAssignCopiedFromPostedDoc(var ToSalesLine: Record "Sales Line"; ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocLineOnAfterValidateQuantityMoveNegLines(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocLineOnAfterMoveNegLines(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnBeforeCopyItemTracking(var TempSalesLineBuf: Record "Sales Line" temporary; ToSalesHeader: Record "Sales Header"; var FromSalesInvLine: Record "Sales Invoice Line"; var ItemLedgEntryBuf: Record "Item Ledger Entry" temporary; var TempItemTrkgEntry: Record "Reservation Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocLineOnBeforeCheckLocationOnWMS(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line"; var IsHandled: Boolean; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocLineOnBeforeAutoReserve(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocLineOnAfterCalcCopyThisLine(var ToSalesHeader: Record "Sales Header"; var FromSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; RoundingLineInserted: Boolean; var CopyThisLine: Boolean; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReCalcSalesLineOnBeforeCalcVAT(FromSalesHeader: Record "Sales Header"; ToSalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReCalcPurchLineOnBeforeCalcVAT(FromPurchaseHeader: Record "Purchase Header"; ToPurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesHeaderWhenCopyFromSalesHeaderOnBeforeValidateShipToCode(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSalesRounding(var FromSalesLine: Record "Sales Line"; var RoundingLineInserted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnAfterCopySalesDocLine(ToSalesLine: Record "Sales Line"; FromSalesInvLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchInvLinesToDocOnBeforeCopyItemCharges(FromPurchInvLine: Record "Purch. Inv. Line"; NextLineNo: Integer; var ToPurchaseLine: Record "Purchase Line"; TempPurchaseLineBuf: Record "Purchase Line" temporary; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocSalesLineOnBeforeCopyFromSalesDocAssgntToLine(FromSalesLine: Record "Sales Line"; ToSalesLine: Record "Sales Line"; RecalculateLines: Boolean; NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesDocSalesLine(var ToSalesLine: Record "Sales Line"; var TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines"; FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProperties(var IncludeHeader: Boolean; var RecalculateLines: Boolean; var MoveNegLines: Boolean; var CreateToHeader: Boolean; var HideDialog: Boolean; var ExactCostRevMandatory: Boolean; var ApplyFully: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocLineOnBeforeCopyThisLine(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line"; FromSalesDocType: Enum "Sales Document Type From"; var RecalculateLines: Boolean; var CopyThisLine: Boolean; var LinesNotCopied: Integer; var Result: Boolean; var IsHandled: Boolean; var NextLineNo: Integer; DocLineNo: Integer; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure CheckCopyFromSalesInvoiceAvailOnBeforeCheckItemAvailability(var ToSalesLine: Record "Sales Line"; var FromSalesInvLine: Record "Sales Invoice Line"; var ToSalesHeader: Record "Sales Header"; var FromSalesInvHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocLineOnBeforeCopyThisLine(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line"; MoveNegLines: Boolean; FromPurchDocType: Enum "Purchase Document Type From"; var LinesNotCopied: Integer; var CopyThisLine: Boolean; var Result: Boolean; var IsHandled: Boolean; ToPurchaseHeader: Record "Purchase Header"; var RecalculateLines: Boolean; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocLineOnBeforeCheckLocationOnWMS(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnAfterCopySalesPostedDeferrals(var FromSalesInvLine: Record "Sales Invoice Line"; NextLineNo: Integer; var ToSalesLine: Record "Sales Line"; var TempSalesLineBuf: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsCopyItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; FillExactCostRevLink: Boolean; var CopyItemTrkg: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCustLedgerEntry(var ToSalesHeader: Record "Sales Header"; FromDocType: Enum "Gen. Journal Document Type"; FromDocNo: Code[20]; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocLineOnBeforeValidateInvDiscountAmount(var ToSalesLine: Record "Sales Line"; InvDiscountAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocLineOnBeforeValidateLineDiscountPct(var ToSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesRounding(FromSalesLine: Record "Sales Line"; var RoundingLineInserted: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPurchPostedDeferrals(ToPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFieldsFromOldPurchHeader(var ToPurchHeader: Record "Purchase Header"; var OldPurchHeader: Record "Purchase Header"; IncludeHeader: Boolean; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFieldsFromOldSalesHeader(var ToSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchPurchLineOnAfterSetNextLineNo(var ToPurchLine: Record "Purchase Line"; var FromPurchLineArchive: Record "Purchase Line Archive"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocLineOnAfterSetNextLineNo(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchPurchLineOnBeforeCopyArchPurchLineExtText(ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; FromPurchHeaderArchive: Record "Purchase Header Archive"; FromPurchLineArchive: Record "Purchase Line Archive"; var NextLineNo: Integer; RecalculateLines: Boolean; var IsHandled: Boolean; var TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPurchLinesToBuffer(var TempPurchaseLine: Record "Purchase Line"; FromPurchaseLine2: Record "Purchase Line"; FromPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyShiptoCodeFromInvToCrMemo(var ToSalesHeader: Record "Sales Header"; FromSalesInvHeader: Record "Sales Invoice Header"; FromDocType: Enum "Sales Document Type From")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesCrMemoLinesToDocOnAfterFillSalesLineBuffer(ToSalesHeader: Record "Sales Header"; var FromSalesLineBuf: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnAfterFillSalesLinesBuffer(ToSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchCrMemoLinesToDocOnAfterFillPurchLineBuffer(ToPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchInvLinesToDocOnAfterFillPurchLineBuffer(ToPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnBeforeTestPricesInclVAT(ToSalesHeader: Record "Sales Header"; IncludeHeader: Boolean; var RecalculateLines: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesShptLinesToDocOnBeforeTestPricesInclVAT(ToSalesHeader: Record "Sales Header"; IncludeHeader: Boolean; var RecalculateLines: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculateSalesLineOnBeforeValidateLocationCode(var ToSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculatePurchLineOnBeforeValidateLocationCode(var ToPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesCreditMemoHeaderOnBeforeSetShipmentDate(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchRcptLinesToDocOnAfterFilterPstdDocLnItemLedgEntries(FromPurchLine: Record "Purchase Line"; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchInvLinesToDocOnAfterCalcShouldCopyItemTrackingEntries(ToPurchLine: Record "Purchase Line"; var ShouldCopyItemTrackingEntries: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchCrMemoLinesToDocOnAfterCalcShouldCopyItemTrackingEntries(ToPurchLine: Record "Purchase Line"; var ShouldCopyItemTrackingEntries: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyAsmOrderToAsmOrderOnBeforeModifySalesLine(var ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetDefaultValuesToSalesLineOnBeforeSetShipmentDate(ToSalesHeader: Record "Sales Header"; var ShouldSetShipmentDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnAfterToSalesLineDeleteAll(var ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchSalesLineOnBeforeTransferExtendedText(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesHeaderArchive: Record "Sales Header Archive"; FromSalesLineArchive: Record "Sales Line Archive"; RecalculateLines: Boolean; var NextLineNo: Integer; var TransferOldExtLines: Codeunit "Transfer Old Ext. Text Lines"; var IsHandled: Boolean; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPostedDeferrals(DeferralDocType: Enum "Deferral Document Type"; FromDocType: Integer; FromDocNo: Code[20]; FromLineNo: Integer; ToDocType: Integer; ToDocNo: Code[20]; ToLineNo: Integer; var StartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyDeferrals(DeferralDocType: Enum "Deferral Document Type"; FromDocType: Integer; FromDocNo: Code[20]; FromLineNo: Integer; ToDocType: Integer; ToDocNo: Code[20]; ToLineNo: Integer; var StartDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempReservationEntryOnBeforeInsert(var TempReservationEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCopySalesDocLineOnBeforeCopySalesJobFields(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; FromSalesDocType: Enum "Sales Document Type From")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalcSalesLineOnBeforeRoundUnitPrice(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocLineOnAfterCalcShouldValidateQuantityMoveNegLines(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line"; var ShouldValidateQuantityMoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocSalesLineOnBeforeFinishSalesDocSalesLine(FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line"; RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesShptLinesToDocOnAfterCopySalesLine(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesShptLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySalesDocCrMemoLine(var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ToSalesHeader: Record "Sales Header"; var FromSalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleAsmAttachedToSalesLine(var ToSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitAndCheckPurchaseDocumentsOnAfterDelNegLines(var ToPurchaseHeader: Record "Purchase Header"; var FromPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitSalesLineFieldsOnBeforeInitQty(var ToSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchSalesLineOnAfterCalcShouldRecalculateAmount(var ToSalesLine: Record "Sales Line"; FromSalesLineArchive: Record "Sales Line Archive"; var ShouldRecalculateAmount: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitAndCheckSalesDocumentsOnAfterDelNegLines(ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchLinesWithNegQty(FromPurchHeader: Record "Purchase Header"; OnlyTest: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCopySalesDocLineOnAfterInsertToSalesLine(var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line"; FromSalesDocType: Enum "Sales Document Type From"; MoveNegLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculateSalesLineOnBeforeValidateWorkTypeCode(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitSalesDocLinesPerItemTrkg(var ItemLedgerEntry: Record "Item Ledger Entry"; var TempReservationEntry: Record "Reservation Entry" temporary; var TempSalesLineBuf: Record "Sales Line" temporary; FromSalesLine: Record "Sales Line"; var TempDocSalesLine: Record "Sales Line" temporary; var NextLineNo: Integer; var NextItemTrkgEntryNo: Integer; var MissingExCostRevLink: Boolean; FromShptOrRcpt: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitPurchDocLinesPerItemTrkg(var ItemLedgerEntry: Record "Item Ledger Entry"; var TempReservationEntry: Record "Reservation Entry" temporary; var FromPurchaseLineBuf: Record "Purchase Line"; FromPurchaseLine: Record "Purchase Line"; var TempDocPurchaseLine: Record "Purchase Line" temporary; var NextLineNo: Integer; var NextItemTrkgEntryNo: Integer; var MissingExCostRevLink: Boolean; FromShptOrRcpt: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitAndCheckSalesDocumentsOnAfterCheckSalesDocItselfCopy(ToSalesHeader: Record "Sales Header"; FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitAndCheckPurchaseDocumentsOnAfterCheckPurchDocItselfCopy(ToPurchaseHeader: Record "Purchase Header"; FromPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyArchPurchLineOnBeforeCheckExactCostRevMandatory(var ToPurchLine: Record "Purchase Line"; FromPurchLineArchive: Record "Purchase Line Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomer(var FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromSalesLineItemChargeAssign(FromSalesLine: Record "Sales Line"; ToSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header"; var ItemChargeAssgntNextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesReturnRcptLinesToDocOnBeforeCopyLines(var ToSalesHeader: Record "Sales Header"; FromReturnRcptLine: Record "Return Receipt Line"; var FromSalesLineBuf: Record "Sales Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchRcptLinesToDocOnBeforeCopyItemTrkg(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; FromPurchLineBuf: Record "Purchase Line"; var RecalculateLines: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchCrMemoLinesToDocOnBeforeCopyItemCharges(var ToPurchLine: Record "Purchase Line"; var FromPurchLineBuf: Record "Purchase Line" temporary; RecalculateLines: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchReturnShptLinesToDocOnBeforeCopyItemTrkg(var ToPurchLine: Record "Purchase Line"; var FromPurchLineBuf: Record "Purchase Line" temporary; RecalculateLines: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesCreditMemoHeader(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitAndCheckSalesDocumentsOnBeforeCheckCreditLimit(var FromSalesHeader: Record "Sales Header"; var ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFieldsFromCrMemoToInvOnBeforeTransferFields(var ToSalesHeader: Record "Sales Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnBeforeTempSalesLineBufLoop(var ToSalesHeader: Record "Sales Header"; var TempSalesLineBuf: Record "Sales Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchHeaderFromPostedReceiptOnBeforeTransferFields(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchHeaderFromPostedInvoiceOnBeforeTransferFields(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchHeaderFromPostedReturnShipmentOnBeforeTransferFields(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromReturnShipmentHeader: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchHeaderFromPostedCreditMemoOnBeforeTransferFields(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocOnBeforeConfirmDeleteLines(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocOnBeforeCreateOrIncludeHeader(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; CreateToHeader: Boolean; IncludeHeader: Boolean; var DoExit: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocPurchLineOnAfterProcessFromPurchLineInLoop(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; FromPurchLine: Record "Purchase Line"; RecalculateLines: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchInvLinesToDocOnBeforeInsertOldPurchLine(var ToPurchaseHeader: Record "Purchase Header"; var FromPurchLineBuf: Record "Purchase Line" temporary; var OldInvDocNo: Code[20]; var OldRcptDocNo: Code[20]; var NextLineNo: Integer; SkipCopyFromDescription: Boolean; InsertCancellationLine: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineBeforeRecalculateAmount(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculatePurchLineOnBeforeValidatePurchasingCode(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var CopyThisLine: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocLineOnBeforeSetSalesHeader(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; FromSalesHeader: Record "Sales Header"; FromSalesLine: Record "Sales Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnBeforeToSalesLineValidateUnitCostLcy(var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnAfterUpdateWithWarehouseShip(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchDocLineOnBeforeRecalculateLines(var ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; var FromPurchHeader: Record "Purchase Header"; var FromPurchLine: Record "Purchase Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchLineOnAfterCopyDocLine(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculateSalesLineOnBeforeCopyThisLine(ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculateSalesLineOnAfterValidateNo(var ToSalesLine: Record "Sales Line"; var FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculatePurchLineOnAfterCopyThisLine(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculatePurchLineOnAfterValidateNo(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecalculatePurchLineOnAfterValidatePurchasingCode(var ToPurchLine: Record "Purchase Line"; var FromPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesInvLinesToDocOnAfterCopyItemLedgEntryTrackingToSalesLine(ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesCrMemoLinesToDocOnAfterCopyItemLedgEntryTrkgToSalesLn(var ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVendor(var FromPurchLine: Record "Purchase Line"; var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFromPurchaseHeader(PurchaseHeaderFrom: Record "Purchase Header"; PurchaseHeaderTo: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySalesDocLineOnBeforeInitToSalesLine(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line"; var ShouldInitToSalesLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnBeforeValidateToSalesLine(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; var FromSalesHeader: Record "Sales Header"; var FromSalesLine: Record "Sales Line"; var ShouldRecalculateSalesLine: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertOldSalesDocNoLineProcedure(var ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; OldDocType: Option; OldDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertOldPurchDocNoLineProcedure(ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; OldDocType: Option; OldDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchRcptLinesToDocOnBeforeTestFieldPricesIncludingVAT(var ToPurchaseHeader: Record "Purchase Header"; IncludeHeader: Boolean; RecalculateLines: Boolean; var FromPurchRcptHeader: Record "Purch. Rcpt. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchInvLinesToDocOnBeforeTestFieldPricesIncludingVAT(var ToPurchaseHeader: Record "Purchase Header"; IncludeHeader: Boolean; RecalculateLines: Boolean; var FromPurchInvHeader: Record "Purch. Inv. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchCrMemoLinesToDocOnBeforeTestFieldPricesIncludingVAT(var ToPurchaseHeader: Record "Purchase Header"; IncludeHeader: Boolean; RecalculateLines: Boolean; var FromPurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPurchReturnShptLinesToDocOnBeforeTestFieldPricesIncludingVAT(var ToPurchaseHeader: Record "Purchase Header"; IncludeHeader: Boolean; RecalculateLines: Boolean; var FromReturnShptHeader: Record "Return Shipment Header"; var IsHandled: Boolean)
    begin
    end;
}

