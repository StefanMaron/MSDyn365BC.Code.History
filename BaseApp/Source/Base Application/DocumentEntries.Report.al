report 35 "Document Entries"
{
    DefaultLayout = RDLC;
    RDLCLayout = './DocumentEntries.rdlc';
    Caption = 'Document Entries';

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(DocNoFilter; Text001 + Format(DocNoFilter))
            {
            }
            column(PostDateFilter; Text002 + PostingDateFilter)
            {
            }
            column(DocEntryNoofRecords; DocEntry."No. of Records")
            {
            }
            column(DocEntryTableName; DocEntry."Table Name")
            {
            }
            column(PrintAmountsInLCY; PrintAmountsInLCY)
            {
            }
            column(CurrencyCaptionRBC; CurrencyCaptionRBC)
            {
            }
            column(DocEntriesCaption; DocEntriesCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(NavigateFiltersCaption; NavigateFiltersCaptionLbl)
            {
            }
            column(DocEntryNoofRecordsCptn; DocEntryNoofRecordsCptnLbl)
            {
            }
            column(DocEntryTableNameCaption; DocEntryTableNameCaptionLbl)
            {
            }
            dataitem("Service Ledger Entry"; "Service Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(PostDate_ServiceLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_ServLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_ServLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(AmtLCY_ServLedgEntry; "Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(EntryNo_ServLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(ServCntrtNo_ServLedgEntry; "Service Contract No.")
                {
                    IncludeCaption = true;
                }
                column(ServLedgEntryPostDtCaption; ServLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Service Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Warranty Ledger Entry"; "Warranty Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(EntryNo_WarrantyLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(PostDt_WarrantyLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_WarrantyLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_WarrantyLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Amt_WarrantyLedgEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(WarrantyLedgEntryPostDtCaption; WarrantyLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Warranty Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Service Shipment Header"; "Service Shipment Header")
            {
                DataItemTableView = SORTING("No.");
                column(CurrencyCaption; CurrencyCaption)
                {
                }
                column(PostDate_ServShptHeader; Format("Posting Date"))
                {
                }
                column(No_ServShptHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_ServShptHeader; Description)
                {
                    IncludeCaption = true;
                }
                column(CurrencyCode_ServShptHeader; "Currency Code")
                {
                }
                column(ServShptHeaderPostDateCaption; ServShptHeaderPostDateCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Service Shipment Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Sales Shipment Header"; "Sales Shipment Header")
            {
                DataItemTableView = SORTING("No.");
                column(SalesShipmentHdrCurryCaption; CurrencyCaption)
                {
                }
                column(PostingDt_SalesShptHeader; Format("Posting Date"))
                {
                }
                column(No_SalesShptHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(SelltoCustNo_SalesShptHeader; "Sell-to Customer No.")
                {
                    IncludeCaption = true;
                }
                column(BilltoCustNo_SalesShptHeader; "Bill-to Customer No.")
                {
                    IncludeCaption = true;
                }
                column(PostDesc_SalesShptHeader; "Posting Description")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_SalesShptHeader; "Currency Code")
                {
                }
                column(SalesShptHeaderPostingDtCaption; SalesShptHeaderPostingDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Sales Shipment Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Sales Invoice Header"; "Sales Invoice Header")
            {
                DataItemTableView = SORTING("No.");
                column(SalesInvHdrCurryCaption; CurrencyCaption)
                {
                }
                column(PostDate_SalesInvHeader; Format("Posting Date"))
                {
                }
                column(No_SalesInvHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(PostDesc_SalesInvHeader; "Posting Description")
                {
                    IncludeCaption = true;
                }
                column(SelltoCustNo_SalesInvHeader; "Sell-to Customer No.")
                {
                    IncludeCaption = true;
                }
                column(BilltoCustNo_SalesInvHeader; "Bill-to Customer No.")
                {
                    IncludeCaption = true;
                }
                column(Amt_SalesInvHeader; Amount)
                {
                    IncludeCaption = true;
                }
                column(AmtIncVAT_SalesInvHeader; "Amount Including VAT")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_SalesInvHeader; "Currency Code")
                {
                }
                column(SalesInvHeaderPostDateCaption; SalesInvHeaderPostDateCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            Amount := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", Amount, "Currency Factor");
                            "Amount Including VAT" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Amount Including VAT", "Currency Factor");
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Sales Invoice Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Return Receipt Header"; "Return Receipt Header")
            {
                DataItemTableView = SORTING("No.");
                column(ReturnRcptHdrCurryCaption; CurrencyCaption)
                {
                }
                column(PostDt_ReturnRcptHeader; Format("Posting Date"))
                {
                }
                column(No_ReturnRcptHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(PostDesc_ReturnRcptHeader; "Posting Description")
                {
                    IncludeCaption = true;
                }
                column(SelltoCustNo_RetrnRcptHeader; "Sell-to Customer No.")
                {
                    IncludeCaption = true;
                }
                column(BilltoCustNo_RetrnRcptHeader; "Bill-to Customer No.")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_ReturnRcptHeader; "Currency Code")
                {
                }
                column(ReturnRcptHeaderPostDtCaption; ReturnRcptHeaderPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Return Receipt Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Sales Cr.Memo Header"; "Sales Cr.Memo Header")
            {
                DataItemTableView = SORTING("No.");
                column(SalesCrMemoHdrCurrCaption; CurrencyCaption)
                {
                }
                column(PostDt_SalesCrMemoHeader; Format("Posting Date"))
                {
                }
                column(No_SalesCrMemoHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(PstDesc_SalesCrMemoHeader; "Posting Description")
                {
                    IncludeCaption = true;
                }
                column(SellCustNo_SalesCrMemoHeader; "Sell-to Customer No.")
                {
                    IncludeCaption = true;
                }
                column(BillCustNo_SalesCrMemoHeader; "Bill-to Customer No.")
                {
                    IncludeCaption = true;
                }
                column(Amt_SalesCrMemoHeader; Amount)
                {
                    IncludeCaption = true;
                }
                column(AmtIncludVAT_SalesCrMemoHeader; "Amount Including VAT")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_SalesCrMemoHeader; "Currency Code")
                {
                }
                column(SalesCrMemoHeaderPostDtCaption; SalesCrMemoHeaderPostDtCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            Amount := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", Amount, "Currency Factor");
                            "Amount Including VAT" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Amount Including VAT", "Currency Factor");
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Sales Cr.Memo Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Issued Reminder Header"; "Issued Reminder Header")
            {
                DataItemTableView = SORTING("No.");
                column(IssuedRemHdrCurCaption; CurrencyCaption)
                {
                }
                column(PostDt_IssuedReminderHeader; Format("Posting Date"))
                {
                }
                column(No_IssuedReminderHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(PostDesc_IssReminderHeadr; "Posting Description")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_IssudReminderHeader; "Currency Code")
                {
                }
                column(VATAmt_IssuedReminderHeader; "VAT Amount")
                {
                    IncludeCaption = true;
                }
                column(AddFee_IssuedReminderHeader; "Additional Fee")
                {
                }
                column(IntrstAmt_IssuReminderHeader; "Interest Amount")
                {
                }
                column(RemAmt_IssReminderHeader; "Remaining Amount")
                {
                    IncludeCaption = true;
                }
                column(IssuedReminderHeaderPostDtCaption; IssuedReminderHeaderPostDtCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            "Remaining Amount" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Remaining Amount", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                            "Interest Amount" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Interest Amount", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                            "Additional Fee" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Additional Fee", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                            "VAT Amount" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "VAT Amount", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Issued Reminder Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Issued Fin. Charge Memo Header"; "Issued Fin. Charge Memo Header")
            {
                DataItemTableView = SORTING("No.");
                column(IssuedFinChrgeCurrCaption; CurrencyCaption)
                {
                }
                column(PostDate_IssuedFinChgMemoHeader; Format("Posting Date"))
                {
                }
                column(No_IssuedFinChrgMemoHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(PstDesc_IssuedFinChrgMemoHeader; "Posting Description")
                {
                    IncludeCaption = true;
                }
                column(RmnAmt_IssuedFinChrgMemoHeader; "Remaining Amount")
                {
                    IncludeCaption = true;
                }
                column(InrstAmt_IssuedFinChrgMemoHeader; "Interest Amount")
                {
                    IncludeCaption = true;
                }
                column(AddFee_IssuedFinChrgMemoHeader; "Additional Fee")
                {
                    IncludeCaption = true;
                }
                column(VATAmt_IssuedFinChrgMemoHeader; "VAT Amount")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_IssuedFinChrgMemoHeader; "Currency Code")
                {
                }
                column(IssuedFinChgMemoHeaderPostDateCaption; IssuedFinChgMemoHeaderPostDateCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            "Remaining Amount" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Remaining Amount", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                            "Interest Amount" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Interest Amount", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                            "Additional Fee" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Additional Fee", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                            "VAT Amount" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "VAT Amount", CurrExchRate.ExchangeRate("Posting Date", "Currency Code"));
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Issued Fin. Charge Memo Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Purch. Rcpt. Header"; "Purch. Rcpt. Header")
            {
                DataItemTableView = SORTING("No.");
                column(PurchRcptHdrCurrCaption; CurrencyCaption)
                {
                }
                column(PstDate_PurchRcptHeader; Format("Posting Date"))
                {
                }
                column(No_PurchRcptHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(PstDesc_PurchRcptHeader; "Posting Description")
                {
                }
                column(BuyfromVenNo_PurchRcptHeader; "Buy-from Vendor No.")
                {
                    IncludeCaption = true;
                }
                column(PaytoVenNo_PurchRcptHeader; "Pay-to Vendor No.")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_PurchRcptHeader; "Currency Code")
                {
                }
                column(PurchRcptHeaderPostDtCaption; PurchRcptHeaderPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Purch. Rcpt. Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Purch. Inv. Header"; "Purch. Inv. Header")
            {
                DataItemTableView = SORTING("No.");
                column(PurchInvHdrCurrCaption; CurrencyCaption)
                {
                }
                column(PstDate_PurchInvHeader; Format("Posting Date"))
                {
                }
                column(No_PurchInvHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(PstDesc_PurchInvHeader; "Posting Description")
                {
                    IncludeCaption = true;
                }
                column(BuyfromVenNo_PurchInvHeader; "Buy-from Vendor No.")
                {
                    IncludeCaption = true;
                }
                column(PaytoVenNo_PurchInvHeader; "Pay-to Vendor No.")
                {
                    IncludeCaption = true;
                }
                column(Amt_PurchInvHeader; Amount)
                {
                    IncludeCaption = true;
                }
                column(CurrCode_PurchInvHeader; "Currency Code")
                {
                }
                column(AmtIncluVAT_PurchInvHeader; "Amount Including VAT")
                {
                    IncludeCaption = true;
                }
                column(PurchInvHeaderPostDtCaption; PurchInvHeaderPostDtCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            Amount := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", Amount, "Currency Factor");
                            "Amount Including VAT" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Amount Including VAT", "Currency Factor");
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Purch. Inv. Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Return Shipment Header"; "Return Shipment Header")
            {
                DataItemTableView = SORTING("No.");
                column(RtrnShpmntHdrCurrCaption; CurrencyCaption)
                {
                }
                column(PstDate_ReturnShptHeader; Format("Posting Date"))
                {
                }
                column(No_ReturnShptHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(PstDesc_ReturnShptHeader; "Posting Description")
                {
                    IncludeCaption = true;
                }
                column(BuyfromVenNo_ReturnShptHeader; "Buy-from Vendor No.")
                {
                    IncludeCaption = true;
                }
                column(PaytoVenNo_ReturnShptHeader; "Pay-to Vendor No.")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_ReturnShptHeader; "Currency Code")
                {
                }
                column(ReturnShptHeaderPostDtCaption; ReturnShptHeaderPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Return Shipment Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Purch. Cr. Memo Hdr."; "Purch. Cr. Memo Hdr.")
            {
                DataItemTableView = SORTING("No.");
                column(PurchCrMemoHdrCurrCaption; CurrencyCaption)
                {
                }
                column(PstDate_PurchCrMemoHeader; Format("Posting Date"))
                {
                }
                column(No_PurchCrMemoHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(PstDesc_PurchCrMemoHeader; "Posting Description")
                {
                    IncludeCaption = true;
                }
                column(BuyfromVenNo_PurchCrMemoHeader; "Buy-from Vendor No.")
                {
                    IncludeCaption = true;
                }
                column(PaytoVenNo_PurchCrMemoHeader; "Pay-to Vendor No.")
                {
                    IncludeCaption = true;
                }
                column(Amt_PurchCrMemoHeader; Amount)
                {
                    IncludeCaption = true;
                }
                column(CurrCode_PurchCrMemoHeader; "Currency Code")
                {
                }
                column(AmtInclVAT_PurchCrMemoHeader; "Amount Including VAT")
                {
                    IncludeCaption = true;
                }
                column(PurchCrMemoHdrPostDtCaption; PurchCrMemoHdrPostDtCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountsInLCY then
                        if "Currency Code" <> '' then begin
                            Amount := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code", Amount, "Currency Factor");
                            "Amount Including VAT" := CurrExchRate.ExchangeAmtFCYToLCY("Posting Date", "Currency Code",
                                "Amount Including VAT", "Currency Factor");
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Purch. Cr. Memo Hdr." then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Production Order"; "Production Order")
            {
                DataItemTableView = SORTING(Status, "No.");
                column(No_ProdOrder; "No.")
                {
                    IncludeCaption = true;
                }
                column(Status_ProdOrder; Status)
                {
                    IncludeCaption = true;
                }
                column(StatusCaption_ProdOrder; FieldCaption(Status))
                {
                }
                column(Desc_ProdOrder; Description)
                {
                    IncludeCaption = true;
                }
                column(SourceType_ProdOrder; "Source Type")
                {
                    IncludeCaption = true;
                }
                column(SourceNo_ProdOrder; "Source No.")
                {
                    IncludeCaption = true;
                }
                column(UnitCost_ProdOrder; "Unit Cost")
                {
                    IncludeCaption = true;
                }
                column(CostAmt_ProdOrder; "Cost Amount")
                {
                    IncludeCaption = true;
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Production Order" then
                        CurrReport.Break();

                    SetCurrentKey(Status, "No.");
                    SetRange(Status, Status::Released, Status::Finished);
                    SetFilter("No.", DocNoFilter);
                end;
            }
            dataitem("Transfer Shipment Header"; "Transfer Shipment Header")
            {
                DataItemTableView = SORTING("No.");
                column(PstDate_TransShptHeader; Format("Posting Date"))
                {
                }
                column(No_TransShptHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(TransferfromCode_TransShptHeader; "Transfer-from Code")
                {
                    IncludeCaption = true;
                }
                column(TransferfromName_TransShptHeader; "Transfer-from Name")
                {
                    IncludeCaption = true;
                }
                column(TranstoCode_TransShptHeader; "Transfer-to Code")
                {
                    IncludeCaption = true;
                }
                column(TranstoName_TransShptHeader; "Transfer-to Name")
                {
                    IncludeCaption = true;
                }
                column(TransShptHeaderPostDtCaption; TransShptHeaderPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Transfer Shipment Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Transfer Receipt Header"; "Transfer Receipt Header")
            {
                DataItemTableView = SORTING("No.");
                column(PstDate_TransRcptHeader; Format("Posting Date"))
                {
                }
                column(No_TransRcptHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(TransfromCode_TransRcptHeader; "Transfer-from Code")
                {
                    IncludeCaption = true;
                }
                column(TransfromName_TransRcptHeader; "Transfer-from Name")
                {
                    IncludeCaption = true;
                }
                column(TranstoCode_TransRcptHeader; "Transfer-to Code")
                {
                    IncludeCaption = true;
                }
                column(TranstoName_TransRcptHeader; "Transfer-to Name")
                {
                    IncludeCaption = true;
                }
                column(TransRcptHeaderPostDtCaption; TransRcptHeaderPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Transfer Receipt Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Posted Whse. Shipment Line"; "Posted Whse. Shipment Line")
            {
                DataItemTableView = SORTING("Posted Source No.", "Posting Date");
                column(PstDate_PostedWhseShptLine; Format("Posting Date"))
                {
                }
                column(ItemNo_PostedWhseShptLine; "Item No.")
                {
                    IncludeCaption = true;
                }
                column(Qty_PostedWhseShptLine; Quantity)
                {
                    IncludeCaption = true;
                }
                column(UOMCode_PostedWhseShptLine; "Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
                column(Desc_PostedWhseShptLine; Description)
                {
                    IncludeCaption = true;
                }
                column(PstdSourceDoc_PostedWhseShptLine; "Posted Source Document")
                {
                    IncludeCaption = true;
                }
                column(PstdSourceNo_PostedWhseShptLine; "Posted Source No.")
                {
                    IncludeCaption = true;
                }
                column(No_PostedWhseShptLine; "No.")
                {
                    IncludeCaption = true;
                }
                column(LineNo_PostedWhseShptLine; "Line No.")
                {
                    IncludeCaption = true;
                }
                column(PostedWhseShptLinePostDtCaption; PostedWhseShptLinePostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Posted Whse. Shipment Line" then
                        CurrReport.Break();

                    SetCurrentKey("Posted Source No.", "Posting Date");
                    SetFilter("Posted Source No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Posted Whse. Receipt Line"; "Posted Whse. Receipt Line")
            {
                DataItemTableView = SORTING("Posted Source No.", "Posting Date");
                column(PstDate_PostedWhseRcptLine; Format("Posting Date"))
                {
                }
                column(Desc_PostedWhseRcptLine; Description)
                {
                    IncludeCaption = true;
                }
                column(ItemNo_PostedWhseRcptLine; "Item No.")
                {
                    IncludeCaption = true;
                }
                column(UOMCode_PostedWhseRcptLine; "Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
                column(Qty_PostedWhseRcptLine; Quantity)
                {
                    IncludeCaption = true;
                }
                column(PstdSourceDoc_PostedWhseRcptLine; "Posted Source Document")
                {
                    IncludeCaption = true;
                }
                column(PstdSourceNo_PostedWhseRcptLine; "Posted Source No.")
                {
                    IncludeCaption = true;
                }
                column(No_PostedWhseRcptLine; "No.")
                {
                    IncludeCaption = true;
                }
                column(LineNo_PostedWhseRcptLine; "Line No.")
                {
                    IncludeCaption = true;
                }
                column(PostedWhseRcptLinePostDtCaption; PostedWhseRcptLinePostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Posted Whse. Receipt Line" then
                        CurrReport.Break();

                    SetCurrentKey("Posted Source No.", "Posting Date");
                    SetFilter("Posted Source No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = SORTING("G/L Account No.", "Posting Date");
                column(PostingDate_GLEntry; Format("Posting Date"))
                {
                }
                column(DocNo_GLEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Description_GLEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(VATAmount_GLEntry; "VAT Amount")
                {
                    IncludeCaption = true;
                }
                column(DebitAmount_GLEntry; "Debit Amount")
                {
                    IncludeCaption = true;
                }
                column(CreditAmount_GLEntry; "Credit Amount")
                {
                    IncludeCaption = true;
                }
                column(EntryNo_GLEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(Quantity_GLEntry; Quantity)
                {
                    IncludeCaption = true;
                }
                column(GLAccNo_GLEntry; "G/L Account No.")
                {
                    IncludeCaption = true;
                }
                column(GLEntryPostDtCaption; GLEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"G/L Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(PostDate_VATEntry; Format("Posting Date"))
                {
                }
                column(DocNo_VATEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Amount_VATEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(EntryNo_VATEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(VATEntryPostDtCaption; VATEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"VAT Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.");
                column(CustLedgEntryCurrCaption; CurrencyCaption)
                {
                }
                column(CustLedgEntry__Entry_No__; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(Amount_CustLedgEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(PstDate_CustLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_CustLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_CustLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(RemainAmt_CustLedgEntry; "Remaining Amount")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_CustLedgEntry; "Currency Code")
                {
                    IncludeCaption = true;
                }
                column(CustNo_CustLedgEntry; "Customer No.")
                {
                    IncludeCaption = true;
                }
                column(AmtLCY_CustLedgEntry; "Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(RemainAmtLCY_CustLedgEntry; "Remaining Amt. (LCY)")
                {
                    IncludeCaption = true;
                }
                column(CustLedgEntryPostDtCaption; CustLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Cust. Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
            {
                DataItemTableView = SORTING("Document No.");
                column(DtldCustLedgEntryCurrCaption; CurrencyCaption)
                {
                }
                column(PstDate_DtldCustLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_DtldCustLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(DebitAmt_DtldCustLedgEntry; "Debit Amount")
                {
                    IncludeCaption = true;
                }
                column(CreditAmt_DtldCustLedgEntry; "Credit Amount")
                {
                    IncludeCaption = true;
                }
                column(EntryNo_DtldCustLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(DocType_DtldCustLedgEntry; "Document Type")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_DtldCustLedgEntry; "Currency Code")
                {
                }
                column(DebitAmtLCY_DtldCustLedgEntry; "Debit Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(CreditAmtLCY_DtldCustLedgEntry; "Credit Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(DtldCustLedgEntryPostDtCaption; DtldCustLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Detailed Cust. Ledg. Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Reminder/Fin. Charge Entry"; "Reminder/Fin. Charge Entry")
            {
                DataItemTableView = SORTING(Type, "No.");
                column(EntryNo_ReminderEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(PstDate_ReminderEntry; Format("Posting Date"))
                {
                }
                column(DocNo_ReminderEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(ReminderLevel_ReminderEntry; "Reminder Level")
                {
                    IncludeCaption = true;
                }
                column(IntrstAmt_ReminderEntry; "Interest Amount")
                {
                    IncludeCaption = true;
                }
                column(RemainAmt_ReminderEntry; "Remaining Amount")
                {
                    IncludeCaption = true;
                }
                column(ReminderEntryPostDtCaption; ReminderEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Reminder/Fin. Charge Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.");
                column(VendLedgEntryCurrCaption; CurrencyCaption)
                {
                }
                column(EntryNo_VenLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(PstDate_VenLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_VenLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_VenLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Amt_VenLedgEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(RemainAmt_VenLedgEntry; "Remaining Amount")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_VenLedgEntry; "Currency Code")
                {
                }
                column(AmtLCY_VenLedgEntry; "Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(RemainAmtLCY_VenLedgEntry; "Remaining Amt. (LCY)")
                {
                    IncludeCaption = true;
                }
                column(VendLedgEntryPostDtCaption; VendLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Vendor Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
            {
                DataItemTableView = SORTING("Document No.");
                column(DtldVendLedgEntryCurrCaption; CurrencyCaption)
                {
                }
                column(PstDate_DtldVenLedgEntry; Format("Posting Date"))
                {
                }
                column(DebitAmt_DtldVenLedgEntry; "Debit Amount")
                {
                    IncludeCaption = true;
                }
                column(CreditAmt_DtldVenLedgEntry; "Credit Amount")
                {
                    IncludeCaption = true;
                }
                column(EntryNo_DtldVenLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(DocType_DtldVenLedgEntry; "Document Type")
                {
                    IncludeCaption = true;
                }
                column(DocNo_DtldVenLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_DtldVenLedgEntry; "Currency Code")
                {
                }
                column(DebitAmtLCY_DtldVenLedgEntry; "Debit Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(CreditAmtLCY_DtldVenLedgEntry; "Credit Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(DtldVendLedgEntryPostDtCaption; DtldVendLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Detailed Vendor Ledg. Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.");
                column(EntryNo_ItemLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(PstDate_ItemLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_ItemLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_ItemLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Qty_ItemLedgEntry; Quantity)
                {
                    IncludeCaption = true;
                }
                column(RemainQty_ItemLedgEntry; "Remaining Quantity")
                {
                    IncludeCaption = true;
                }
                column(Open_ItemLedgEntry; Format(Open))
                {
                }
                column(ItemLedgEntryPostDtCaption; ItemLedgEntryPostDtCaptionLbl)
                {
                }
                column(ItemLedEntryOpenCaption; CaptionClassTranslate(FieldCaption(Open)))
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Item Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemTableView = SORTING("Document No.");
                column(PstDate_ValueEntry; Format("Posting Date"))
                {
                }
                column(DocNo_ValueEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_ValueEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(EntryNo_ValueEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(ValuedQty_ValueEntry; "Valued Quantity")
                {
                    IncludeCaption = true;
                }
                column(InvoicedQty_ValueEntry; "Invoiced Quantity")
                {
                    IncludeCaption = true;
                }
                column(ValueEntryPostDtCaption; ValueEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Value Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Phys. Inventory Ledger Entry"; "Phys. Inventory Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(EntryNo_PhysInvtLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(PstDate_PhysInvtLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_PhysInvtLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_PhysInvtLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Qty_PhysInvtLedgEntry; Quantity)
                {
                    IncludeCaption = true;
                }
                column(UnitAmt_PhysInvtLedgEntry; "Unit Amount")
                {
                    IncludeCaption = true;
                }
                column(UnitCost_PhysInvtLedgEntry; "Unit Cost")
                {
                    IncludeCaption = true;
                }
                column(Amt_PhysInvtLedgEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(PhysInvtLedgEntryPostDtCaption; PhysInvtLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Phys. Inventory Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Res. Ledger Entry"; "Res. Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(PstDate_ResLedgEntry; Format("Posting Date"))
                {
                }
                column(Desc_ResLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(DocNo_ResLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(EntryNo_ResLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(Qty_ResLedgEntry; Quantity)
                {
                    IncludeCaption = true;
                }
                column(UnitCost_ResLedgEntry; "Unit Cost")
                {
                    IncludeCaption = true;
                }
                column(UnitPrice_ResLedgEntry; "Unit Price")
                {
                    IncludeCaption = true;
                }
                column(ResLedgEntryPostDtCaption; ResLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Res. Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Job Ledger Entry"; "Job Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(PstDate_JobLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_JobLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_JobLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Qty_JobLedgEntry; Quantity)
                {
                    IncludeCaption = true;
                }
                column(UnitCostLCY_JobLedgEntry; "Unit Cost (LCY)")
                {
                    IncludeCaption = true;
                }
                column(UnitPriceLCY_JobLedgEntry; "Unit Price (LCY)")
                {
                    IncludeCaption = true;
                }
                column(EntryNo_JobLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(JobLedgEntryPostDtCaption; JobLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Job Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(BankAccLedgEntryCurrCaption; CurrencyCaption)
                {
                }
                column(EntryNo_BankAccLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(PstDate_BankAccLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_BankAccLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_BankAccLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(DebitAmt_BankAccLedgEntry; "Debit Amount")
                {
                    IncludeCaption = true;
                }
                column(CreditAmt_BankAccLedgEntry; "Credit Amount")
                {
                    IncludeCaption = true;
                }
                column(CurrCode_BankAccLedgEntry; "Currency Code")
                {
                    IncludeCaption = true;
                }
                column(DebitAmtLCY_BankAccLedgEntry; "Debit Amount (LCY)")
                {
                    IncludeCaption = false;
                }
                column(CreditAmtLCY_BankAccLedgEntry; "Credit Amount (LCY)")
                {
                    IncludeCaption = false;
                }
                column(BankAccLedgEntryPostDtCaption; BankAccLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Bank Account Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Check Ledger Entry"; "Check Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(DocNo_CheckLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(PstDate_CheckLedgEntry; Format("Posting Date"))
                {
                }
                column(Desc_CheckLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Amt_CheckLedgEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(Open_CheckLedgEntry; Open)
                {
                    IncludeCaption = true;
                }
                column(EntryNo_CheckLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(CheckDate_CheckLedgEntry; Format("Check Date"))
                {
                }
                column(CheckNo_CheckLedgEntry; "Check No.")
                {
                    IncludeCaption = true;
                }
                column(CheckType_CheckLedgEntry; "Check Type")
                {
                    IncludeCaption = true;
                }
                column(CheckLedgEntryOpenCaption; FieldCaption(Open))
                {
                }
                column(CheckLedgEntryPostDtCaption; CheckLedgEntryPostDtCaptionLbl)
                {
                }
                column(CheckLedgEntryCheckDtCaption; CheckLedgEntryCheckDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Check Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("FA Ledger Entry"; "FA Ledger Entry")
            {
                DataItemTableView = SORTING("Document Type", "Document No.");
                column(PstDate_FALedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_FALedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_FALedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(EntryNo_FALedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(Amt_FALedgEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(AmtLCY_FALedgEntry; "Amount (LCY)")
                {
                    IncludeCaption = false;
                }
                column(FALedgEntryPostDtCaption; FALedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"FA Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Maintenance Ledger Entry"; "Maintenance Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(EntryNo_MaintLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(PostingDate_MaintLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_MaintLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_MaintLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Amt_MaintLedgEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(AmtLCY_MaintLedgEntry; "Amount (LCY)")
                {
                    IncludeCaption = false;
                }
                column(MaintenanceLedgEntryPostDtCaption; MaintenanceLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Maintenance Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Ins. Coverage Ledger Entry"; "Ins. Coverage Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(PstDate_InsCoverageLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_InsCoverageLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_InsCoverageLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Amt_InsCoverageLedgEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(EntryNo_InsCoverageLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(InsurNo_InsCoverageLedgEntry; "Insurance No.")
                {
                    IncludeCaption = true;
                }
                column(InsCoverageLedgEntryPostDtCaption; InsCoverageLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Ins. Coverage Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Capacity Ledger Entry"; "Capacity Ledger Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(EntryNo_CapLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(PstDate_CapLedgEntry; Format("Posting Date"))
                {
                }
                column(DocNo_CapLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_CapLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Qty_CapLedgEntry; Quantity)
                {
                    IncludeCaption = true;
                }
                column(CapLedgEntryPostDtCaption; CapLedgEntryPostDtCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Capacity Ledger Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                end;
            }
            dataitem("Warehouse Entry"; "Warehouse Entry")
            {
                DataItemTableView = SORTING("Reference No.", "Registering Date");
                column(EntryNo_WhseEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(RegDate_WhseEntry; Format("Registering Date"))
                {
                }
                column(ItemNo_WhseEntry; "Item No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_WhseEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(Qty_WhseEntry; Quantity)
                {
                    IncludeCaption = true;
                }
                column(RefNo_WhseEntry; "Reference No.")
                {
                    IncludeCaption = true;
                }
                column(UOMCode_WhseEntry; "Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
                column(WhseEntryRegisteringDateCaption; WhseEntryRegisteringDateCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if DocEntry."Table ID" <> DATABASE::"Warehouse Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Reference No.", "Registering Date");
                    SetFilter("Reference No.", DocNoFilter);
                    SetFilter("Registering Date", PostingDateFilter);
                end;
            }
            dataitem("Issued Bank Statement Header"; "Issued Bank Statement Header")
            {
                DataItemTableView = SORTING("No.");
                column(No_IssuedBankStatementHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(BankAccountNo_IssuedBankStatementHeader; "Bank Account No.")
                {
                    IncludeCaption = true;
                }
                column(BankAccountName_IssuedBankStatementHeader; "Bank Account Name")
                {
                    IncludeCaption = true;
                }
                column(DocumentDate_IssuedBankStatementHeader; Format("Document Date"))
                {
                }
                column(CurrencyCode_IssuedBankStatementHeader; "Currency Code")
                {
                    IncludeCaption = true;
                }
                column(Amount_IssuedBankStatementHeader; Amount)
                {
                    IncludeCaption = true;
                }
                column(Debit_IssuedBankStatementHeader; Debit)
                {
                    IncludeCaption = true;
                }
                column(Credit_IssuedBankStatementHeader; Credit)
                {
                    IncludeCaption = true;
                }
                column(IssuedBankStmtHdrCurrCaption; CurrencyCaption)
                {
                }
                column(IssuedBankStmtHdrDocDateCaption; IssuedBankStmtHdrDocDateCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    // NAVCZ
                    if DocEntry."Table ID" <> DATABASE::"Issued Bank Statement Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Document Date", PostingDateFilter);
                    // NAVCZ
                end;
            }
            dataitem("Issued Payment Order Header"; "Issued Payment Order Header")
            {
                DataItemTableView = SORTING("No.");
                column(No_IssuedPaymentOrderHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(BankAccountNo_IssuedPaymentOrderHeader; "Bank Account No.")
                {
                    IncludeCaption = true;
                }
                column(BankAccountName_IssuedPaymentOrderHeader; "Bank Account Name")
                {
                    IncludeCaption = true;
                }
                column(DocumentDate_IssuedPaymentOrderHeader; Format("Document Date"))
                {
                }
                column(CurrencyCode_IssuedPaymentOrderHeader; "Currency Code")
                {
                    IncludeCaption = true;
                }
                column(Amount_IssuedPaymentOrderHeader; Amount)
                {
                    IncludeCaption = true;
                }
                column(Debit_IssuedPaymentOrderHeader; Debit)
                {
                    IncludeCaption = true;
                }
                column(Credit_IssuedPaymentOrderHeader; Credit)
                {
                    IncludeCaption = true;
                }
                column(IssuedPmtOrdHdrCurrCaption; CurrencyCaption)
                {
                }
                column(IssuedPmtOrdHdrDocDateCaption; IssuedPmtOrdHdrDocDateCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    // NAVCZ
                    if DocEntry."Table ID" <> DATABASE::"Issued Payment Order Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Document Date", PostingDateFilter);
                    // NAVCZ
                end;
            }
            dataitem("Posted Cash Document Header"; "Posted Cash Document Header")
            {
                DataItemTableView = SORTING("No.", "Posting Date");
                column(CashDeskNo_PostedCashDocumentHeader; "Cash Desk No.")
                {
                    IncludeCaption = true;
                }
                column(No_PostedCashDocumentHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(PostingDate_PostedCashDocumentHeader; Format("Posting Date"))
                {
                }
                column(Amount_PostedCashDocumentHeader; Amount)
                {
                    IncludeCaption = true;
                }
                column(CashDocumentType_PostedCashDocumentHeader; "Cash Document Type")
                {
                    IncludeCaption = true;
                }
                column(CurrencyCode_PostedCashDocumentHeader; "Currency Code")
                {
                    IncludeCaption = true;
                }
                column(AmountIncludingVAT_PostedCashDocumentHeader; "Amount Including VAT")
                {
                    IncludeCaption = true;
                }
                column(PaymentPurpose_PostedCashDocumentHeader; "Payment Purpose")
                {
                    IncludeCaption = true;
                }
                column(PostedCashDocHdrCurrCaption; CurrencyCaption)
                {
                }
                column(PostedCashDocHdrPostDateCaption; PostedCashDocHdrPostDateCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    // NAVCZ
                    if DocEntry."Table ID" <> DATABASE::"Posted Cash Document Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.", "Posting Date");
                    if CashDeskNo <> '' then
                        SetRange("Cash Desk No.", CashDeskNo);
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                    // NAVCZ
                end;
            }
            dataitem("Sales Advance Letter Entry"; "Sales Advance Letter Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(EntryNo_SalesAdvanceLetterEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(LetterNo_SalesAdvanceLetterEntry; "Letter No.")
                {
                    IncludeCaption = true;
                }
                column(DocumentNo_SalesAdvanceLetterEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(PostingDate_SalesAdvanceLetterEntry; Format("Posting Date"))
                {
                }
                column(CustomerNo_SalesAdvanceLetterEntry; "Customer No.")
                {
                    IncludeCaption = true;
                }
                column(Amount_SalesAdvanceLetterEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(CurrencyCode_SalesAdvanceLetterEntry; "Currency Code")
                {
                    IncludeCaption = true;
                }
                column(VATBaseAmountLCY_SalesAdvanceLetterEntry; "VAT Base Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(VATAmountLCY_SalesAdvanceLetterEntry; "VAT Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(VATBaseAmount_SalesAdvanceLetterEntry; "VAT Base Amount")
                {
                    IncludeCaption = true;
                }
                column(VATAmount_SalesAdvanceLetterEntry; "VAT Amount")
                {
                    IncludeCaption = true;
                }
                column(SalesAdvLetterEntryCurrCaption; CurrencyCaption)
                {
                }
                column(SalesAdvLetterEntryPostDateCaption; SalesAdvLetterEntryPostDateCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    // NAVCZ
                    if DocEntry."Table ID" <> DATABASE::"Sales Advance Letter Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                    // NAVCZ
                end;
            }
            dataitem("Purch. Advance Letter Entry"; "Purch. Advance Letter Entry")
            {
                DataItemTableView = SORTING("Document No.", "Posting Date");
                column(EntryNo_PurchAdvanceLetterEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(LetterNo_PurchAdvanceLetterEntry; "Letter No.")
                {
                    IncludeCaption = true;
                }
                column(DocumentNo_PurchAdvanceLetterEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(PostingDate_PurchAdvanceLetterEntry; Format("Posting Date"))
                {
                }
                column(VendorNo_PurchAdvanceLetterEntry; "Vendor No.")
                {
                    IncludeCaption = true;
                }
                column(Amount_PurchAdvanceLetterEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(CurrencyCode_PurchAdvanceLetterEntry; "Currency Code")
                {
                    IncludeCaption = true;
                }
                column(VATBaseAmountLCY_PurchAdvanceLetterEntry; "VAT Base Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(VATAmountLCY_PurchAdvanceLetterEntry; "VAT Amount (LCY)")
                {
                    IncludeCaption = true;
                }
                column(VATBaseAmount_PurchAdvanceLetterEntry; "VAT Base Amount")
                {
                    IncludeCaption = true;
                }
                column(VATAmount_PurchAdvanceLetterEntry; "VAT Amount")
                {
                    IncludeCaption = true;
                }
                column(PurchAdvLetterEntryCurrCaption; CurrencyCaption)
                {
                }
                column(PurchAdvLetterEntryPostDateCaption; PurchAdvLetterEntryPostDateCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    // NAVCZ
                    if DocEntry."Table ID" <> DATABASE::"Purch. Advance Letter Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.", "Posting Date");
                    SetFilter("Document No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                    // NAVCZ
                end;
            }
            dataitem("Posted Credit Header"; "Posted Credit Header")
            {
                DataItemTableView = SORTING("No.");
                column(No_PostedCreditHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(Description_PostedCreditHeader; Description)
                {
                    IncludeCaption = true;
                }
                column(CompanyNo_PostedCreditHeader; "Company No.")
                {
                    IncludeCaption = true;
                }
                column(PostingDate_PostedCreditHeader; Format("Posting Date"))
                {
                }
                column(BalanceLCY_PostedCreditHeader; "Balance (LCY)")
                {
                    IncludeCaption = true;
                }
                column(Type_PostedCreditHeader; Type)
                {
                    IncludeCaption = true;
                }
                column(PostedCreditHdrPostDateCaption; PostedCreditHdrPostDateCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    // NAVCZ
                    if DocEntry."Table ID" <> DATABASE::"Posted Credit Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                    // NAVCZ
                end;
            }
            dataitem("Posted Invt. Put-away Header"; "Posted Invt. Put-away Header")
            {
                DataItemTableView = SORTING("No.");
                column(No_PostedInvtPutawayHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(LocationCode_PostedInvtPutawayHeader; "Location Code")
                {
                    IncludeCaption = true;
                }
                column(PostingDate_PostedInvtPutawayHeader; Format("Posting Date"))
                {
                }
                column(SourceNo_PostedInvtPutawayHeader; "Source No.")
                {
                    IncludeCaption = true;
                }
                column(DestinationNo_PostedInvtPutawayHeader; "Destination No.")
                {
                    IncludeCaption = true;
                }
                column(ExternalDocumentNo_PostedInvtPutawayHeader; "External Document No.")
                {
                    IncludeCaption = true;
                }
                column(ExpectedReceiptDate_PostedInvtPutawayHeader; "Expected Receipt Date")
                {
                    IncludeCaption = true;
                }
                column(PostedInvtPutAwayHdrPostDateCaption; PostedInvtPutAwayHdrPostDateCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    // NAVCZ
                    if DocEntry."Table ID" <> DATABASE::"Posted Invt. Put-away Header" then
                        CurrReport.Break();

                    SetCurrentKey("No.");
                    SetFilter("No.", DocNoFilter);
                    SetFilter("Posting Date", PostingDateFilter);
                    // NAVCZ
                end;
            }
            dataitem("EET Entry"; "EET Entry")
            {
                DataItemTableView = SORTING("Document No.");
                column(DocumentNo_EETEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Description_EETEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(BusinessPremisesCode_EETEntry; "Business Premises Code")
                {
                    IncludeCaption = true;
                }
                column(CashRegisterCode_EETEntry; "Cash Register Code")
                {
                    IncludeCaption = true;
                }
                column(EETStatus_EETEntry; "EET Status")
                {
                    IncludeCaption = true;
                }
                column(TotalSalesAmount_EETEntry; "Total Sales Amount")
                {
                    IncludeCaption = true;
                }
                column(EntryNo_EETEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }

                trigger OnPreDataItem()
                begin
                    // NAVCZ
                    if DocEntry."Table ID" <> DATABASE::"EET Entry" then
                        CurrReport.Break();

                    SetCurrentKey("Document No.");
                    SetFilter("Document No.", DocNoFilter);
                    // NAVCZ
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not DocEntry.Find('-') then
                        CurrReport.Break();
                end else
                    if DocEntry.Next() = 0 then
                        CurrReport.Break();
                CurrencyCaptionRBC := Text003;
            end;

            trigger OnPreDataItem()
            begin
                if not PrintAmountsInLCY then
                    CurrencyCaption := Text003
                else
                    CurrencyCaption := '';
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
                    field(PrintAmountsInLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if amounts in the report are displayed in LCY. If you leave the check box blank, amounts are shown in foreign currencies.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        DocEntry: Record "Document Entry" temporary;
        CurrExchRate: Record "Currency Exchange Rate";
        DocNoFilter: Text;
        PostingDateFilter: Text;
        Text001: Label 'Document No. : ';
        Text002: Label 'Posting Date : ';
        PrintAmountsInLCY: Boolean;
        CurrencyCaption: Text[30];
        Text003: Label 'Currency Code';
        CurrencyCaptionRBC: Text[30];
        DocEntriesCaptionLbl: Label 'Document Entries';
        PageNoCaptionLbl: Label 'Page';
        NavigateFiltersCaptionLbl: Label 'Navigate Filters';
        DocEntryNoofRecordsCptnLbl: Label 'No. of Records';
        DocEntryTableNameCaptionLbl: Label 'Table Name';
        ServLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        WarrantyLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        ServShptHeaderPostDateCaptionLbl: Label 'Posting Date';
        SalesShptHeaderPostingDtCaptionLbl: Label 'Posting Date';
        SalesInvHeaderPostDateCaptionLbl: Label 'Posting Date';
        ReturnRcptHeaderPostDtCaptionLbl: Label 'Posting Date';
        SalesCrMemoHeaderPostDtCaptionLbl: Label 'Posting Date';
        IssuedReminderHeaderPostDtCaptionLbl: Label 'Posting Date';
        IssuedFinChgMemoHeaderPostDateCaptionLbl: Label 'Posting Date';
        PurchRcptHeaderPostDtCaptionLbl: Label 'Posting Date';
        PurchInvHeaderPostDtCaptionLbl: Label 'Posting Date';
        ReturnShptHeaderPostDtCaptionLbl: Label 'Posting Date';
        PurchCrMemoHdrPostDtCaptionLbl: Label 'Posting Date';
        TransShptHeaderPostDtCaptionLbl: Label 'Posting Date';
        TransRcptHeaderPostDtCaptionLbl: Label 'Posting Date';
        PostedWhseShptLinePostDtCaptionLbl: Label 'Posting Date';
        PostedWhseRcptLinePostDtCaptionLbl: Label 'Posting Date';
        GLEntryPostDtCaptionLbl: Label 'Posting Date';
        VATEntryPostDtCaptionLbl: Label 'Posting Date';
        CustLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        DtldCustLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        ReminderEntryPostDtCaptionLbl: Label 'Posting Date';
        VendLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        DtldVendLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        ItemLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        ValueEntryPostDtCaptionLbl: Label 'Posting Date';
        PhysInvtLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        ResLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        JobLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        BankAccLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        CheckLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        CheckLedgEntryCheckDtCaptionLbl: Label 'Check Date';
        FALedgEntryPostDtCaptionLbl: Label 'Posting Date';
        MaintenanceLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        InsCoverageLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        CapLedgEntryPostDtCaptionLbl: Label 'Posting Date';
        WhseEntryRegisteringDateCaptionLbl: Label 'Registering Date';
        IssuedBankStmtHdrDocDateCaptionLbl: Label 'Document Date';
        IssuedPmtOrdHdrDocDateCaptionLbl: Label 'Document Date';
        PostedCashDocHdrPostDateCaptionLbl: Label 'Posting Date';
        SalesAdvLetterEntryPostDateCaptionLbl: Label 'Posting Date';
        PurchAdvLetterEntryPostDateCaptionLbl: Label 'Posting Date';
        PostedCreditHdrPostDateCaptionLbl: Label 'Posting Date';
        PostedInvtPutAwayHdrPostDateCaptionLbl: Label 'Posting Date';
        CashDeskNo: Code[20];

    procedure TransferDocEntries(var NewDocEntry: Record "Document Entry")
    var
        TempDocumentEntry: Record "Document Entry";
    begin
        TempDocumentEntry := NewDocEntry;
        NewDocEntry.Reset();
        if NewDocEntry.Find('-') then
            repeat
                DocEntry := NewDocEntry;
                DocEntry.Insert();
            until NewDocEntry.Next() = 0;
        NewDocEntry := TempDocumentEntry;
    end;

    procedure TransferFilters(NewDocNoFilter: Text; NewPostingDateFilter: Text)
    begin
        DocNoFilter := NewDocNoFilter;
        PostingDateFilter := NewPostingDateFilter;
    end;

    [Scope('OnPrem')]
    procedure SetCashDesk(NewCashDeskNo: Code[20])
    begin
        CashDeskNo := NewCashDeskNo; // NAVCZ
    end;
}

