﻿namespace Microsoft.Foundation.Navigate;

using Microsoft.Assembly.History;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.CostAccounting.Ledger;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.HumanResources.Payables;
using Microsoft.Inventory.Counting.History;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Ledger;
using System.IO;
using System.Text;

page 344 Navigate
{
    AdditionalSearchTerms = 'find,search,analyze,navigate';
    ApplicationArea = Basic, Suite, FixedAssets, Service, CostAccounting;
    Caption = 'Find entries';
    DataCaptionExpression = GetCaptionText();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Document Entry";
    SourceTableTemporary = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(SearchBy)
            {
                Caption = 'Search By';
                ShowCaption = false;
                field(Scope; SearchBasedOn)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    Caption = 'Search By';

                    trigger OnValidate()
                    begin
                        UpdateFindByGroupsVisibility();
                    end;
                }
            }
            group(Document)
            {
                Caption = 'Document';
                Visible = DocumentVisible;
                ShowCaption = false;
                field(DocNoFilter; DocNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number of an entry that is used to find all documents that have the same document number. You can enter a new document number in this field to search for another set of documents.';

                    trigger OnValidate()
                    begin
                        SetDocNo(DocNoFilter);
                        ClearTrackingInfo();
                        ClearContactInfo();
                        DocNoFilterOnAfterValidate();
                        FilterSelectionChanged();
                    end;
                }
                field(PostingDateFilter; PostingDateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date for the document that you are searching for. You can insert a filter if you want to search for a certain interval of dates.';

                    trigger OnValidate()
                    begin
                        SetPostingDate(PostingDateFilter);
                        ClearTrackingInfo();
                        ClearContactInfo();
                        PostingDateFilterOnAfterValidate();
                        FilterSelectionChanged();
                    end;
                }
                field(ExtDocNo2; ExtDocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'External Document No.';
                    ToolTip = 'Specifies the document number assigned by the vendor.';

                    trigger OnValidate()
                    begin
                        ExtDocNoOnAfterValidate();
                        ClearTrackingInfo();
                        ClearContactInfo();
                        FilterSelectionChanged();
                    end;
                }
            }
            group("Business Contact")
            {
                Caption = 'Business Contact';
                ShowCaption = false;
                Visible = BusinessContactVisible;
                field(ContactType; ContactType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Business Contact Type';
                    ToolTip = 'Specifies if you want to search for customers, vendors, or bank accounts. Your choice determines the list that you can access in the Business Contact No. field.';

                    trigger OnValidate()
                    begin
                        SetDocNo('');
                        SetPostingDate('');
                        ClearTrackingInfo();
                        ContactTypeOnAfterValidate();
                        FilterSelectionChanged();
                    end;
                }
                field(ContactNo; ContactNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Business Contact No.';
                    ToolTip = 'Specifies the number of the customer, vendor, or bank account that you want to find entries for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Vend: Record Vendor;
                        Cust: Record Customer;
                        BankAccount: Record "Bank Account";
                    begin
                        case ContactType of
                            ContactType::Vendor:
                                if PAGE.RunModal(0, Vend) = ACTION::LookupOK then begin
                                    Text := Vend."No.";
                                    exit(true);
                                end;
                            ContactType::Customer:
                                if PAGE.RunModal(0, Cust) = ACTION::LookupOK then begin
                                    Text := Cust."No.";
                                    exit(true);
                                end;
                            ContactType::"Bank Account":
                                if PAGE.RunModal(0, BankAccount) = ACTION::LookupOK then begin
                                    Text := BankAccount."No.";
                                    exit(true);
                                end;
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SetDocNo('');
                        SetPostingDate('');
                        ClearTrackingInfo();
                        ContactNoOnAfterValidate();
                        FilterSelectionChanged();
                    end;
                }
                field(ExtDocNo; ExtDocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'External Document No.';
                    ToolTip = 'Specifies the document number assigned by the vendor.';

                    trigger OnValidate()
                    begin
                        SetDocNo('');
                        SetPostingDate('');
                        ClearTrackingInfo();
                        ExtDocNoOnAfterValidate();
                        FilterSelectionChanged();
                    end;
                }
            }
            group("Item Reference")
            {
                Caption = 'Item Reference';
                Visible = ItemReferenceVisible;
                ShowCaption = false;
                field(SerialNoFilter; SerialNoFilter)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Serial No.';
                    ToolTip = 'Specifies the posting date of the document when you have opened the Navigate window from the document. The entry''s document number is shown in the Document No. field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        SerialNoInformationList: Page "Serial No. Information List";
                    begin
                        Clear(SerialNoInformationList);
                        if SerialNoInformationList.RunModal() = ACTION::LookupOK then begin
                            Text := SerialNoInformationList.GetSelectionFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ClearInfo();
                        SerialNoFilterOnAfterValidate();
                        FilterSelectionChanged();
                    end;
                }
                field(LotNoFilter; LotNoFilter)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot No.';
                    ToolTip = 'Specifies the number that you want to find entries for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LotNoInformationList: Page "Lot No. Information List";
                    begin
                        Clear(LotNoInformationList);
                        if LotNoInformationList.RunModal() = ACTION::LookupOK then begin
                            Text := LotNoInformationList.GetSelectionFilter();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ClearInfo();
                        LotNoFilterOnAfterValidate();
                        FilterSelectionChanged();
                    end;
                }
            }
            group(Notification)
            {
                Caption = 'Notification';
                InstructionalText = 'The filter has been changed. Choose Find to update the list of related entries.';
                Visible = FilterSelectionChangedTxtVisible;
            }
            repeater(Control16)
            {
                Editable = false;
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table that the entry is stored in.';
                    Visible = false;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Related Entries';
                    ToolTip = 'Specifies the name of the table where the Navigate facility has found entries with the selected document number and/or posting date.';

                    trigger OnDrillDown()
                    begin
                        ShowRecords();
                    end;
                }
                field("No. of Records"; Rec."No. of Records")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Entries';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of documents that the Navigate facility has found in the table with the selected entries.';

                    trigger OnDrillDown()
                    begin
                        ShowRecords();
                    end;
                }
            }
            group(Source)
            {
                Caption = 'Source';
                field(DocType; DocType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Type';
                    Editable = false;
                    Enabled = DocTypeEnable;
                    ToolTip = 'Specifies the type of the selected document. Leave the Document Type field blank if you want to search by posting date. The entry''s document number is shown in the Document No. field.';
                }
                field(SourceType; SourceType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Type';
                    Editable = false;
                    Enabled = SourceTypeEnable;
                    ToolTip = 'Specifies the source type of the selected document or remains blank if you search by posting date. The entry''s document number is shown in the Document No. field.';
                }
                field(SourceNo; SourceNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source No.';
                    Editable = false;
                    Enabled = SourceNoEnable;
                    ToolTip = 'Specifies the source number of the selected document. The entry''s document number is shown in the Document No. field.';
                }
                field(SourceName; SourceName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Name';
                    Editable = false;
                    Enabled = SourceNameEnable;
                    ToolTip = 'Specifies the source name on the selected entry. The entry''s document number is shown in the Document No. field.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Process)
            {
                Caption = 'Process';
                action(Show)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Show Related Entries';
                    Enabled = ShowEnable;
                    Image = ViewDocumentLine;
                    ToolTip = 'View the related entries of the type that you have chosen.';

                    trigger OnAction()
                    begin
                        ShowRecords();
                    end;
                }
                action(Find)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Fi&nd';
                    Image = Find;
                    ToolTip = 'Apply a filter to search on this page.';

                    trigger OnAction()
                    begin
                        FindPush();
                        FilterSelectionChangedTxtVisible := false;
                    end;
                }
                action(Print)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Print';
                    Ellipsis = true;
                    Enabled = PrintEnable;
                    Image = Print;
                    ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        ItemTrackingNavigate: Report "Item Tracking Navigate";
                        DocumentEntries: Report "Document Entries";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforePrint(Rec, SearchBasedOn, TempRecordBuffer, ItemTrackingFilters, DocNoFilter, PostingDateFilter, IsHandled);
                        if IsHandled then
                            exit;

                        if ItemTrackingSearch() then begin
                            Clear(ItemTrackingNavigate);
                            ItemTrackingNavigate.TransferDocEntries(Rec);
                            ItemTrackingNavigate.TransferRecordBuffer(TempRecordBuffer);
                            ItemTrackingNavigate.SetTrackingFilters(ItemTrackingFilters);
                            ItemTrackingNavigate.Run();
                        end else begin
                            DocumentEntries.TransferDocEntries(Rec);
                            DocumentEntries.TransferFilters(DocNoFilter, PostingDateFilter);
                            DocumentEntries.Run();
                        end;
                    end;
                }
            }
            group(FindGroup)
            {
                Caption = 'Find by';
                action(FindByDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find by Document';
                    Image = Documents;
                    ToolTip = 'View entries based on the specified document number.';
                    Visible = false;

                    trigger OnAction()
                    begin
                        SearchBasedOn := SearchBasedOn::Document;
                        UpdateFindByGroupsVisibility();
                    end;
                }
                action(FindByBusinessContact)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find by Business Contact';
                    Image = ContactPerson;
                    ToolTip = 'Filter entries based on the specified contact or contact type.';
                    Visible = false;

                    trigger OnAction()
                    begin
                        SearchBasedOn := SearchBasedOn::"Business Contact";
                        UpdateFindByGroupsVisibility();
                    end;
                }
                action(FindByItemReference)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find by Item Reference';
                    Image = ItemTracking;
                    ToolTip = 'Filter entries based on the specified serial number or lot number.';
                    Visible = false;

                    trigger OnAction()
                    begin
                        SearchBasedOn := SearchBasedOn::"Item Reference";
                        UpdateFindByGroupsVisibility();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Show_Promoted; Show)
                {
                }
                actionref(Find_Promoted; Find)
                {
                }
                actionref(Print_Promoted; Print)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Find By', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnInit()
    begin
        SourceNameEnable := true;
        SourceNoEnable := true;
        SourceTypeEnable := true;
        DocTypeEnable := true;
        PrintEnable := true;
        ShowEnable := true;
        DocumentVisible := true;
        SearchBasedOn := SearchBasedOn::Document;

        OnAfterOnInit(Rec);
    end;

    trigger OnOpenPage()
    begin
        UpdateFindByGroupsVisibility();
        UpdateForm := true;
        FindRecordsOnOpen();
    end;

    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        BankAccount: Record "Bank Account";
        Text000: Label 'The business contact type was not specified.';
        Text001: Label 'There are no posted records with this external document number.';
        Text002: Label 'Counting records...';
        Text013: Label 'There are no posted records with this document number.';
        Text014: Label 'There are no posted records with this combination of document number and posting date.';
        Text015: Label 'The search results in too many external documents. Specify a business contact no.';
        Text016: Label 'The search results in too many external documents. Use Navigate from the relevant ledger entries.';
        PostedSalesInvoiceTxt: Label 'Posted Sales Invoice';
        PostedSalesCreditMemoTxt: Label 'Posted Sales Credit Memo';
        PostedSalesShipmentTxt: Label 'Posted Sales Shipment';
        IssuedReminderTxt: Label 'Issued Reminder';
        IssuedFinanceChargeMemoTxt: Label 'Issued Finance Charge Memo';
        PostedPurchaseInvoiceTxt: Label 'Posted Purchase Invoice';
        PostedPurchaseCreditMemoTxt: Label 'Posted Purchase Credit Memo';
        PostedPurchaseReceiptTxt: Label 'Posted Purchase Receipt';
        PostedReturnReceiptTxt: Label 'Posted Return Receipt';
        PostedReturnShipmentTxt: Label 'Posted Return Shipment';
        PostedTransferShipmentTxt: Label 'Posted Transfer Shipment';
        PostedTransferReceiptTxt: Label 'Posted Transfer Receipt';
        PostedDirectTransferTxt: Label 'Posted Direct Transfer';
        SalesQuoteTxt: Label 'Sales Quote';
        SalesOrderTxt: Label 'Sales Order';
        SalesInvoiceTxt: Label 'Sales Invoice';
        PurchaseQuoteTxt: Label 'Purchase Quote';
        PurchaseOrderTxt: Label 'Purchase Order';
        PurchaseInvoiceTxt: Label 'Purchase Invoice';
        SalesReturnOrderTxt: Label 'Sales Return Order';
        SalesCreditMemoTxt: Label 'Sales Credit Memo';
        PostedAssemblyOrderTxt: Label 'Posted Assembly Order';
        PostedServiceInvoiceTxt: Label 'Posted Service Invoice';
        PostedServiceCreditMemoTxt: Label 'Posted Service Credit Memo';
        PostedServiceShipmentTxt: Label 'Posted Service Shipment';
        ServiceOrderTxt: Label 'Service Order';
        ServiceInvoiceTxt: Label 'Service Invoice';
        ServiceCreditMemoTxt: Label 'Service Credit Memo';
        ProductionOrderTxt: Label 'Production Order';
        PostedGenJournalLineTxt: Label 'Posted Gen. Journal Line';
        [SecurityFiltering(SecurityFilter::Filtered)]
        Cust: Record Customer;
        [SecurityFiltering(SecurityFilter::Filtered)]
        Vend: Record Vendor;
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServShptHeader: Record "Service Shipment Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServInvHeader: Record "Service Invoice Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        IssuedReminderHeader: Record "Issued Reminder Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PurchInvHeader: Record "Purch. Inv. Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ReturnShptHeader: Record "Return Shipment Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ProductionOrderHeader: Record "Production Order";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedAssemblyHeader: Record "Posted Assembly Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        TransShptHeader: Record "Transfer Shipment Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        TransRcptHeader: Record "Transfer Receipt Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        DirectTransHeader: Record "Direct Trans. Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLEntry: Record "G/L Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        VATEntry: Record "VAT Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        CustLedgEntry: Record "Cust. Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        VendLedgEntry: Record "Vendor Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        EmplLedgEntry: Record "Employee Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ItemLedgEntry: Record "Item Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ResLedgEntry: Record "Res. Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        JobLedgEntry: Record "Job Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        JobWIPEntry: Record "Job WIP Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        JobWIPGLEntry: Record "Job WIP G/L Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ValueEntry: Record "Value Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        CheckLedgEntry: Record "Check Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ReminderEntry: Record "Reminder/Fin. Charge Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        FALedgEntry: Record "FA Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        InsuranceCovLedgEntry: Record "Ins. Coverage Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        CapacityLedgEntry: Record "Capacity Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServLedgerEntry: Record "Service Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        WhseEntry: Record "Warehouse Entry";
        TempRecordBuffer: Record "Record Buffer" temporary;
        [SecurityFiltering(SecurityFilter::Filtered)]
        CostEntry: Record "Cost Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        IncomingDocument: Record "Incoming Document";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        [SecurityFiltering(SecurityFilter::Filtered)]
        IssuedDeliveryReminderHeader: Record "Issued Deliv. Reminder Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        DelivReminLedgerEntries: Record "Delivery Reminder Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedInvtRcptHeader: Record "Invt. Receipt Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedInvtShptHeader: Record "Invt. Shipment Header";
        ItemTrackingFilters: Record Item;
        NewItemTrackingSetup: Record "Item Tracking Setup";
        FilterTokens: Codeunit "Filter Tokens";
        ItemTrackingNavigateMgt: Codeunit "Item Tracking Navigate Mgt.";
        Window: Dialog;
        DocType: Text[100];
        SourceType: Text[30];
        SourceNo: Code[20];
        SourceName: Text[100];
        ShowEnable: Boolean;
        PrintEnable: Boolean;
        DocTypeEnable: Boolean;
        SourceTypeEnable: Boolean;
        SourceNoEnable: Boolean;
        SourceNameEnable: Boolean;
        UpdateForm: Boolean;
        DocumentVisible: Boolean;
        BusinessContactVisible: Boolean;
        ItemReferenceVisible: Boolean;
        FilterSelectionChangedTxtVisible: Boolean;
        PageCaptionTxt: Label 'Selected - %1';

    protected var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesShptHeader: Record "Sales Shipment Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesInvHeader: Record "Sales Invoice Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ReturnRcptHeader: Record "Return Receipt Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SQSalesHeader: Record "Sales Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SOSalesHeader: Record "Sales Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SISalesHeader: Record "Sales Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SROSalesHeader: Record "Sales Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SCMSalesHeader: Record "Sales Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PQPurchaseHeader: Record "Purchase Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        POPurchaseHeader: Record "Purchase Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PIPurchaseHeader: Record "Purchase Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlLine: Record "Gen. Journal Line";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SOServHeader: Record "Service Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SIServHeader: Record "Service Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SCMServHeader: Record "Service Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        ContactNo: Code[250];
        ContactType: Enum "Navigate Contact Type";
        SearchBasedOn: Enum "Navigate Search Type";
        DocExists: Boolean;
        DocNoFilter: Text;
        PostingDateFilter: Text;
        ExtDocNo: Code[250];
        NewDocNo: Code[20];
        NewPostingDate: Date;
        NewSourceRecVar: Variant;
        SerialNoFilter: Text;
        LotNoFilter: Text;
        PackageNoFilter: Text;

    procedure SetDoc(PostingDate: Date; DocNo: Code[20])
    begin
        NewDocNo := DocNo;
        NewPostingDate := PostingDate;
    end;

    procedure SetRec(SourceRecVar: Variant)
    begin
        NewSourceRecVar := SourceRecVar;

        OnAfterSetRec(NewSourceRecVar);
    end;

    procedure FindExtRecords()
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        VendLedgEntry2: Record "Vendor Ledger Entry";
        FoundRecords: Boolean;
        DateFilter2: Text;
        DocNoFilter2: Text;
    begin
        FoundRecords := false;
        case ContactType of
            ContactType::Vendor:
                begin
                    FindUnpostedPurchaseDocs(PQPurchaseHeader."Document Type"::Quote, PurchaseQuoteTxt, PQPurchaseHeader);
                    FindUnpostedPurchaseDocs(POPurchaseHeader."Document Type"::Order, PurchaseOrderTxt, POPurchaseHeader);
                    FindUnpostedPurchaseDocs(PIPurchaseHeader."Document Type"::Invoice, PurchaseInvoiceTxt, PIPurchaseHeader);

                    VendLedgEntry2.SetCurrentKey("External Document No.");
                    VendLedgEntry2.SetFilter("External Document No.", ExtDocNo);
                    VendLedgEntry2.SetFilter("Vendor No.", ContactNo);
                    if VendLedgEntry2.FindSet() then begin
                        repeat
                            MakeExtFilter(
                              DateFilter2,
                              VendLedgEntry2."Posting Date",
                              DocNoFilter2,
                              VendLedgEntry2."Document No.");
                        until VendLedgEntry2.Next() = 0;
                        SetPostingDate(DateFilter2);
                        SetDocNo(DocNoFilter2);
                        FindRecords();
                        FoundRecords := true;
                    end;
                end;
            ContactType::Customer:
                begin
                    Rec.DeleteAll();
                    Rec."Entry No." := 0;
                    FindUnpostedSalesDocs(SOSalesHeader."Document Type"::Quote, SalesQuoteTxt, SQSalesHeader);
                    FindUnpostedSalesDocs(SOSalesHeader."Document Type"::Order, SalesOrderTxt, SOSalesHeader);
                    FindUnpostedSalesDocs(SISalesHeader."Document Type"::Invoice, SalesInvoiceTxt, SISalesHeader);
                    FindUnpostedSalesDocs(SROSalesHeader."Document Type"::"Return Order", SalesReturnOrderTxt, SROSalesHeader);
                    FindUnpostedSalesDocs(SCMSalesHeader."Document Type"::"Credit Memo", SalesCreditMemoTxt, SCMSalesHeader);
                    if SalesShptHeader.ReadPermission() then begin
                        SalesShptHeader.Reset();
                        SalesShptHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
                        SalesShptHeader.SetFilter("Sell-to Customer No.", ContactNo);
                        SalesShptHeader.SetFilter("External Document No.", ExtDocNo);
                        InsertIntoDocEntry(Rec, Database::"Sales Shipment Header", PostedSalesShipmentTxt, SalesShptHeader.Count);
                    end;
                    if SalesInvHeader.ReadPermission() then begin
                        SalesInvHeader.Reset();
                        SalesInvHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
                        SalesInvHeader.SetFilter("Sell-to Customer No.", ContactNo);
                        SalesInvHeader.SetFilter("External Document No.", ExtDocNo);
                        OnFindExtRecordsOnAfterSetSalesInvoiceFilter(SalesInvHeader);
                        InsertIntoDocEntry(Rec, Database::"Sales Invoice Header", PostedSalesInvoiceTxt, SalesInvHeader.Count);
                    end;
                    if ReturnRcptHeader.ReadPermission() then begin
                        ReturnRcptHeader.Reset();
                        ReturnRcptHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
                        ReturnRcptHeader.SetFilter("Sell-to Customer No.", ContactNo);
                        ReturnRcptHeader.SetFilter("External Document No.", ExtDocNo);
                        InsertIntoDocEntry(Rec, Database::"Return Receipt Header", PostedReturnReceiptTxt, ReturnRcptHeader.Count);
                    end;
                    if SalesCrMemoHeader.ReadPermission() then begin
                        SalesCrMemoHeader.Reset();
                        SalesCrMemoHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
                        SalesCrMemoHeader.SetFilter("Sell-to Customer No.", ContactNo);
                        SalesCrMemoHeader.SetFilter("External Document No.", ExtDocNo);
                        OnFindExtRecordsOnAfterSetSalesCrMemoFilter(SalesCrMemoHeader);
                        InsertIntoDocEntry(Rec, Database::"Sales Cr.Memo Header", PostedSalesCreditMemoTxt, SalesCrMemoHeader.Count);
                    end;
                    FindUnpostedServDocs(SOServHeader."Document Type"::Order, ServiceOrderTxt, SOServHeader);
                    FindUnpostedServDocs(SIServHeader."Document Type"::Invoice, ServiceInvoiceTxt, SIServHeader);
                    FindUnpostedServDocs(SCMServHeader."Document Type"::"Credit Memo", ServiceCreditMemoTxt, SCMServHeader);
                    if ServShptHeader.ReadPermission() then
                        if ExtDocNo = '' then begin
                            ServShptHeader.Reset();
                            ServShptHeader.SetCurrentKey("Customer No.");
                            ServShptHeader.SetFilter("Customer No.", ContactNo);
                            InsertIntoDocEntry(Rec, Database::"Service Shipment Header", PostedServiceShipmentTxt, ServShptHeader.Count);
                        end;
                    if ServInvHeader.ReadPermission() then
                        if ExtDocNo = '' then begin
                            ServInvHeader.Reset();
                            ServInvHeader.SetCurrentKey("Customer No.");
                            ServInvHeader.SetFilter("Customer No.", ContactNo);
                            InsertIntoDocEntry(Rec, Database::"Service Invoice Header", PostedServiceInvoiceTxt, ServInvHeader.Count);
                        end;
                    if ServCrMemoHeader.ReadPermission() then
                        if ExtDocNo = '' then begin
                            ServCrMemoHeader.Reset();
                            ServCrMemoHeader.SetCurrentKey("Customer No.");
                            ServCrMemoHeader.SetFilter("Customer No.", ContactNo);
                            InsertIntoDocEntry(Rec, Database::"Service Cr.Memo Header", PostedServiceCreditMemoTxt, ServCrMemoHeader.Count);
                        end;

                    OnFindExtRecordsOnBeforeFormUpdate(Rec, SalesInvHeader, SalesCrMemoHeader);
                    UpdateFormAfterFindRecords();
                    FoundRecords := DocExists;
                end;
            else
                Error(Text000);
        end;

        OnAfterNavigateFindExtRecords(Rec, ContactType, ContactNo, ExtDocNo, FoundRecords);

        if not FoundRecords then begin
            SetSource(0D, '', '', 0, '');
            Message(Text001);
        end;
    end;

    procedure FindRecords()
    var
        DocType2: Text[100];
        DocNo2: Code[20];
        SourceType2: Integer;
        SourceNo2: Code[20];
        PostingDate: Date;
        IsSourceUpdated: Boolean;
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindRecordsProcedure(Rec, HideDialog, IsHandled);
        if IsHandled then
            exit;

        if (DocNoFilter = '') and (ExtDocNo = '') and (PostingDateFilter = '') then
            exit;
#if not CLEAN22
        OnBeforeFindRecords(HideDialog);
#endif
        if not HideDialog then
            Window.Open(Text002);
        Rec.Reset();
        Rec.DeleteAll();
        Rec."Entry No." := 0;

        FindPostedDocuments();
        FindLedgerEntries();
        FindUnpostedPurchaseDocs(PQPurchaseHeader."Document Type"::Quote, PurchaseQuoteTxt, PQPurchaseHeader);
        FindUnpostedPurchaseDocs(POPurchaseHeader."Document Type"::Order, PurchaseOrderTxt, POPurchaseHeader);
        FindUnpostedPurchaseDocs(PIPurchaseHeader."Document Type"::Invoice, PurchaseInvoiceTxt, PIPurchaseHeader);
        FindUnpostedSalesDocs(SQSalesHeader."Document Type"::Quote, SalesQuoteTxt, SQSalesHeader);
        FindUnpostedSalesDocs(SOSalesHeader."Document Type"::Order, SalesOrderTxt, SOSalesHeader);
        FindUnpostedSalesDocs(SISalesHeader."Document Type"::Invoice, SalesInvoiceTxt, SISalesHeader);
        FindUnpostedSalesDocs(SROSalesHeader."Document Type"::"Return Order", SalesReturnOrderTxt, SROSalesHeader);
        FindUnpostedSalesDocs(SCMSalesHeader."Document Type"::"Credit Memo", SalesCreditMemoTxt, SCMSalesHeader);
        FindUnpostedGenJnlLines(CopyStr(GenJnlLine.TableCaption(), 1, 100), GenJnlLine);

        OnAfterNavigateFindRecords(Rec, DocNoFilter, PostingDateFilter, NewSourceRecVar, ExtDocNo, HideDialog);
        DocExists := Rec.FindFirst();

        SetSource(0D, '', '', 0, '');
        if DocExists then begin
            OnBeforeFindRecordsSetSources(Rec, DocNoFilter, PostingDateFilter, ExtDocNo, IsSourceUpdated);
            if not IsSourceUpdated then begin
                SetSourceForService();
                SetSourceForSales();
                SetSourceForPurchase();
                SetSourceForServiceDoc();
            end;

            IsSourceUpdated := false;
            OnFindRecordsOnAfterSetSource(Rec, PostingDate, DocType2, DocNo2, SourceType2, SourceNo2, DocNoFilter, PostingDateFilter, IsSourceUpdated);
            if IsSourceUpdated then
                SetSource(PostingDate, DocType2, DocNo2, SourceType2, SourceNo2);
        end else begin
            IsHandled := false;
            OnFindRecordsOnBeforeMessagePostingDateFilter(Rec, PostingDateFilter, IsHandled);
            if not IsHandled then
                if PostingDateFilter = '' then
                    Message(Text013)
                else
                    Message(Text014);
        end;

        OnAfterFindRecords(Rec, DocNoFilter, PostingDateFilter);

        if UpdateForm then
            UpdateFormAfterFindRecords();

        if not HideDialog then
            Window.Close();
    end;

    local procedure FindLedgerEntries()
    begin
        FindGLEntries();
        FindVATEntries();
        FindCustEntries();
        FindReminderEntries();
        FindVendEntries();
        FindInvtEntries();
        FindResEntries();
        FindJobEntries();
        FindBankEntries();
        FindFAEntries();
        FindCapEntries();
        FindWhseEntries();
        FindServEntries();
        FindCostEntries();
        FindPostedGenJournalLine();
        FindDeliveryReminderEntries();
        if PostedInvtRcptHeader.ReadPermission() then begin
            PostedInvtRcptHeader.Reset();
            PostedInvtRcptHeader.SetFilter("No.", DocNoFilter);
            PostedInvtRcptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Invt. Receipt Header", PostedInvtRcptHeader.TableCaption(), PostedInvtRcptHeader.Count);
        end;
        if PostedInvtShptHeader.ReadPermission() then begin
            PostedInvtShptHeader.Reset();
            PostedInvtShptHeader.SetFilter("No.", DocNoFilter);
            PostedInvtShptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Invt. Shipment Header", PostedInvtShptHeader.TableCaption(), PostedInvtShptHeader.Count);
        end;

        OnAfterFindLedgerEntries(Rec, DocNoFilter, PostingDateFilter);
    end;

    local procedure FindCustEntries()
    var
        IsHandled: Boolean;
    begin
        OnBeforeFindCustLedgerEntry(CustLedgEntry, DocNoFilter, PostingDateFilter, ExtDocNo, IsHandled);
        if CustLedgEntry.ReadPermission() and (not IsHandled) then begin
            CustLedgEntry.Reset();
            CustLedgEntry.SetCurrentKey("Document No.");
            CustLedgEntry.SetFilter("Document No.", DocNoFilter);
            CustLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            CustLedgEntry.SetFilter("External Document No.", ExtDocNo);
            OnFindCustEntriesOnAfterSetFilters(CustLedgEntry);
            InsertIntoDocEntry(Rec, Database::"Cust. Ledger Entry", CustLedgEntry.TableCaption(), CustLedgEntry.Count);
        end;
        if (DocNoFilter <> '') or (PostingDateFilter <> '') then
            if DtldCustLedgEntry.ReadPermission() then begin
                DtldCustLedgEntry.Reset();
                DtldCustLedgEntry.SetCurrentKey("Document No.");
                DtldCustLedgEntry.SetFilter("Document No.", DocNoFilter);
                DtldCustLedgEntry.SetFilter("Posting Date", PostingDateFilter);
                OnFindCustEntriesOnAfterDtldCustLedgEntriesSetFilters(DtldCustLedgEntry);
                InsertIntoDocEntry(Rec, Database::"Detailed Cust. Ledg. Entry", DtldCustLedgEntry.TableCaption(), DtldCustLedgEntry.Count);
            end;
    end;

    local procedure FindVendEntries()
    var
        IsHandled: Boolean;
    begin
        OnBeforeFindVendorLedgerEntry(VendLedgEntry, DocNoFilter, PostingDateFilter, ExtDocNo, IsHandled);
        if VendLedgEntry.ReadPermission() and (not IsHandled) then begin
            VendLedgEntry.Reset();
            VendLedgEntry.SetCurrentKey("Document No.");
            VendLedgEntry.SetFilter("Document No.", DocNoFilter);
            VendLedgEntry.SetFilter("External Document No.", ExtDocNo);
            VendLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            OnFindVendEntriesOnAfterSetFilters(VendLedgEntry);
            InsertIntoDocEntry(Rec, Database::"Vendor Ledger Entry", VendLedgEntry.TableCaption(), VendLedgEntry.Count);
        end;
        if (DocNoFilter <> '') or (PostingDateFilter <> '') then
            if DtldVendLedgEntry.ReadPermission() then begin
                DtldVendLedgEntry.Reset();
                DtldVendLedgEntry.SetCurrentKey("Document No.");
                DtldVendLedgEntry.SetFilter("Document No.", DocNoFilter);
                DtldVendLedgEntry.SetFilter("Posting Date", PostingDateFilter);
                OnFindVendEntriesOnAfterDtldVendLedgEntriesSetFilters(DtldVendLedgEntry);
                InsertIntoDocEntry(Rec, Database::"Detailed Vendor Ledg. Entry", DtldVendLedgEntry.TableCaption(), DtldVendLedgEntry.Count);
            end;
    end;

    local procedure FindBankEntries()
    var
        IsHandled: Boolean;
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        OnBeforeFindBankAccountLedgerEntry(BankAccLedgEntry, DocNoFilter, PostingDateFilter, ExtDocNo, IsHandled);
        if BankAccLedgEntry.ReadPermission() and (not IsHandled) then begin
            BankAccLedgEntry.Reset();
            BankAccLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            BankAccLedgEntry.SetFilter("Document No.", DocNoFilter);
            BankAccLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            OnFindBankEntriesOnAfterSetFilters(BankAccLedgEntry);
            InsertIntoDocEntry(Rec, Database::"Bank Account Ledger Entry", BankAccLedgEntry.TableCaption(), BankAccLedgEntry.Count);
        end;
        if CheckLedgEntry.ReadPermission() then begin
            CheckLedgEntry.Reset();
            CheckLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            CheckLedgEntry.SetFilter("Document No.", DocNoFilter);
            CheckLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Check Ledger Entry", CheckLedgEntry.TableCaption(), CheckLedgEntry.Count);
        end;
    end;

    local procedure FindGLEntries()
    var
        IsHandled: Boolean;
    begin
        OnBeforeFindGLEntry(GLEntry, DocNoFilter, PostingDateFilter, ExtDocNo, IsHandled);
        if GLEntry.ReadPermission() and (not IsHandled) then begin
            GLEntry.Reset();
            GLEntry.SetCurrentKey("Document No.", "Posting Date");
            GLEntry.SetFilter("Document No.", DocNoFilter);
            GLEntry.SetFilter("Posting Date", PostingDateFilter);
            GLEntry.SetFilter("External Document No.", ExtDocNo);
            OnFindGLEntriesOnAfterSetFilters(GLEntry);
            InsertIntoDocEntry(Rec, Database::"G/L Entry", GLEntry.TableCaption(), GLEntry.Count);
        end;
    end;

    local procedure FindVATEntries()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if VATEntry.ReadPermission() then begin
            VATEntry.Reset();
            VATEntry.SetCurrentKey("Document No.", "Posting Date");
            VATEntry.SetFilter("Document No.", DocNoFilter);
            VATEntry.SetFilter("Posting Date", PostingDateFilter);
            OnFindVATEntriesOnAfterVATEntrySetFilters(VATEntry, DocNoFilter, PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"VAT Entry", VATEntry.TableCaption(), VATEntry.Count);
        end;
    end;

    local procedure FindFAEntries()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if FALedgEntry.ReadPermission() then begin
            FALedgEntry.Reset();
            FALedgEntry.SetCurrentKey("Document No.", "Posting Date");
            FALedgEntry.SetFilter("Document No.", DocNoFilter);
            FALedgEntry.SetFilter("Posting Date", PostingDateFilter);
            OnFindFAEntriesOnAfterSetFilters(FALedgEntry);
            InsertIntoDocEntry(Rec, Database::"FA Ledger Entry", FALedgEntry.TableCaption(), FALedgEntry.Count);
        end;
        if MaintenanceLedgEntry.ReadPermission() then begin
            MaintenanceLedgEntry.Reset();
            MaintenanceLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            MaintenanceLedgEntry.SetFilter("Document No.", DocNoFilter);
            MaintenanceLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Maintenance Ledger Entry", MaintenanceLedgEntry.TableCaption(), MaintenanceLedgEntry.Count);
        end;
        if InsuranceCovLedgEntry.ReadPermission() then begin
            InsuranceCovLedgEntry.Reset();
            InsuranceCovLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            InsuranceCovLedgEntry.SetFilter("Document No.", DocNoFilter);
            InsuranceCovLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Ins. Coverage Ledger Entry", InsuranceCovLedgEntry.TableCaption(), InsuranceCovLedgEntry.Count);
        end;
    end;

    local procedure FindInvtEntries()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ItemLedgEntry.ReadPermission() then begin
            ItemLedgEntry.Reset();
            ItemLedgEntry.SetCurrentKey("Document No.");
            ItemLedgEntry.SetFilter("Document No.", DocNoFilter);
            ItemLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Item Ledger Entry", ItemLedgEntry.TableCaption(), ItemLedgEntry.Count);
        end;
        if ValueEntry.ReadPermission() then begin
            ValueEntry.Reset();
            ValueEntry.SetCurrentKey("Document No.");
            ValueEntry.SetFilter("Document No.", DocNoFilter);
            ValueEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Value Entry", ValueEntry.TableCaption(), ValueEntry.Count);
        end;
        if PhysInvtLedgEntry.ReadPermission() then begin
            PhysInvtLedgEntry.Reset();
            PhysInvtLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            PhysInvtLedgEntry.SetFilter("Document No.", DocNoFilter);
            PhysInvtLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Phys. Inventory Ledger Entry", PhysInvtLedgEntry.TableCaption(), PhysInvtLedgEntry.Count);
        end;
    end;

    local procedure FindReminderEntries()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ReminderEntry.ReadPermission() then begin
            ReminderEntry.Reset();
            ReminderEntry.SetCurrentKey(Type, "No.");
            ReminderEntry.SetFilter("No.", DocNoFilter);
            ReminderEntry.SetFilter("Posting Date", PostingDateFilter);
            OnFindReminderEntriesOnAfterSetFilters(ReminderEntry);
            InsertIntoDocEntry(Rec, Database::"Reminder/Fin. Charge Entry", ReminderEntry.TableCaption(), ReminderEntry.Count);
        end;
    end;

    local procedure FindResEntries()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ResLedgEntry.ReadPermission() then begin
            ResLedgEntry.Reset();
            ResLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            ResLedgEntry.SetFilter("Document No.", DocNoFilter);
            ResLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Res. Ledger Entry", ResLedgEntry.TableCaption(), ResLedgEntry.Count);
        end;
    end;

    local procedure FindServEntries()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ServLedgerEntry.ReadPermission() then begin
            ServLedgerEntry.Reset();
            ServLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
            ServLedgerEntry.SetFilter("Document No.", DocNoFilter);
            ServLedgerEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Service Ledger Entry", ServLedgerEntry.TableCaption(), ServLedgerEntry.Count);
        end;
        if WarrantyLedgerEntry.ReadPermission() then begin
            WarrantyLedgerEntry.Reset();
            WarrantyLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
            WarrantyLedgerEntry.SetFilter("Document No.", DocNoFilter);
            WarrantyLedgerEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Warranty Ledger Entry", WarrantyLedgerEntry.TableCaption(), WarrantyLedgerEntry.Count);
        end;
    end;

    local procedure FindCapEntries()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if CapacityLedgEntry.ReadPermission() then begin
            CapacityLedgEntry.Reset();
            CapacityLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            CapacityLedgEntry.SetFilter("Document No.", DocNoFilter);
            CapacityLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Capacity Ledger Entry", CapacityLedgEntry.TableCaption(), CapacityLedgEntry.Count);
        end;
    end;

    local procedure FindCostEntries()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if CostEntry.ReadPermission() then begin
            CostEntry.Reset();
            CostEntry.SetCurrentKey("Document No.", "Posting Date");
            CostEntry.SetFilter("Document No.", DocNoFilter);
            CostEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Cost Entry", CostEntry.TableCaption(), CostEntry.Count);
        end;
        OnAfterFindCostEntries(Rec, DocNoFilter, PostingDateFilter);
    end;

    local procedure FindWhseEntries()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if WhseEntry.ReadPermission() then begin
            WhseEntry.Reset();
            WhseEntry.SetCurrentKey("Reference No.", "Registering Date");
            WhseEntry.SetFilter("Reference No.", DocNoFilter);
            WhseEntry.SetFilter("Registering Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Warehouse Entry", WhseEntry.TableCaption(), WhseEntry.Count);
        end;
    end;

    local procedure FindJobEntries()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if JobLedgEntry.ReadPermission() then begin
            JobLedgEntry.Reset();
            JobLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            JobLedgEntry.SetFilter("Document No.", DocNoFilter);
            JobLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Job Ledger Entry", JobLedgEntry.TableCaption(), JobLedgEntry.Count);
        end;
        if JobWIPEntry.ReadPermission() then begin
            JobWIPEntry.Reset();
            JobWIPEntry.SetFilter("Document No.", DocNoFilter);
            JobWIPEntry.SetFilter("WIP Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Job WIP Entry", JobWIPEntry.TableCaption(), JobWIPEntry.Count);
        end;
        if JobWIPGLEntry.ReadPermission() then begin
            JobWIPGLEntry.Reset();
            JobWIPGLEntry.SetCurrentKey("Document No.", "Posting Date");
            JobWIPGLEntry.SetFilter("Document No.", DocNoFilter);
            JobWIPGLEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Job WIP G/L Entry", JobWIPGLEntry.TableCaption(), JobWIPGLEntry.Count);
        end;
    end;

    local procedure FindDeliveryReminderEntries()
    begin
        OnBeforeFindDeliveryReminderEntries();
        if DelivReminLedgerEntries.ReadPermission() then begin
            DelivReminLedgerEntries.Reset();
            DelivReminLedgerEntries.SetCurrentKey("Reminder No.", "Posting Date");
            DelivReminLedgerEntries.SetFilter("Reminder No.", DocNoFilter);
            DelivReminLedgerEntries.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(
              Rec, DATABASE::"Delivery Reminder Ledger Entry", DelivReminLedgerEntries.TableCaption(), DelivReminLedgerEntries.Count);
        end;
    end;

    local procedure FindPostedDocuments()
    begin
        FindIncomingDocumentRecords();
        FindEmployeeRecords();
        FindSalesShipmentHeader();
        FindSalesInvoiceHeader();
        FindReturnRcptHeader();
        FindSalesCrMemoHeader();
        FindServShipmentHeader();
        FindServInvoiceHeader();
        FindServCrMemoHeader();
        FindIssuedReminderHeader();
        FindIssuedFinChrgMemoHeader();
        FindPurchRcptHeader();
        FindPurchInvoiceHeader();
        FindReturnShptHeader();
        FindPurchCrMemoHeader();
        FindProdOrderHeader();
        FindPostedAssemblyHeader();
        FindTransShptHeader();
        FindTransRcptHeader();
        FindDirectTransHeader();
        FindPstdPhysInvtOrderHdr();
        FindPostedWhseShptLine();
        FindPostedWhseRcptLine();
        FindPostedInvtReceipt();
        FindPostedInvtShipment();
        FindIssuedDeliveryReminderHeader();

        OnAfterFindPostedDocuments(DocNoFilter, PostingDateFilter, Rec);
    end;

    local procedure FindIncomingDocumentRecords()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if IncomingDocument.ReadPermission() then begin
            IncomingDocument.Reset();
            IncomingDocument.SetFilter("Document No.", DocNoFilter);
            IncomingDocument.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Incoming Document", IncomingDocument.TableCaption(), IncomingDocument.Count);
        end;
    end;

    local procedure FindSalesShipmentHeader()
    begin
        if SalesShptHeader.ReadPermission() then begin
            SalesShptHeader.Reset();
            SalesShptHeader.SetFilter("No.", DocNoFilter);
            SalesShptHeader.SetFilter("Posting Date", PostingDateFilter);
            SalesShptHeader.SetFilter("External Document No.", ExtDocNo);
            OnFindSalesShipmentHeaderOnAfterSetFilters(SalesShptHeader);
            InsertIntoDocEntry(Rec, Database::"Sales Shipment Header", PostedSalesShipmentTxt, SalesShptHeader.Count);
        end;
    end;

    local procedure FindSalesInvoiceHeader()
    begin
        if SalesInvHeader.ReadPermission() then begin
            SalesInvHeader.Reset();
            SalesInvHeader.SetFilter("No.", DocNoFilter);
            SalesInvHeader.SetFilter("Posting Date", PostingDateFilter);
            SalesInvHeader.SetFilter("External Document No.", ExtDocNo);
            OnFindSalesInvoiceHeaderOnAfterSetFilters(SalesInvHeader);
            InsertIntoDocEntry(Rec, Database::"Sales Invoice Header", PostedSalesInvoiceTxt, SalesInvHeader.Count);
        end;
    end;

    local procedure FindSalesCrMemoHeader()
    begin
        if SalesCrMemoHeader.ReadPermission() then begin
            SalesCrMemoHeader.Reset();
            SalesCrMemoHeader.SetFilter("No.", DocNoFilter);
            SalesCrMemoHeader.SetFilter("Posting Date", PostingDateFilter);
            SalesCrMemoHeader.SetFilter("External Document No.", ExtDocNo);
            OnFindSalesCrMemoHeaderOnAfterSetFilters(SalesCrMemoHeader);
            InsertIntoDocEntry(Rec, Database::"Sales Cr.Memo Header", PostedSalesCreditMemoTxt, SalesCrMemoHeader.Count);
        end;
    end;

    local procedure FindReturnRcptHeader()
    begin
        if ReturnRcptHeader.ReadPermission() then begin
            ReturnRcptHeader.Reset();
            ReturnRcptHeader.SetFilter("No.", DocNoFilter);
            ReturnRcptHeader.SetFilter("Posting Date", PostingDateFilter);
            ReturnRcptHeader.SetFilter("External Document No.", ExtDocNo);
            InsertIntoDocEntry(Rec, Database::"Return Receipt Header", PostedReturnReceiptTxt, ReturnRcptHeader.Count);
        end;
    end;

    local procedure FindServShipmentHeader()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ServShptHeader.ReadPermission() then begin
            ServShptHeader.Reset();
            ServShptHeader.SetFilter("No.", DocNoFilter);
            ServShptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Service Shipment Header", PostedServiceShipmentTxt, ServShptHeader.Count);
        end;
    end;

    local procedure FindServInvoiceHeader()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ServInvHeader.ReadPermission() then begin
            ServInvHeader.Reset();
            ServInvHeader.SetFilter("No.", DocNoFilter);
            ServInvHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Service Invoice Header", PostedServiceInvoiceTxt, ServInvHeader.Count);
        end;
    end;

    local procedure FindServCrMemoHeader()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ServCrMemoHeader.ReadPermission() then begin
            ServCrMemoHeader.Reset();
            ServCrMemoHeader.SetFilter("No.", DocNoFilter);
            ServCrMemoHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Service Cr.Memo Header", PostedServiceCreditMemoTxt, ServCrMemoHeader.Count);
        end;
    end;

    local procedure FindEmployeeRecords()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if EmplLedgEntry.ReadPermission() then begin
            EmplLedgEntry.Reset();
            EmplLedgEntry.SetCurrentKey("Document No.");
            EmplLedgEntry.SetFilter("Document No.", DocNoFilter);
            EmplLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Employee Ledger Entry", EmplLedgEntry.TableCaption(), EmplLedgEntry.Count);
        end;
        if DtldEmplLedgEntry.ReadPermission() then begin
            DtldEmplLedgEntry.Reset();
            DtldEmplLedgEntry.SetCurrentKey("Document No.");
            DtldEmplLedgEntry.SetFilter("Document No.", DocNoFilter);
            DtldEmplLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Detailed Employee Ledger Entry", DtldEmplLedgEntry.TableCaption(), DtldEmplLedgEntry.Count);
        end;
    end;

    local procedure FindIssuedReminderHeader()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if IssuedReminderHeader.ReadPermission() then begin
            IssuedReminderHeader.Reset();
            IssuedReminderHeader.SetFilter("No.", DocNoFilter);
            IssuedReminderHeader.SetFilter("Posting Date", PostingDateFilter);
            OnFindIssuedReminderHeaderOnAfterSetFilters(IssuedReminderHeader);
            InsertIntoDocEntry(Rec, Database::"Issued Reminder Header", IssuedReminderTxt, IssuedReminderHeader.Count);
        end;
    end;

    local procedure FindIssuedFinChrgMemoHeader()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if IssuedFinChrgMemoHeader.ReadPermission() then begin
            IssuedFinChrgMemoHeader.Reset();
            IssuedFinChrgMemoHeader.SetFilter("No.", DocNoFilter);
            IssuedFinChrgMemoHeader.SetFilter("Posting Date", PostingDateFilter);
            OnFindIssuedFinChrgMemoHeaderOnAfterSetFilters(IssuedFinChrgMemoHeader);
            InsertIntoDocEntry(
                Rec, Database::"Issued Fin. Charge Memo Header", IssuedFinanceChargeMemoTxt, IssuedFinChrgMemoHeader.Count);
        end;
    end;

    local procedure FindPurchRcptHeader()
    begin
        if PurchRcptHeader.ReadPermission() then begin
            PurchRcptHeader.Reset();
            PurchRcptHeader.SetFilter("No.", DocNoFilter);
            PurchRcptHeader.SetFilter("Posting Date", PostingDateFilter);
            PurchRcptHeader.SetFilter("Vendor Shipment No.", ExtDocNo);
            OnFindPurchRcptHeaderOnAfterSetFilters(PurchRcptHeader);
            InsertIntoDocEntry(Rec, Database::"Purch. Rcpt. Header", PostedPurchaseReceiptTxt, PurchRcptHeader.Count);
        end;

        OnAfterFindPurchRcptHeader(Rec, PurchRcptHeader, DocNoFilter, PostingDateFilter);
    end;

    local procedure FindPurchInvoiceHeader()
    begin
        if PurchInvHeader.ReadPermission() then begin
            PurchInvHeader.Reset();
            PurchInvHeader.SetFilter("No.", DocNoFilter);
            PurchInvHeader.SetFilter("Posting Date", PostingDateFilter);
            PurchInvHeader.SetFilter("Vendor Invoice No.", ExtDocNo);
            OnFindPurchInvoiceHeaderOnAfterSetFilters(PurchInvHeader);
            InsertIntoDocEntry(Rec, Database::"Purch. Inv. Header", PostedPurchaseInvoiceTxt, PurchInvHeader.Count);
        end;
    end;

    local procedure FindPurchCrMemoHeader()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if PurchCrMemoHeader.ReadPermission() then begin
            PurchCrMemoHeader.Reset();
            PurchCrMemoHeader.SetFilter("No.", DocNoFilter);
            PurchCrMemoHeader.SetFilter("Posting Date", PostingDateFilter);
            OnFindPurchCrMemoHeaderOnAfterSetFilters(PurchCrMemoHeader);
            InsertIntoDocEntry(Rec, Database::"Purch. Cr. Memo Hdr.", PostedPurchaseCreditMemoTxt, PurchCrMemoHeader.Count);
        end;
    end;

    local procedure FindReturnShptHeader()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ReturnShptHeader.ReadPermission() then begin
            ReturnShptHeader.Reset();
            ReturnShptHeader.SetFilter("No.", DocNoFilter);
            ReturnShptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Return Shipment Header", PostedReturnShipmentTxt, ReturnShptHeader.Count);
        end;
    end;

    local procedure FindProdOrderHeader()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ProductionOrderHeader.ReadPermission() then begin
            ProductionOrderHeader.Reset();
            ProductionOrderHeader.SetRange(
              Status,
              ProductionOrderHeader.Status::Released,
              ProductionOrderHeader.Status::Finished);
            ProductionOrderHeader.SetFilter("No.", DocNoFilter);
            InsertIntoDocEntry(Rec, Database::"Production Order", ProductionOrderTxt, ProductionOrderHeader.Count);
        end;
    end;

    local procedure FindPostedAssemblyHeader()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if PostedAssemblyHeader.ReadPermission() then begin
            PostedAssemblyHeader.Reset();
            PostedAssemblyHeader.SetFilter("No.", DocNoFilter);
            InsertIntoDocEntry(Rec, Database::"Posted Assembly Header", PostedAssemblyOrderTxt, PostedAssemblyHeader.Count);
        end;
    end;

    local procedure FindPostedWhseShptLine()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if PostedWhseShptLine.ReadPermission() then begin
            PostedWhseShptLine.Reset();
            PostedWhseShptLine.SetCurrentKey("Posted Source No.", "Posting Date");
            PostedWhseShptLine.SetFilter("Posted Source No.", DocNoFilter);
            PostedWhseShptLine.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Posted Whse. Shipment Line", PostedWhseShptLine.TableCaption(), PostedWhseShptLine.Count);
        end;
    end;

    local procedure FindPostedWhseRcptLine()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if PostedWhseRcptLine.ReadPermission() then begin
            PostedWhseRcptLine.Reset();
            PostedWhseRcptLine.SetCurrentKey("Posted Source No.", "Posting Date");
            PostedWhseRcptLine.SetFilter("Posted Source No.", DocNoFilter);
            PostedWhseRcptLine.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Posted Whse. Receipt Line", PostedWhseRcptLine.TableCaption(), PostedWhseRcptLine.Count);
        end;
    end;

    local procedure FindPstdPhysInvtOrderHdr()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if PstdPhysInvtOrderHdr.ReadPermission() then begin
            PstdPhysInvtOrderHdr.Reset();
            PstdPhysInvtOrderHdr.SetFilter("No.", DocNoFilter);
            PstdPhysInvtOrderHdr.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Pstd. Phys. Invt. Order Hdr", PstdPhysInvtOrderHdr.TableCaption(), PstdPhysInvtOrderHdr.Count);
        end;
    end;

    local procedure FindTransShptHeader()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if TransShptHeader.ReadPermission() then begin
            TransShptHeader.Reset();
            TransShptHeader.SetFilter("No.", DocNoFilter);
            TransShptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Transfer Shipment Header", PostedTransferShipmentTxt, TransShptHeader.Count);
        end;
    end;

    local procedure FindTransRcptHeader()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if TransRcptHeader.ReadPermission() then begin
            TransRcptHeader.Reset();
            TransRcptHeader.SetFilter("No.", DocNoFilter);
            TransRcptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Transfer Receipt Header", PostedTransferReceiptTxt, TransRcptHeader.Count);
        end;
    end;

    local procedure FindDirectTransHeader()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if DirectTransHeader.ReadPermission() then begin
            DirectTransHeader.Reset();
            DirectTransHeader.SetFilter("No.", DocNoFilter);
            DirectTransHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Direct Trans. Header", PostedDirectTransferTxt, DirectTransHeader.Count);
        end;
    end;

    local procedure FindPostedInvtReceipt()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if PostedInvtRcptHeader.ReadPermission() then begin
            PostedInvtRcptHeader.Reset();
            PostedInvtRcptHeader.SetFilter("No.", DocNoFilter);
            PostedInvtRcptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Invt. Receipt Header", PostedInvtRcptHeader.TableCaption(), PostedInvtRcptHeader.Count);
        end;
    end;

    local procedure FindPostedInvtShipment()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if PostedInvtShptHeader.ReadPermission() then begin
            PostedInvtShptHeader.Reset();
            PostedInvtShptHeader.SetFilter("No.", DocNoFilter);
            PostedInvtShptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Invt. Shipment Header", PostedInvtShptHeader.TableCaption(), PostedInvtShptHeader.Count);
        end;
    end;

    local procedure FindIssuedDeliveryReminderHeader()
    begin
        if IssuedDeliveryReminderHeader.ReadPermission() then begin
            IssuedDeliveryReminderHeader.Reset();
            IssuedDeliveryReminderHeader.SetFilter("No.", DocNoFilter);
            IssuedDeliveryReminderHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec,
              DATABASE::"Issued Deliv. Reminder Header", IssuedDeliveryReminderHeader.TableCaption(), IssuedDeliveryReminderHeader.Count);
        end;
    end;

    protected procedure UpdateFormAfterFindRecords()
    begin
        OnBeforeUpdateFormAfterFindRecords(PostingDateFilter);

        DocExists := Rec.FindFirst();
        ShowEnable := DocExists;
        PrintEnable := DocExists;
        CurrPage.Update(false);
    end;

    procedure InsertIntoDocEntry(DocTableID: Integer; DocTableName: Text; DocNoOfRecords: Integer)
    begin
        InsertIntoDocEntry(Rec, DocTableID, Enum::"Document Entry Document Type"::" ", DocTableName, DocNoOfRecords);
    end;

    procedure InsertIntoDocEntry(var TempDocumentEntry: Record "Document Entry" temporary; DocTableID: Integer; DocTableName: Text; DocNoOfRecords: Integer)
    begin
        InsertIntoDocEntry(TempDocumentEntry, DocTableID, Enum::"Document Entry Document Type"::" ", DocTableName, DocNoOfRecords);
    end;

    procedure InsertIntoDocEntry(var TempDocumentEntry: Record "Document Entry" temporary; DocTableID: Integer; DocType: Enum "Document Entry Document Type"; DocTableName: Text; DocNoOfRecords: Integer)
    begin
        if DocNoOfRecords = 0 then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." := TempDocumentEntry."Entry No." + 1;
        TempDocumentEntry."Table ID" := DocTableID;
        TempDocumentEntry."Document Type" := DocType;
        TempDocumentEntry."Table Name" := CopyStr(DocTableName, 1, MaxStrLen(Rec."Table Name"));
        TempDocumentEntry."No. of Records" := DocNoOfRecords;
        TempDocumentEntry.Insert();
    end;

    protected procedure NoOfRecords(TableID: Integer): Integer
    begin
        OnBeforeOnNoOfRecords(Rec, TableID);
        Rec.SetRange("Table ID", TableID);
        if not Rec.FindFirst() then
            Rec.Init();
        Rec.SetRange("Table ID");
        exit(Rec."No. of Records");
    end;

    procedure SetSource(PostingDate: Date; DocType2: Text[100]; DocNo: Text[50]; SourceType2: Integer; SourceNo2: Code[20])
    begin
        if SourceType2 = 0 then begin
            DocType := '';
            SourceType := '';
            SourceNo := '';
            SourceName := '';
        end else begin
            DocType := DocType2;
            SourceNo := SourceNo2;
            Rec.SetRange("Document No.", DocNo);
            Rec.SetRange("Posting Date", PostingDate);
            DocNoFilter := Rec.GetFilter("Document No.");
            PostingDateFilter := Rec.GetFilter("Posting Date");
            case SourceType2 of
                1:
                    begin
                        SourceType := CopyStr(Cust.TableCaption(), 1, MaxStrLen(SourceType));
                        if not Cust.Get(SourceNo) then
                            Cust.Init();
                        SourceName := Cust.Name;
                    end;
                2:
                    begin
                        SourceType := CopyStr(Vend.TableCaption(), 1, MaxStrLen(SourceType));
                        if not Vend.Get(SourceNo) then
                            Vend.Init();
                        SourceName := Vend.Name;
                    end;
                4:
                    begin
                        SourceType := CopyStr(BankAccount.TableCaption(), 1, MaxStrLen(SourceType));
                        if not BankAccount.Get(SourceNo) then
                            BankAccount.Init();
                        SourceName := BankAccount.Name;
                    end;
            end;
        end;
        DocTypeEnable := SourceType2 <> 0;
        SourceTypeEnable := SourceType2 <> 0;
        SourceNoEnable := SourceType2 <> 0;
        SourceNameEnable := SourceType2 <> 0;

        OnAfterSetSource(SourceType2, SourceType, SourceNo, SourceName, PostingDateFilter);
    end;

    local procedure SetSourceForPurchase()
    begin
        if NoOfRecords(Database::"Vendor Ledger Entry") = 1 then begin
            VendLedgEntry.FindFirst();
            SetSource(
              VendLedgEntry."Posting Date", Format(VendLedgEntry."Document Type"), VendLedgEntry."Document No.",
              2, VendLedgEntry."Vendor No.");
        end;
        if NoOfRecords(Database::"Detailed Vendor Ledg. Entry") = 1 then begin
            DtldVendLedgEntry.FindFirst();
            SetSource(
              DtldVendLedgEntry."Posting Date", Format(DtldVendLedgEntry."Document Type"), DtldVendLedgEntry."Document No.",
              2, DtldVendLedgEntry."Vendor No.");
        end;
        if NoOfRecords(Database::"Purch. Inv. Header") = 1 then begin
            PurchInvHeader.FindFirst();
            SetSource(
              PurchInvHeader."Posting Date", Format(Rec."Table Name"), PurchInvHeader."No.",
              2, PurchInvHeader."Pay-to Vendor No.");
        end;
        if NoOfRecords(Database::"Purch. Cr. Memo Hdr.") = 1 then begin
            PurchCrMemoHeader.FindFirst();
            SetSource(
              PurchCrMemoHeader."Posting Date", Format(Rec."Table Name"), PurchCrMemoHeader."No.",
              2, PurchCrMemoHeader."Pay-to Vendor No.");
        end;
        if NoOfRecords(Database::"Return Shipment Header") = 1 then begin
            ReturnShptHeader.FindFirst();
            SetSource(
              ReturnShptHeader."Posting Date", Format(Rec."Table Name"), ReturnShptHeader."No.",
              2, ReturnShptHeader."Buy-from Vendor No.");
        end;
        if NoOfRecords(Database::"Purch. Rcpt. Header") = 1 then begin
            PurchRcptHeader.FindFirst();
            SetSource(
              PurchRcptHeader."Posting Date", Format(Rec."Table Name"), PurchRcptHeader."No.",
              2, PurchRcptHeader."Buy-from Vendor No.");
        end;
        if NoOfRecords(Database::"Posted Whse. Receipt Line") = 1 then begin
            PostedWhseRcptLine.FindFirst();
            SetSource(
              PostedWhseRcptLine."Posting Date", Format(Rec."Table Name"), PostedWhseRcptLine."Posted Source No.",
              2, '');
        end;
        if NoOfRecords(Database::"Pstd. Phys. Invt. Order Hdr") = 1 then begin
            PstdPhysInvtOrderHdr.FindFirst();
            SetSource(
              PstdPhysInvtOrderHdr."Posting Date", Format(Rec."Table Name"), PstdPhysInvtOrderHdr."No.",
              3, '');
        end;
        if NoOfRecords(DATABASE::"Issued Deliv. Reminder Header") = 1 then begin
            IssuedDeliveryReminderHeader.FindFirst();
            SetSource(
                IssuedDeliveryReminderHeader."Posting Date", Format(Rec."Table Name"), IssuedDeliveryReminderHeader."No.",
                2, IssuedDeliveryReminderHeader."Vendor No.");
        end;

        OnAfterSetSourceForPurchase();
    end;

    local procedure SetSourceForSales()
    begin
        if NoOfRecords(Database::"Cust. Ledger Entry") = 1 then begin
            CustLedgEntry.FindFirst();
            SetSource(
              CustLedgEntry."Posting Date", Format(CustLedgEntry."Document Type"), CustLedgEntry."Document No.",
              1, CustLedgEntry."Customer No.");
        end;
        if NoOfRecords(Database::"Detailed Cust. Ledg. Entry") = 1 then begin
            DtldCustLedgEntry.FindFirst();
            SetSource(
              DtldCustLedgEntry."Posting Date", Format(DtldCustLedgEntry."Document Type"), DtldCustLedgEntry."Document No.",
              1, DtldCustLedgEntry."Customer No.");
        end;
        if NoOfRecords(Database::"Sales Invoice Header") = 1 then begin
            SalesInvHeader.FindFirst();
            SetSource(
              SalesInvHeader."Posting Date", Format(Rec."Table Name"), SalesInvHeader."No.",
              1, SalesInvHeader."Bill-to Customer No.");
        end;
        if NoOfRecords(Database::"Sales Cr.Memo Header") = 1 then begin
            SalesCrMemoHeader.FindFirst();
            SetSource(
              SalesCrMemoHeader."Posting Date", Format(Rec."Table Name"), SalesCrMemoHeader."No.",
              1, SalesCrMemoHeader."Bill-to Customer No.");
        end;
        if NoOfRecords(Database::"Return Receipt Header") = 1 then begin
            ReturnRcptHeader.FindFirst();
            SetSource(
              ReturnRcptHeader."Posting Date", Format(Rec."Table Name"), ReturnRcptHeader."No.",
              1, ReturnRcptHeader."Sell-to Customer No.");
        end;
        if NoOfRecords(Database::"Sales Shipment Header") = 1 then begin
            SalesShptHeader.FindFirst();
            SetSource(
              SalesShptHeader."Posting Date", Format(Rec."Table Name"), SalesShptHeader."No.",
              1, SalesShptHeader."Sell-to Customer No.");
        end;
        if NoOfRecords(Database::"Posted Whse. Shipment Line") = 1 then begin
            PostedWhseShptLine.FindFirst();
            SetSource(
              PostedWhseShptLine."Posting Date", Format(Rec."Table Name"), PostedWhseShptLine."Posted Source No.",
              1, PostedWhseShptLine."Destination No.");
        end;
        if NoOfRecords(Database::"Issued Reminder Header") = 1 then begin
            IssuedReminderHeader.FindFirst();
            SetSource(
              IssuedReminderHeader."Posting Date", Format(Rec."Table Name"), IssuedReminderHeader."No.",
              1, IssuedReminderHeader."Customer No.");
        end;
        if NoOfRecords(Database::"Issued Fin. Charge Memo Header") = 1 then begin
            IssuedFinChrgMemoHeader.FindFirst();
            SetSource(
              IssuedFinChrgMemoHeader."Posting Date", Format(Rec."Table Name"), IssuedFinChrgMemoHeader."No.",
              1, IssuedFinChrgMemoHeader."Customer No.");
        end;
    end;

    local procedure SetSourceForService()
    begin
        if NoOfRecords(Database::"Service Ledger Entry") = 1 then begin
            ServLedgerEntry.FindFirst();
            if ServLedgerEntry.Type = ServLedgerEntry.Type::"Service Contract" then
                SetSource(
                  ServLedgerEntry."Posting Date", Format(ServLedgerEntry."Document Type"), ServLedgerEntry."Document No.",
                  2, ServLedgerEntry."Service Contract No.")
            else
                SetSource(
                  ServLedgerEntry."Posting Date", Format(ServLedgerEntry."Document Type"), ServLedgerEntry."Document No.",
                  2, ServLedgerEntry."Service Order No.")
        end;
        if NoOfRecords(Database::"Warranty Ledger Entry") = 1 then begin
            WarrantyLedgerEntry.FindFirst();
            SetSource(
              WarrantyLedgerEntry."Posting Date", '', WarrantyLedgerEntry."Document No.",
              2, WarrantyLedgerEntry."Service Order No.")
        end;
    end;

    local procedure SetSourceForServiceDoc()
    begin
        if NoOfRecords(Database::"Service Invoice Header") = 1 then begin
            ServInvHeader.FindFirst();
            SetSource(
              ServInvHeader."Posting Date", Format(Rec."Table Name"), ServInvHeader."No.",
              1, ServInvHeader."Bill-to Customer No.");
        end;
        if NoOfRecords(Database::"Service Cr.Memo Header") = 1 then begin
            ServCrMemoHeader.FindFirst();
            SetSource(
              ServCrMemoHeader."Posting Date", Format(Rec."Table Name"), ServCrMemoHeader."No.",
              1, ServCrMemoHeader."Bill-to Customer No.");
        end;
        if NoOfRecords(Database::"Service Shipment Header") = 1 then begin
            ServShptHeader.FindFirst();
            SetSource(
              ServShptHeader."Posting Date", Format(Rec."Table Name"), ServShptHeader."No.",
              1, ServShptHeader."Customer No.");
        end;
    end;

    procedure ShowRecords()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNavigateShowRecords(
          Rec."Table ID", DocNoFilter, PostingDateFilter, ItemTrackingSearch(), Rec, IsHandled,
          SalesInvHeader, SalesCrMemoHeader, PurchInvHeader, PurchCrMemoHeader, ServInvHeader, ServCrMemoHeader,
          SOSalesHeader, SISalesHeader, SCMSalesHeader, SROSalesHeader, GLEntry, VATEntry, VendLedgEntry, WarrantyLedgerEntry, NewSourceRecVar,
          SalesShptHeader, ReturnRcptHeader, ReturnShptHeader, PurchRcptHeader, CustLedgEntry, DtldCustLedgEntry);
        if IsHandled then
            exit;

        if ItemTrackingSearch() then
            ItemTrackingNavigateMgt.Show(Rec."Table ID")
        else
            case Rec."Table ID" of
                Database::"Incoming Document":
                    PAGE.Run(PAGE::"Incoming Document", IncomingDocument);
                Database::"Sales Header":
                    ShowSalesHeaderRecords();
                Database::"Purchase Header":
                    ShowPurchaseHeaderRecords();
                Database::"Gen. Journal Line":
                    Page.Run(PAGE::"General Journal", GenJnlLine);
                Database::"Sales Invoice Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Sales Invoice", SalesInvHeader)
                    else
                        PAGE.Run(PAGE::"Posted Sales Invoices", SalesInvHeader);
                Database::"Sales Cr.Memo Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader)
                    else
                        PAGE.Run(PAGE::"Posted Sales Credit Memos", SalesCrMemoHeader);
                Database::"Return Receipt Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Return Receipt", ReturnRcptHeader)
                    else
                        PAGE.Run(0, ReturnRcptHeader);
                Database::"Sales Shipment Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Sales Shipment", SalesShptHeader)
                    else
                        PAGE.Run(0, SalesShptHeader);
                Database::"Issued Reminder Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Issued Reminder", IssuedReminderHeader)
                    else
                        PAGE.Run(0, IssuedReminderHeader);
                Database::"Issued Fin. Charge Memo Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Issued Finance Charge Memo", IssuedFinChrgMemoHeader)
                    else
                        PAGE.Run(0, IssuedFinChrgMemoHeader);
                Database::"Purch. Inv. Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Purchase Invoice", PurchInvHeader)
                    else
                        PAGE.Run(PAGE::"Posted Purchase Invoices", PurchInvHeader);
                Database::"Purch. Cr. Memo Hdr.":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHeader)
                    else
                        PAGE.Run(PAGE::"Posted Purchase Credit Memos", PurchCrMemoHeader);
                Database::"Return Shipment Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Return Shipment", ReturnShptHeader)
                    else
                        PAGE.Run(0, ReturnShptHeader);
                Database::"Purch. Rcpt. Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Purchase Receipt", PurchRcptHeader)
                    else
                        PAGE.Run(0, PurchRcptHeader);
                Database::"Production Order":
                    PAGE.Run(0, ProductionOrderHeader);
                Database::"Posted Assembly Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Assembly Order", PostedAssemblyHeader)
                    else
                        PAGE.Run(0, PostedAssemblyHeader);
                Database::"Transfer Shipment Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Transfer Shipment", TransShptHeader)
                    else
                        PAGE.Run(0, TransShptHeader);
                Database::"Transfer Receipt Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Transfer Receipt", TransRcptHeader)
                    else
                        PAGE.Run(0, TransRcptHeader);
                Database::"Posted Whse. Shipment Line":
                    PAGE.Run(0, PostedWhseShptLine);
                Database::"Posted Whse. Receipt Line":
                    PAGE.Run(0, PostedWhseRcptLine);
                Database::"G/L Entry":
                    PAGE.Run(0, GLEntry);
                Database::"VAT Entry":
                    PAGE.Run(0, VATEntry);
                Database::"Detailed Cust. Ledg. Entry":
                    PAGE.Run(0, DtldCustLedgEntry);
                Database::"Cust. Ledger Entry":
                    PAGE.Run(0, CustLedgEntry);
                Database::"Reminder/Fin. Charge Entry":
                    PAGE.Run(0, ReminderEntry);
                Database::"Vendor Ledger Entry":
                    PAGE.Run(0, VendLedgEntry);
                Database::"Detailed Vendor Ledg. Entry":
                    PAGE.Run(0, DtldVendLedgEntry);
                Database::"Employee Ledger Entry":
                    ShowEmployeeLedgerEntries();
                Database::"Detailed Employee Ledger Entry":
                    ShowDetailedEmployeeLedgerEntries();
                Database::"Item Ledger Entry":
                    PAGE.Run(0, ItemLedgEntry);
                Database::"Value Entry":
                    PAGE.Run(0, ValueEntry);
                Database::"Phys. Inventory Ledger Entry":
                    PAGE.Run(0, PhysInvtLedgEntry);
                Database::"Res. Ledger Entry":
                    PAGE.Run(0, ResLedgEntry);
                Database::"Job Ledger Entry":
                    PAGE.Run(0, JobLedgEntry);
                Database::"Job WIP Entry":
                    PAGE.Run(0, JobWIPEntry);
                Database::"Job WIP G/L Entry":
                    PAGE.Run(0, JobWIPGLEntry);
                Database::"Bank Account Ledger Entry":
                    PAGE.Run(0, BankAccLedgEntry);
                Database::"Check Ledger Entry":
                    PAGE.Run(0, CheckLedgEntry);
                Database::"FA Ledger Entry":
                    PAGE.Run(0, FALedgEntry);
                Database::"Maintenance Ledger Entry":
                    PAGE.Run(0, MaintenanceLedgEntry);
                Database::"Ins. Coverage Ledger Entry":
                    PAGE.Run(0, InsuranceCovLedgEntry);
                Database::"Capacity Ledger Entry":
                    PAGE.Run(0, CapacityLedgEntry);
                Database::"Warehouse Entry":
                    PAGE.Run(0, WhseEntry);
                Database::"Service Header":
                    ShowServiceHeaderRecords();
                Database::"Service Invoice Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Service Invoice", ServInvHeader)
                    else
                        PAGE.Run(0, ServInvHeader);
                Database::"Service Cr.Memo Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Service Credit Memo", ServCrMemoHeader)
                    else
                        PAGE.Run(0, ServCrMemoHeader);
                Database::"Service Shipment Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Service Shipment", ServShptHeader)
                    else
                        PAGE.Run(0, ServShptHeader);
                Database::"Service Ledger Entry":
                    PAGE.Run(0, ServLedgerEntry);
                Database::"Warranty Ledger Entry":
                    PAGE.Run(0, WarrantyLedgerEntry);
                Database::"Cost Entry":
                    PAGE.Run(0, CostEntry);
                Database::"Pstd. Phys. Invt. Order Hdr":
                    PAGE.Run(0, PstdPhysInvtOrderHdr);
                Database::"Posted Gen. Journal Line":
                    Page.Run(0, PostedGenJournalLine);
                Database::"Invt. Receipt Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Invt. Receipt", PostedInvtRcptHeader)
                    else
                        PAGE.Run(0, PostedInvtRcptHeader);
                Database::"Invt. Shipment Header":
                    if Rec."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Invt. Shipment", PostedInvtShptHeader)
                    else
                        PAGE.Run(0, PostedInvtShptHeader);
                DATABASE::"Issued Deliv. Reminder Header":
                    PAGE.Run(0, IssuedDeliveryReminderHeader);
                DATABASE::"Delivery Reminder Ledger Entry":
                    PAGE.Run(0, DelivReminLedgerEntries);
            end;

        OnAfterNavigateShowRecords(
          Rec."Table ID", DocNoFilter, PostingDateFilter, ItemTrackingSearch(), Rec,
          SalesInvHeader, SalesCrMemoHeader, PurchInvHeader, PurchCrMemoHeader, ServInvHeader, ServCrMemoHeader,
          ContactType, ContactNo, ExtDocNo);
    end;

    local procedure ShowPurchaseHeaderRecords()
    begin
        Rec.TestField("Table ID", Database::"Purchase Header");

        case Rec."Document Type" of
            Rec."Document Type"::Quote:
                if Rec."No. of Records" = 1 then
                    PAGE.Run(PAGE::"Purchase Quote", PQPurchaseHeader)
                else
                    PAGE.Run(0, PQPurchaseHeader);
            Rec."Document Type"::Order:
                if Rec."No. of Records" = 1 then
                    PAGE.Run(PAGE::"Purchase Order", POPurchaseHeader)
                else
                    PAGE.Run(0, POPurchaseHeader);
            Rec."Document Type"::Invoice:
                if Rec."No. of Records" = 1 then
                    PAGE.Run(PAGE::"Purchase Invoice", PIPurchaseHeader)
                else
                    PAGE.Run(0, PIPurchaseHeader);
        end;
    end;

    local procedure ShowSalesHeaderRecords()
    begin
        Rec.TestField("Table ID", Database::"Sales Header");

        case Rec."Document Type" of
            Rec."Document Type"::Quote:
                if Rec."No. of Records" = 1 then
                    PAGE.Run(PAGE::"Sales Quote", SQSalesHeader)
                else
                    PAGE.Run(0, SQSalesHeader);
            Rec."Document Type"::Order:
                if Rec."No. of Records" = 1 then
                    PAGE.Run(PAGE::"Sales Order", SOSalesHeader)
                else
                    PAGE.Run(0, SOSalesHeader);
            Rec."Document Type"::Invoice:
                if Rec."No. of Records" = 1 then
                    PAGE.Run(PAGE::"Sales Invoice", SISalesHeader)
                else
                    PAGE.Run(0, SISalesHeader);
            Rec."Document Type"::"Return Order":
                if Rec."No. of Records" = 1 then
                    PAGE.Run(PAGE::"Sales Return Order", SROSalesHeader)
                else
                    PAGE.Run(0, SROSalesHeader);
            Rec."Document Type"::"Credit Memo":
                if Rec."No. of Records" = 1 then
                    PAGE.Run(PAGE::"Sales Credit Memo", SCMSalesHeader)
                else
                    PAGE.Run(0, SCMSalesHeader);
        end;
    end;

    local procedure ShowServiceHeaderRecords()
    begin
        Rec.TestField("Table ID", Database::"Service Header");

        case Rec."Document Type" of
            Rec."Document Type"::Order:
                if Rec."No. of Records" = 1 then
                    PAGE.Run(PAGE::"Service Order", SOServHeader)
                else
                    PAGE.Run(0, SOServHeader);
            Rec."Document Type"::Invoice:
                if Rec."No. of Records" = 1 then
                    PAGE.Run(PAGE::"Service Invoice", SIServHeader)
                else
                    PAGE.Run(0, SIServHeader);
            Rec."Document Type"::"Credit Memo":
                if Rec."No. of Records" = 1 then
                    PAGE.Run(PAGE::"Service Credit Memo", SCMServHeader)
                else
                    PAGE.Run(0, SCMServHeader);
        end;
    end;

    local procedure ShowEmployeeLedgerEntries()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowEmployeeLedgerEntries(EmplLedgEntry, IsHandled);
        if IsHandled then
            exit;

        PAGE.Run(PAGE::"Employee Ledger Entries", EmplLedgEntry);
    end;

    local procedure ShowDetailedEmployeeLedgerEntries()
    begin
        PAGE.Run(PAGE::"Detailed Empl. Ledger Entries", DtldEmplLedgEntry);
    end;

    protected procedure SetPostingDate(PostingDate: Text)
    begin
        FilterTokens.MakeDateFilter(PostingDate);
        Rec.SetFilter("Posting Date", PostingDate);
        PostingDateFilter := Rec.GetFilter("Posting Date");
    end;

    protected procedure SetDocNo(DocNo: Text)
    begin
        Rec.SetFilter("Document No.", DocNo);
        DocNoFilter := Rec.GetFilter("Document No.");
        PostingDateFilter := Rec.GetFilter("Posting Date");
    end;

    protected procedure ClearSourceInfo()
    begin
        if DocExists then begin
            DocExists := false;
            Rec.DeleteAll();
            PrintEnable := false;
            ShowEnable := false;
            SetSource(0D, '', '', 0, '');
            CurrPage.Update(false);
        end;
    end;

    procedure MakeExtFilter(var DateFilter: Text; AddDate: Date; var DocNoFilter: Text; AddDocNo: Code[20])
    begin
        if DateFilter = '' then
            DateFilter := Format(AddDate)
        else
            if StrPos(DateFilter, Format(AddDate)) = 0 then
                if MaxStrLen(DateFilter) >= StrLen(DateFilter + '|' + Format(AddDate)) then
                    DateFilter := DateFilter + '|' + Format(AddDate)
                else
                    TooLongFilter();

        if DocNoFilter = '' then
            DocNoFilter := AddDocNo
        else
            if StrPos(DocNoFilter, AddDocNo) = 0 then
                if MaxStrLen(DocNoFilter) >= StrLen(DocNoFilter + '|' + AddDocNo) then
                    DocNoFilter := DocNoFilter + '|' + AddDocNo
                else
                    TooLongFilter();
    end;

    procedure FindPush()
    begin
        if (DocNoFilter <> '') or (PostingDateFilter <> '') or (ExtDocNo <> '') then
            SearchBasedOn := SearchBasedOn::Document;
        if (ContactType <> ContactType::" ") and ((ContactNo <> '') or (ExtDocNo <> '')) then
            SearchBasedOn := SearchBasedOn::"Business Contact";
        if (SerialNoFilter <> '') or (LotNoFilter <> '') then
            SearchBasedOn := SearchBasedOn::"Item Reference";

        case SearchBasedOn of
            SearchBasedOn::Document:
                FindRecords();
            SearchBasedOn::"Business Contact":
                FindExtRecords();
            SearchBasedOn::"Item Reference":
                FindTrackingRecords();
        end;
    end;

    local procedure TooLongFilter()
    begin
        if ContactNo = '' then
            Error(Text015);

        Error(Text016);
    end;

    local procedure FindUnpostedSalesDocs(DocType: Enum "Sales Document Type"; DocTableName: Text[100]; var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."SecurityFiltering"(SECURITYFILTER::Filtered);
        if SalesHeader.ReadPermission() then begin
            SalesHeader.Reset();
            SalesHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
            if DocNoFilter <> '' then
                SalesHeader.SetFilter("No.", DocNoFilter);
            if ContactNo <> '' then
                SalesHeader.SetFilter("Sell-to Customer No.", ContactNo);
            if ExtDocNo <> '' then
                SalesHeader.SetFilter("External Document No.", ExtDocNo);
            if PostingDateFilter <> '' then
                SalesHeader.SetFilter("Posting Date", PostingDateFilter);
            SalesHeader.SetRange("Document Type", DocType);
            OnFindUnpostedSalesDocsOnAfterSetFilters(SalesHeader);
            InsertIntoDocEntry(Rec, Database::"Sales Header", DocType, DocTableName, SalesHeader.Count);
        end;
    end;

    local procedure FindUnpostedGenJnlLines(DocTableName: Text[100]; var GenJournallLine: Record "Gen. Journal Line")
    var
        DocEntryType: Enum "Document Entry Document Type";
    begin
        GenJournallLine."SecurityFiltering"(SECURITYFILTER::Filtered);
        if GenJournallLine.ReadPermission() then begin
            GenJournallLine.Reset();
            GenJournallLine.SetCurrentKey("Document No.");
            if DocNoFilter <> '' then
                GenJournallLine.SetFilter("Document No.", DocNoFilter);
            if ExtDocNo <> '' then
                GenJournallLine.SetFilter("External Document No.", ExtDocNo);
            if PostingDateFilter <> '' then
                GenJournallLine.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, Database::"Gen. Journal Line", DocEntryType::" ", DocTableName, GenJournallLine.Count);
        end;
    end;

    local procedure FindUnpostedPurchaseDocs(DocType: Enum "Purchase Document Type"; DocTableName: Text[100]; var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader."SecurityFiltering"(SECURITYFILTER::Filtered);
        if PurchaseHeader.ReadPermission() then begin
            PurchaseHeader.Reset();
            PurchaseHeader.SetCurrentKey("Buy-from Vendor No.", "Vendor Invoice No.");
            if DocNoFilter <> '' then
                PurchaseHeader.SetFilter("No.", DocNoFilter);
            if ContactNo <> '' then
                PurchaseHeader.SetFilter("Sell-to Customer No.", ContactNo);
            if ExtDocNo <> '' then
                if DocType = DocType::Order then
                    PurchaseHeader.SetFilter("Vendor Order No.", ExtDocNo)
                else
                    PurchaseHeader.SetFilter("Vendor Invoice No.", ExtDocNo);
            if PostingDateFilter <> '' then
                PurchaseHeader.SetFilter("Posting Date", PostingDateFilter);
            PurchaseHeader.SetRange("Document Type", DocType);
            InsertIntoDocEntry(Rec, Database::"Purchase Header", DocType, DocTableName, PurchaseHeader.Count);
        end;
    end;

    local procedure FindUnpostedServDocs(DocType: Enum "Service Document Type"; DocTableName: Text[100]; var ServHeader: Record "Service Header")
    begin
        if ContactNo = '' then
            exit;
        if ExtDocNo <> '' then
            exit;
        ServHeader."SecurityFiltering"(SECURITYFILTER::Filtered);
        if not ServHeader.ReadPermission() then
            exit;
        ServHeader.Reset();
        ServHeader.SetCurrentKey("Customer No.");
        ServHeader.SetFilter("Customer No.", ContactNo);
        ServHeader.SetRange("Document Type", DocType);
        InsertIntoDocEntry(Rec, Database::"Service Header", DocType, DocTableName, ServHeader.Count);
    end;

    procedure FindTrackingRecords()
    var
        DocNoOfRecords: Integer;
    begin
        Window.Open(Text002);
        Rec.DeleteAll();
        Rec."Entry No." := 0;

        ItemTrackingFilters.SetFilter("Serial No. Filter", SerialNoFilter);
        ItemTrackingFilters.SetFilter("Lot No. Filter", LotNoFilter);
        ItemTrackingFilters.SetFilter("Package No. Filter", PackageNoFilter);

        Clear(ItemTrackingNavigateMgt);
        ItemTrackingNavigateMgt.FindTrackingRecords(ItemTrackingFilters);

        ItemTrackingNavigateMgt.Collect(TempRecordBuffer);
        OnFindTrackingRecordsOnAfterCollectTempRecordBuffer(TempRecordBuffer, SerialNoFilter, LotNoFilter);
        TempRecordBuffer.SetCurrentKey("Table No.", "Record Identifier");
        if TempRecordBuffer.Find('-') then
            repeat
                TempRecordBuffer.SetRange("Table No.", TempRecordBuffer."Table No.");

                DocNoOfRecords := 0;
                if TempRecordBuffer.Find('-') then
                    repeat
                        TempRecordBuffer.SetRange("Record Identifier", TempRecordBuffer."Record Identifier");
                        TempRecordBuffer.Find('+');
                        TempRecordBuffer.SetRange("Record Identifier");
                        DocNoOfRecords += 1;
                    until TempRecordBuffer.Next() = 0;

                InsertIntoDocEntry(Rec, TempRecordBuffer."Table No.", TempRecordBuffer."Table Name", DocNoOfRecords);

                TempRecordBuffer.SetRange("Table No.");
            until TempRecordBuffer.Next() = 0;

        OnAfterNavigateFindTrackingRecords(Rec, SerialNoFilter, LotNoFilter);

        DocExists := Rec.Find('-');

        UpdateFormAfterFindRecords();
        Window.Close();
    end;

    procedure SetTracking(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        NewItemTrackingSetup := ItemTrackingSetup;
    end;

    procedure ItemTrackingSearch(): Boolean
    begin
        exit(SearchBasedOn = SearchBasedOn::"Item Reference");
    end;

    procedure ClearTrackingInfo()
    begin
        SerialNoFilter := '';
        LotNoFilter := '';
        PackageNoFilter := '';
    end;

    procedure ClearInfo()
    begin
        SetDocNo('');
        SetPostingDate('');
        ExtDocNo := '';
    end;

    procedure ClearContactInfo()
    begin
        ContactType := ContactType::" ";
        ContactNo := '';
    end;

    local procedure DocNoFilterOnAfterValidate()
    begin
        ClearSourceInfo();
    end;

    local procedure PostingDateFilterOnAfterValidate()
    begin
        ClearSourceInfo();
    end;

    local procedure ExtDocNoOnAfterValidate()
    begin
        ClearSourceInfo();
    end;

    local procedure ContactTypeOnAfterValidate()
    begin
        ClearSourceInfo();
    end;

    local procedure ContactNoOnAfterValidate()
    begin
        ClearSourceInfo();
    end;

    local procedure SerialNoFilterOnAfterValidate()
    begin
        ClearSourceInfo();
    end;

    local procedure LotNoFilterOnAfterValidate()
    begin
        ClearSourceInfo();
    end;

    procedure FindRecordsOnOpen()
    begin
        if (NewDocNo = '') and (NewPostingDate = 0D) and not NewItemTrackingSetup.TrackingExists() then begin
            Rec.DeleteAll();
            ShowEnable := false;
            PrintEnable := false;
            SetSource(0D, '', '', 0, '');
        end else
            if NewItemTrackingSetup.TrackingExists() then begin
                SearchBasedOn := SearchBasedOn::"Item Reference";
                UpdateFindByGroupsVisibility();
                SetSource(0D, '', '', 0, '');
                Rec.SetTrackingFilterFromItemTrackingSetup(NewItemTrackingSetup);
                if NewItemTrackingSetup."Serial No." <> '' then
                    SerialNoFilter := Rec.GetFilter("Serial No. Filter");
                if NewItemTrackingSetup."Lot No." <> '' then
                    LotNoFilter := Rec.GetFilter("Lot No. Filter");
                if NewItemTrackingSetup."Package No." <> '' then
                    PackageNoFilter := Rec.GetFilter("Package No. Filter");
                ClearContactInfo();
                ClearInfo();
                FindTrackingRecords();
            end else begin
                SearchBasedOn := SearchBasedOn::Document;
                UpdateFindByGroupsVisibility();
                Rec.SetRange("Document No.", NewDocNo);
                Rec.SetRange("Posting Date", NewPostingDate);
                DocNoFilter := Rec.GetFilter("Document No.");
                PostingDateFilter := Rec.GetFilter("Posting Date");
                ExtDocNo := '';
                ClearContactInfo();
                ClearTrackingInfo();
                OnFindRecordsOnOpenOnAfterSetDocuentFilters(Rec, DocNoFilter, PostingDateFilter, ExtDocNo, NewSourceRecVar);
                FindRecords();
            end;
    end;

    procedure UpdateNavigateForm(UpdateFormFrom: Boolean)
    begin
        UpdateForm := UpdateFormFrom;
    end;

    procedure ReturnDocumentEntry(var TempDocumentEntry: Record "Document Entry" temporary)
    begin
        Rec.SetRange("Table ID");  // Clear filter.
        Rec.FindSet();
        repeat
            TempDocumentEntry.Init();
            TempDocumentEntry := Rec;
            TempDocumentEntry.Insert();
        until Rec.Next() = 0;
    end;

    protected procedure UpdateFindByGroupsVisibility()
    begin
        DocumentVisible := false;
        BusinessContactVisible := false;
        ItemReferenceVisible := false;
        ClearInfo();
        ClearContactInfo();
        ClearTrackingInfo();

        case SearchBasedOn of
            SearchBasedOn::Document:
                DocumentVisible := true;
            SearchBasedOn::"Business Contact":
                BusinessContactVisible := true;
            SearchBasedOn::"Item Reference":
                ItemReferenceVisible := true;
        end;
    end;

    procedure FilterSelectionChanged()
    begin
        FilterSelectionChangedTxtVisible := not Rec.IsEmpty();
    end;

    local procedure GetCaptionText(): Text
    begin
        if Rec."Table Name" <> '' then
            exit(StrSubstNo(PageCaptionTxt, Rec."Table Name"));

        exit('');
    end;

    local procedure FindPostedGenJournalLine()
    begin
        if PostedGenJournalLine.ReadPermission() then begin
            PostedGenJournalLine.Reset();
            if DocNoFilter <> '' then
                PostedGenJournalLine.SetFilter("Document No.", DocNoFilter);
            if PostingDateFilter <> '' then
                PostedGenJournalLine.SetFilter("Posting Date", PostingDateFilter);
            if ExtDocNo <> '' then
                PostedGenJournalLine.SetFilter("External Document No.", ExtDocNo);
            InsertIntoDocEntry(Rec, Database::"Posted Gen. Journal Line", PostedGenJournalLineTxt, PostedGenJournalLine.Count);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindCostEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFindPostedDocuments(var DocNoFilter: Text; var PostingDateFilter: Text; var DocumentEntry: Record "Document Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFindPurchRcptHeader(var DocumentEntry: Record "Document Entry"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterNavigateFindExtRecords(var DocumentEntry: Record "Document Entry"; ContactType: Enum "Navigate Contact Type"; ContactNo: Code[250]; ExtDocNo: Code[250]; var FoundRecords: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterNavigateFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var NewSourceRecVar: Variant; ExtDocNo: Code[250]; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNavigateFindTrackingRecords(var DocumentEntry: Record "Document Entry"; SerialNoFilter: Text; LotNoFilter: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterNavigateShowRecords(TableID: Integer; DocNoFilter: Text; PostingDateFilter: Text; ItemTrackingSearch: Boolean; var TempDocumentEntry: Record "Document Entry" temporary; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ContactType: Enum "Navigate Contact Type"; ContactNo: Code[250]; ExtDocNo: Code[250])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetRec(NewSourceRecVar: Variant)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetSourceForPurchase()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetSource(var SourceType2: Integer; var SourceType: Text[30]; SourceNo: Code[20]; var SourceName: Text[100]; var PostingDateFilter: Text)
    begin
    end;

#if not CLEAN22
    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by OnBeforeFindRecordsProcedure', '22.0')]
    local procedure OnBeforeFindRecords(var HideDialog: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecordsProcedure(DocumentEntry: Record "Document Entry"; var HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnNoOfRecords(var DocumentEntry: Record "Document Entry"; var TableID: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeNavigateShowRecords(TableID: Integer; DocNoFilter: Text; PostingDateFilter: Text; ItemTrackingSearch: Boolean; var TempDocumentEntry: Record "Document Entry" temporary; var IsHandled: Boolean; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var SOSalesHeader: Record "Sales Header"; var SISalesHeader: Record "Sales Header"; var SCMSalesHeader: Record "Sales Header"; var SROSalesHeader: Record "Sales Header"; var GLEntry: Record "G/L Entry"; var VATEntry: Record "VAT Entry"; var VendLedgEntry: Record "Vendor Ledger Entry"; var WarrantyLedgerEntry: Record "Warranty Ledger Entry"; var NewSourceRecVar: Variant; var SalesShipmentHeader: Record "Sales Shipment Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var ReturnShipmentHeader: Record "Return Shipment Header"; var PurchRcptHeader: Record "Purch. Rcpt. Header"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeShowEmployeeLedgerEntries(var EmplLedgEntry: Record "Employee Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateFormAfterFindRecords(var PostingDateFilter: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindDeliveryReminderEntries()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindExtRecordsOnAfterSetSalesCrMemoFilter(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindVATEntriesOnAfterVATEntrySetFilters(var VATEntry: Record "VAT Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindExtRecordsOnAfterSetSalesInvoiceFilter(var SalesInvHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindExtRecordsOnBeforeFormUpdate(var Rec: Record "Document Entry"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPurchCrMemoHeaderOnAfterSetFilters(var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPurchInvoiceHeaderOnAfterSetFilters(var PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSalesCrMemoHeaderOnAfterSetFilters(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSalesInvoiceHeaderOnAfterSetFilters(var SalesInvHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindRecordsOnAfterSetSource(var DocumentEntry: Record "Document Entry"; var PostingDate: Date; var DocType2: Text[100]; var DocNo: Code[20]; var SourceType2: Integer; var SourceNo: Code[20]; var DocNoFilter: Text; var PostingDateFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordsOnOpenOnAfterSetDocuentFilters(var Rec: Record "Document Entry"; var DocNoFilter: Text; var PostingDateFilter: Text; ExtDocNo: Code[250]; NewSourceRecVar: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindTrackingRecordsOnAfterCollectTempRecordBuffer(var TempRecordBuffer: Record "Record Buffer" temporary; SerialNoFilter: Text; LotNoFilter: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocNoFilter: Text; PostingDateFilter: Text; ExtDocNo: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocNoFilter: Text; PostingDateFilter: Text; ExtDocNo: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindBankAccountLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; DocNoFilter: Text; PostingDateFilter: Text; ExtDocNo: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindGLEntry(var GLEntry: Record "G/L Entry"; DocNoFilter: Text; PostingDateFilter: Text; ExtDocNo: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindRecordsSetSources(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; ExtDocNo: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordsOnBeforeMessagePostingDateFilter(DocumentEntry: Record "Document Entry"; PostingDateFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindLedgerEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInit(var DocumentEntry: Record "Document Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindCustEntriesOnAfterSetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindVendEntriesOnAfterSetFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindCustEntriesOnAfterDtldCustLedgEntriesSetFilters(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindVendEntriesOnAfterDtldVendLedgEntriesSetFilters(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindUnpostedSalesDocsOnAfterSetFilters(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSalesShipmentHeaderOnAfterSetFilters(var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindIssuedFinChrgMemoHeaderOnAfterSetFilters(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindReminderEntriesOnAfterSetFilters(var ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindGLEntriesOnAfterSetFilters(var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindIssuedReminderHeaderOnAfterSetFilters(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindFAEntriesOnAfterSetFilters(var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPurchRcptHeaderOnAfterSetFilters(var PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBankEntriesOnAfterSetFilters(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrint(var Rec: Record "Document Entry"; SearchBasedOn: Enum "Navigate Search Type"; var TempRecordBuffer: Record "Record Buffer"; var ItemTrackingFilters: Record Item; DocNoFilter: Text; PostingDateFilter: Text; var IsHandled: Boolean);
    begin
    end;
}
