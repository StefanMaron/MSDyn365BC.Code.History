namespace Microsoft.Finance.Deferral;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

report 1702 "Deferral Summary - Purchasing"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Deferral/DeferralSummaryPurchasing.rdlc';
    ApplicationArea = Suite;
    Caption = 'Purchasing Deferral Summary';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Posted Deferral Header"; "Posted Deferral Header")
        {
            DataItemTableView = sorting("Deferral Doc. Type", CustVendorNo, "Posting Date", "Gen. Jnl. Document No.", "Account No.", "Document Type", "Document No.", "Line No.") order(ascending) where("Deferral Doc. Type" = const(Purchase), CustVendorNo = filter(<> ''));
            RequestFilterFields = CustVendorNo, "Document No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(GLAccTableCaption; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(EmptyString; '')
            {
            }
            column(VendorFilter; VendorFilter)
            {
            }
            column(VendNo; CustVendorNo)
            {
            }
            column(No_GLAcc; "Account No.")
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Document_Type; "Document Type")
            {
            }
            column(DocumentTypeString; DocumentTypeString)
            {
            }
            column(Line_No; "Line No.")
            {
            }
            column(DeferralSummaryPurchCaption; DeferralSummaryPurchCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(GLBalCaption; GLBalCaptionLbl)
            {
            }
            column(RemAmtDefCaption; RemAmtDefCaptionLbl)
            {
            }
            column(TotAmtDefCaption; TotAmtDefCaptionLbl)
            {
            }
            column(BalanceAsOfDateCaption; BalanceAsOfDateCaptionLbl + Format(BalanceAsOfDateFilter))
            {
            }
            column(BalanceAsOfDateFilter; BalanceAsOfDateFilter)
            {
            }
            column(DocumentCaption; DocumentCaptionLbl + Format(DocumentFilter))
            {
            }
            column(DocumentFilter; DocumentFilter)
            {
            }
            column(VendorCaption; VendorCaptionLbl + Format(VendorFilter))
            {
            }
            column(AccountNoCaption; AccountNoLbl)
            {
            }
            column(AmtRecognizedCaption; AmtRecognizedLbl)
            {
            }
            column(AccountName; AccountName)
            {
            }
            column(VendorName; VendorName)
            {
            }
            column(TotalAmtDeferred; "Amount to Defer (LCY)")
            {
            }
            column(NumOfPeriods; "No. of Periods")
            {
            }
            column(DocumentType; "Document Type")
            {
            }
            column(DeferralStartDate; Format("Start Date"))
            {
            }
            column(AmtRecognized; AmtRecognized)
            {
            }
            column(RemainingAmtDeferred; RemainingAmtDeferred)
            {
            }
            column(PostingDate; Format(PostingDate))
            {
            }
            column(DeferralAccount; DeferralAccount)
            {
            }
            column(Amount; "Amount to Defer (LCY)")
            {
            }
            column(LineDescription; LineDescription)
            {
            }
            column(LineType; LineType)
            {
            }

            trigger OnAfterGetRecord()
            var
                PostedDeferralLine: Record "Posted Deferral Line";
                PurchaseHeader: Record "Purchase Header";
                PurchaseLine: Record "Purchase Line";
                PurchInvHeader: Record "Purch. Inv. Header";
                PurchInvLine: Record "Purch. Inv. Line";
                PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                PurchCrMemoLine: Record "Purch. Cr. Memo Line";
                ReverseAmounts: Boolean;
            begin
                PreviousVendor := WorkingVendor;
                ReverseAmounts := false;

                if Vendor.Get(CustVendorNo) then begin
                    VendorName := Vendor.Name;
                    WorkingVendor := CustVendorNo;
                end;

                if PrintOnlyOnePerPage and (PreviousVendor <> WorkingVendor) then begin
                    PostedDeferralHeaderPage.Reset();
                    PostedDeferralHeaderPage.SetRange(CustVendorNo, CustVendorNo);
                    if PostedDeferralHeaderPage.FindFirst() then
                        PageGroupNo := PageGroupNo + 1;
                end;

                LineDescription := '';
                case "Document Type" of
                    7: // Posted Invoice
                        if PurchInvLine.Get("Document No.", "Line No.") then begin
                            LineDescription := PurchInvLine.Description;
                            LineType := PurchInvLine.Type.AsInteger();
                            if PurchInvHeader.Get("Document No.") then
                                PostingDate := PurchInvHeader."Posting Date";
                        end;
                    8: // Posted Credit Memo
                        if PurchCrMemoLine.Get("Document No.", "Line No.") then begin
                            LineDescription := PurchCrMemoLine.Description;
                            LineType := PurchCrMemoLine.Type.AsInteger();
                            if PurchCrMemoHdr.Get("Document No.") then
                                PostingDate := PurchCrMemoHdr."Posting Date";
                            ReverseAmounts := true;
                        end;
                    9: // Posted Return Receipt
                        if PurchaseLine.Get("Document Type", "Document No.", "Line No.") then begin
                            LineDescription := PurchaseLine.Description;
                            LineType := PurchaseLine.Type.AsInteger();
                            if PurchaseHeader.Get("Document Type", "Document No.") then
                                PostingDate := PurchaseHeader."Posting Date";
                            ReverseAmounts := true;
                        end;
                end;

                AmtRecognized := 0;
                RemainingAmtDeferred := 0;

                PostedDeferralLine.SetRange("Deferral Doc. Type", "Deferral Doc. Type");
                PostedDeferralLine.SetRange("Gen. Jnl. Document No.", "Gen. Jnl. Document No.");
                PostedDeferralLine.SetRange("Account No.", "Account No.");
                PostedDeferralLine.SetRange("Document Type", "Document Type");
                PostedDeferralLine.SetRange("Document No.", "Document No.");
                PostedDeferralLine.SetRange("Line No.", "Line No.");
                if PostedDeferralLine.Find('-') then
                    repeat
                        DeferralAccount := PostedDeferralLine."Deferral Account";
                        if PostedDeferralLine."Posting Date" <= BalanceAsOfDateFilter then
                            AmtRecognized := AmtRecognized + PostedDeferralLine."Amount (LCY)"
                        else
                            RemainingAmtDeferred := RemainingAmtDeferred + PostedDeferralLine."Amount (LCY)";
                    until (PostedDeferralLine.Next() = 0);

                DocumentTypeString := ReturnPurchDocTypeString("Document Type");
                if ReverseAmounts then begin
                    AmtRecognized := -AmtRecognized;
                    RemainingAmtDeferred := -RemainingAmtDeferred;
                    "Amount to Defer (LCY)" := -"Amount to Defer (LCY)";
                end;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewPageperVendor; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Suite;
                        Caption = 'New Page per Vendor';
                        ToolTip = 'Specifies if each vendor''s information is printed on a new page if you have chosen two or more vendors to be included in the report.';
                    }
                    field(BalanceAsOfDateFilter; BalanceAsOfDateFilter)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Balance as of:';
                        ToolTip = 'Specifies the date up to which you want to see deferred expenses.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if BalanceAsOfDateFilter = 0D then
                BalanceAsOfDateFilter := WorkDate();
        end;
    }

    labels
    {
        PostingDateCaption = 'Posting Date';
        DocNoCaption = 'Document No.';
        DescCaption = 'Description';
        EntryNoCaption = 'Entry No.';
        NoOfPeriodsCaption = 'No. of Periods';
        DeferralAccountCaption = 'Deferral Account';
        DocTypeCaption = 'Document Type';
        DefStartDateCaption = 'Deferral Start Date';
        AcctNameCaption = 'Account Name';
        LineNoCaption = 'Line No.';
        VendNoCaption = 'Vendor No.';
        VendNameCaption = 'Vendor Name';
        LineDescCaption = 'Line Description';
        LineTypeCaption = 'Line Type';
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        VendorFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
    end;

    var
        Vendor: Record Vendor;
        PostedDeferralHeaderPage: Record "Posted Deferral Header";
        GLFilter: Text;
        VendorFilter: Text;
        DocumentFilter: Text;
        PrintOnlyOnePerPage: Boolean;
        PageGroupNo: Integer;
        PageCaptionLbl: Label 'Page';
        BalanceCaptionLbl: Label 'This also includes general ledger accounts that only have a balance.';
        PeriodCaptionLbl: Label 'This report also includes closing entries within the period.';
        GLBalCaptionLbl: Label 'Balance';
        DeferralSummaryPurchCaptionLbl: Label 'Deferral Summary - Purchasing';
        RemAmtDefCaptionLbl: Label 'Remaining Amt. Deferred';
        TotAmtDefCaptionLbl: Label 'Total Amt. Deferred';
        BalanceAsOfDateFilter: Date;
        PostingDate: Date;
        AmtRecognized: Decimal;
        RemainingAmtDeferred: Decimal;
        BalanceAsOfDateCaptionLbl: Label 'Balance as of: ';
        AccountNoLbl: Label 'Account No.';
        AmtRecognizedLbl: Label 'Amt. Recognized';
        AccountName: Text[100];
        VendorName: Text[100];
        WorkingVendor: Code[20];
        PreviousVendor: Code[20];
        DeferralAccount: Code[20];
        DocumentTypeString: Text;
        QuoteLbl: Label 'Quote';
        OrderLbl: Label 'Order';
        InvoiceLbl: Label 'Invoice';
        CreditMemoLbl: Label 'Credit Memo';
        BlanketOrderLbl: Label 'Blanket Order';
        ReturnOrderLbl: Label 'Return Order';
        ShipmentLbl: Label 'Shipment';
        PostedInvoiceLbl: Label 'Posted Invoice';
        PostedCreditMemoLbl: Label 'Posted Credit Memo';
        PostedReturnReceiptLbl: Label 'Posted Return Receipt';
        LineDescription: Text[100];
        LineType: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)";
        DocumentCaptionLbl: Label 'Document:';
        VendorCaptionLbl: Label 'Vendor:';

    procedure InitializeRequest(NewPrintOnlyOnePerPage: Boolean; NewBalanceAsOfDateFilter: Date; NewDocumentNoFilter: Text; NewVendorNoFilter: Text)
    begin
        PrintOnlyOnePerPage := NewPrintOnlyOnePerPage;
        BalanceAsOfDateFilter := NewBalanceAsOfDateFilter;
        VendorFilter := NewVendorNoFilter;
        DocumentFilter := NewDocumentNoFilter;
    end;

    local procedure ReturnPurchDocTypeString(PurchDocType: Integer): Text
    begin
        case PurchDocType of
            0:
                exit(QuoteLbl);
            1:
                exit(OrderLbl);
            2:
                exit(InvoiceLbl);
            3:
                exit(CreditMemoLbl);
            4:
                exit(BlanketOrderLbl);
            5:
                exit(ReturnOrderLbl);
            6:
                exit(ShipmentLbl);
            7:
                exit(PostedInvoiceLbl);
            8:
                exit(PostedCreditMemoLbl);
            9:
                exit(PostedReturnReceiptLbl);
            else
                exit('');
        end;
    end;
}

