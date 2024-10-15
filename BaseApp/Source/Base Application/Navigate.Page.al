page 344 Navigate
{
    AdditionalSearchTerms = 'find,search,analyze';
    ApplicationArea = Basic, Suite, FixedAssets, Service, CostAccounting;
    Caption = 'Navigate';
    DataCaptionExpression = GetCaptionText;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Find By';
    SaveValues = false;
    SourceTable = "Document Entry";
    SourceTableTemporary = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Document)
            {
                Caption = 'Document';
                Visible = DocumentVisible;
                field(DocNoFilter; DocNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number of an entry that is used to find all documents that have the same document number. You can enter a new document number in this field to search for another set of documents.';

                    trigger OnValidate()
                    begin
                        SetDocNo(DocNoFilter);
                        ContactType := ContactType::" ";
                        ContactNo := '';
                        ExtDocNo := '';
                        ClearTrackingInfo;
                        DocNoFilterOnAfterValidate;
                        FilterSelectionChanged;
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
                        ContactType := ContactType::" ";
                        ContactNo := '';
                        ExtDocNo := '';
                        ClearTrackingInfo;
                        PostingDateFilterOnAfterValida;
                        FilterSelectionChanged;
                    end;
                }
            }
            group("Business Contact")
            {
                Caption = 'Business Contact';
                Visible = BusinessContactVisible;
                field(ContactType; ContactType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Business Contact Type';
                    OptionCaption = ' ,Vendor,Customer';
                    ToolTip = 'Specifies if you want to search for customers, vendors, or bank accounts. Your choice determines the list that you can access in the Business Contact No. field.';

                    trigger OnValidate()
                    begin
                        SetDocNo('');
                        SetPostingDate('');
                        ClearTrackingInfo;
                        ContactTypeOnAfterValidate;
                        FilterSelectionChanged;
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
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        SetDocNo('');
                        SetPostingDate('');
                        ClearTrackingInfo;
                        ContactNoOnAfterValidate;
                        FilterSelectionChanged;
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
                        ClearTrackingInfo;
                        ExtDocNoOnAfterValidate;
                        FilterSelectionChanged;
                    end;
                }
            }
            group("Item Reference")
            {
                Caption = 'Item Reference';
                Visible = ItemReferenceVisible;
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
                        if SerialNoInformationList.RunModal = ACTION::LookupOK then begin
                            Text := SerialNoInformationList.GetSelectionFilter;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ClearInfo;
                        SerialNoFilterOnAfterValidate;
                        FilterSelectionChanged;
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
                        if LotNoInformationList.RunModal = ACTION::LookupOK then begin
                            Text := LotNoInformationList.GetSelectionFilter;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ClearInfo;
                        LotNoFilterOnAfterValidate;
                        FilterSelectionChanged;
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
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
                field("Table ID"; "Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table that the entry is stored in.';
                    Visible = false;
                }
                field("Table Name"; "Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Related Entries';
                    ToolTip = 'Specifies the name of the table where the Navigate facility has found entries with the selected document number and/or posting date.';
                }
                field("No. of Records"; "No. of Records")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Entries';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of documents that the Navigate facility has found in the table with the selected entries.';

                    trigger OnDrillDown()
                    begin
                        ShowRecords;
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
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'View the related entries of the type that you have chosen.';

                    trigger OnAction()
                    begin
                        ShowRecords;
                    end;
                }
                action(Find)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Fi&nd';
                    Image = Find;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Apply a filter to search on this page.';

                    trigger OnAction()
                    begin
                        FindPush;
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
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        ItemTrackingNavigate: Report "Item Tracking Navigate";
                        DocumentEntries: Report "Document Entries";
                    begin
                        if ItemTrackingSearch then begin
                            Clear(ItemTrackingNavigate);
                            ItemTrackingNavigate.TransferDocEntries(Rec);
                            ItemTrackingNavigate.TransferRecordBuffer(TempRecordBuffer);
                            ItemTrackingNavigate.TransferFilters(SerialNoFilter, LotNoFilter, CDNoFilter, '', '');
                            ItemTrackingNavigate.Run;
                        end else begin
                            DocumentEntries.TransferDocEntries(Rec);
                            DocumentEntries.TransferFilters(DocNoFilter, PostingDateFilter);
                            DocumentEntries.Run;
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

                    trigger OnAction()
                    begin
                        FindBasedOn := FindBasedOn::Document;
                        UpdateFindByGroupsVisibility;
                    end;
                }
                action(FindByBusinessContact)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find by Business Contact';
                    Image = ContactPerson;
                    ToolTip = 'Filter entries based on the specified contact or contact type.';

                    trigger OnAction()
                    begin
                        FindBasedOn := FindBasedOn::"Business Contact";
                        UpdateFindByGroupsVisibility;
                    end;
                }
                action(FindByItemReference)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find by Item Reference';
                    Image = ItemTracking;
                    ToolTip = 'Filter entries based on the specified serial number or lot number.';

                    trigger OnAction()
                    begin
                        FindBasedOn := FindBasedOn::"Item Reference";
                        UpdateFindByGroupsVisibility;
                    end;
                }
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
        FindBasedOn := FindBasedOn::Document;
    end;

    trigger OnOpenPage()
    begin
        UpdateForm := true;
        FindRecordsOnOpen;
    end;

    var
        Text000: Label 'The business contact type was not specified.';
        Text001: Label 'There are no posted records with this external document number.';
        Text002: Label 'Counting records...';
        Text003: Label 'Posted Sales Invoice';
        Text004: Label 'Posted Sales Credit Memo';
        Text005: Label 'Posted Sales Shipment';
        Text006: Label 'Issued Reminder';
        Text007: Label 'Issued Finance Charge Memo';
        Text008: Label 'Posted Purchase Invoice';
        Text009: Label 'Posted Purchase Credit Memo';
        Text010: Label 'Posted Purchase Receipt';
        Text011: Label 'The document number has been used more than once.';
        Text012: Label 'This combination of document number and posting date has been used more than once.';
        Text013: Label 'There are no posted records with this document number.';
        Text014: Label 'There are no posted records with this combination of document number and posting date.';
        Text015: Label 'The search results in too many external documents. Specify a business contact no.';
        Text016: Label 'The search results in too many external documents. Use Navigate from the relevant ledger entries.';
        Text017: Label 'Posted Return Receipt';
        Text018: Label 'Posted Return Shipment';
        Text019: Label 'Posted Transfer Shipment';
        Text020: Label 'Posted Transfer Receipt';
        Text021: Label 'Sales Order';
        Text022: Label 'Sales Invoice';
        Text023: Label 'Sales Return Order';
        Text024: Label 'Sales Credit Memo';
        Text025: Label 'Posted Assembly Order';
        sText003: Label 'Posted Service Invoice';
        sText004: Label 'Posted Service Credit Memo';
        sText005: Label 'Posted Service Shipment';
        sText021: Label 'Service Order';
        sText022: Label 'Service Invoice';
        sText024: Label 'Service Credit Memo';
        Text99000000: Label 'Production Order';
        [SecurityFiltering(SecurityFilter::Filtered)]
        Cust: Record Customer;
        [SecurityFiltering(SecurityFilter::Filtered)]
        Vend: Record Vendor;
        SOSalesHeader: Record "Sales Header";
        SISalesHeader: Record "Sales Header";
        SROSalesHeader: Record "Sales Header";
        SCMSalesHeader: Record "Sales Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesShptHeader: Record "Sales Shipment Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesInvHeader: Record "Sales Invoice Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ReturnRcptHeader: Record "Return Receipt Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SOServHeader: Record "Service Header";
        SIServHeader: Record "Service Header";
        SCMServHeader: Record "Service Header";
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
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
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
        PostedItemRcptHeader: Record "Item Receipt Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedItemShptHeader: Record "Item Shipment Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedFADocHeader: Record "Posted FA Doc. Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedAbsenceHeader: Record "Posted Absence Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlPostedLine: Record "Gen. Journal Line Archive";
        [SecurityFiltering(SecurityFilter::Filtered)]
        VATLedgLineSales: Record "VAT Ledger Line";
        [SecurityFiltering(SecurityFilter::Filtered)]
        VATLedgLinePurch: Record "VAT Ledger Line";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLCorrEntry: Record "G/L Correspondence Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        TaxDiffLedgerEntry: Record "Tax Diff. Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        EmplLedgEntry: Record "Employee Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        EmplAbsenceEntry: Record "Employee Absence Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PayrollLedgEntry: Record "Payroll Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        DtldPayrollLedgEntry: Record "Detailed Payroll Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        TimesheetDetail: Record "Timesheet Detail";
        FilterTokens: Codeunit "Filter Tokens";
        ItemTrackingNavigateMgt: Codeunit "Item Tracking Navigate Mgt.";
        Window: Dialog;
        DocNoFilter: Text;
        PostingDateFilter: Text;
        NewDocNo: Code[30];
        ContactNo: Code[250];
        ExtDocNo: Code[250];
        NewPostingDate: Date;
        DocType: Text[100];
        SourceType: Text[30];
        SourceNo: Code[20];
        SourceName: Text[100];
        ContactType: Option " ",Vendor,Customer;
        DocExists: Boolean;
        NewSerialNo: Code[50];
        NewLotNo: Code[50];
        NewCDNo: Code[30];
        SerialNoFilter: Text;
        LotNoFilter: Text;
        Text12470: Label 'Posted FA Writeoff';
        Text12471: Label 'Posted FA Release';
        Text12472: Label 'Posted FA Movement';
        CDNoFilter: Code[1000];
        NewHROrderNo: Code[20];
        NewHROrderDate: Date;
        [InDataSet]
        ShowEnable: Boolean;
        [InDataSet]
        PrintEnable: Boolean;
        [InDataSet]
        DocTypeEnable: Boolean;
        [InDataSet]
        SourceTypeEnable: Boolean;
        [InDataSet]
        SourceNoEnable: Boolean;
        [InDataSet]
        SourceNameEnable: Boolean;
        UpdateForm: Boolean;
        FindBasedOn: Option Document,"Business Contact","Item Reference";
        [InDataSet]
        DocumentVisible: Boolean;
        [InDataSet]
        BusinessContactVisible: Boolean;
        [InDataSet]
        ItemReferenceVisible: Boolean;
        [InDataSet]
        FilterSelectionChangedTxtVisible: Boolean;
        PageCaptionTxt: Label 'Selected - %1';

    procedure SetDoc(PostingDate: Date; DocNo: Code[30])
    begin
        NewDocNo := DocNo;
        NewPostingDate := PostingDate;
    end;

    local procedure FindExtRecords()
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
                    VendLedgEntry2.SetCurrentKey("External Document No.");
                    VendLedgEntry2.SetFilter("External Document No.", ExtDocNo);
                    VendLedgEntry2.SetFilter("Vendor No.", ContactNo);
                    if VendLedgEntry2.FindSet then begin
                        repeat
                            MakeExtFilter(
                              DateFilter2,
                              VendLedgEntry2."Posting Date",
                              DocNoFilter2,
                              VendLedgEntry2."Document No.");
                        until VendLedgEntry2.Next = 0;
                        SetPostingDate(DateFilter2);
                        SetDocNo(DocNoFilter2);
                        FindRecords;
                        FoundRecords := true;
                    end;
                end;
            ContactType::Customer:
                begin
                    DeleteAll;
                    "Entry No." := 0;
                    FindUnpostedSalesDocs(SOSalesHeader."Document Type"::Order, Text021, SOSalesHeader);
                    FindUnpostedSalesDocs(SISalesHeader."Document Type"::Invoice, Text022, SISalesHeader);
                    FindUnpostedSalesDocs(SROSalesHeader."Document Type"::"Return Order", Text023, SROSalesHeader);
                    FindUnpostedSalesDocs(SCMSalesHeader."Document Type"::"Credit Memo", Text024, SCMSalesHeader);
                    if SalesShptHeader.ReadPermission then begin
                        SalesShptHeader.Reset;
                        SalesShptHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
                        SalesShptHeader.SetFilter("Sell-to Customer No.", ContactNo);
                        SalesShptHeader.SetFilter("External Document No.", ExtDocNo);
                        InsertIntoDocEntry(Rec, DATABASE::"Sales Shipment Header", 0, Text005, SalesShptHeader.Count);
                    end;
                    if SalesInvHeader.ReadPermission then begin
                        SalesInvHeader.Reset;
                        SalesInvHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
                        SalesInvHeader.SetFilter("Sell-to Customer No.", ContactNo);
                        SalesInvHeader.SetFilter("External Document No.", ExtDocNo);
                        InsertIntoDocEntry(Rec, DATABASE::"Sales Invoice Header", 0, Text003, SalesInvHeader.Count);
                    end;
                    if ReturnRcptHeader.ReadPermission then begin
                        ReturnRcptHeader.Reset;
                        ReturnRcptHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
                        ReturnRcptHeader.SetFilter("Sell-to Customer No.", ContactNo);
                        ReturnRcptHeader.SetFilter("External Document No.", ExtDocNo);
                        InsertIntoDocEntry(Rec, DATABASE::"Return Receipt Header", 0, Text017, ReturnRcptHeader.Count);
                    end;
                    if SalesCrMemoHeader.ReadPermission then begin
                        SalesCrMemoHeader.Reset;
                        SalesCrMemoHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
                        SalesCrMemoHeader.SetFilter("Sell-to Customer No.", ContactNo);
                        SalesCrMemoHeader.SetFilter("External Document No.", ExtDocNo);
                        InsertIntoDocEntry(Rec, DATABASE::"Sales Cr.Memo Header", 0, Text004, SalesCrMemoHeader.Count);
                    end;
                    FindUnpostedServDocs(SOServHeader."Document Type"::Order, sText021, SOServHeader);
                    FindUnpostedServDocs(SIServHeader."Document Type"::Invoice, sText022, SIServHeader);
                    FindUnpostedServDocs(SCMServHeader."Document Type"::"Credit Memo", sText024, SCMServHeader);
                    if ServShptHeader.ReadPermission then
                        if ExtDocNo = '' then begin
                            ServShptHeader.Reset;
                            ServShptHeader.SetCurrentKey("Customer No.");
                            ServShptHeader.SetFilter("Customer No.", ContactNo);
                            InsertIntoDocEntry(Rec, DATABASE::"Service Shipment Header", 0, sText005, ServShptHeader.Count);
                        end;
                    if ServInvHeader.ReadPermission then
                        if ExtDocNo = '' then begin
                            ServInvHeader.Reset;
                            ServInvHeader.SetCurrentKey("Customer No.");
                            ServInvHeader.SetFilter("Customer No.", ContactNo);
                            InsertIntoDocEntry(Rec, DATABASE::"Service Invoice Header", 0, sText003, ServInvHeader.Count);
                        end;
                    if ServCrMemoHeader.ReadPermission then
                        if ExtDocNo = '' then begin
                            ServCrMemoHeader.Reset;
                            ServCrMemoHeader.SetCurrentKey("Customer No.");
                            ServCrMemoHeader.SetFilter("Customer No.", ContactNo);
                            InsertIntoDocEntry(Rec, DATABASE::"Service Cr.Memo Header", 0, sText004, ServCrMemoHeader.Count);
                        end;

                    DocExists := FindFirst;

                    UpdateFormAfterFindRecords;
                    FoundRecords := DocExists;
                end;
            else
                Error(Text000);
        end;

        if not FoundRecords then begin
            SetSource(0D, '', '', 0, '');
            Message(Text001);
        end;
    end;

    local procedure FindRecords()
    var
        DocType2: Text[100];
        DocNo2: Code[20];
        SourceType2: Integer;
        SourceNo2: Code[20];
        PostingDate: Date;
        IsSourceUpdated: Boolean;
        HideDialog: Boolean;
    begin
        OnBeforeFindRecords(HideDialog);
        if not HideDialog then
            Window.Open(Text002);
        Reset;
        DeleteAll;
        "Entry No." := 0;

        FindPostedDocuments;
        FindLedgerEntries;

        OnAfterNavigateFindRecords(Rec, DocNoFilter, PostingDateFilter);
        DocExists := FindFirst;

        SetSource(0D, '', '', 0, '');
        if DocExists then begin
            if (NoOfRecords(DATABASE::"Cust. Ledger Entry") + NoOfRecords(DATABASE::"Vendor Ledger Entry") <= 1) and
               (GetDocumentCount <= 1)
            then begin
                SetSourceForService;
                SetSourceForSales;
                SetSourceForPurchase;
                SetSourceForServiceDoc;

                IsSourceUpdated := false;
                OnFindRecordsOnAfterSetSource(
                  Rec, PostingDate, DocType2, DocNo2, SourceType2, SourceNo2, DocNoFilter, PostingDateFilter, IsSourceUpdated);
                if IsSourceUpdated then
                    SetSource(PostingDate, DocType2, DocNo2, SourceType2, SourceNo2);
            end else begin
                if DocNoFilter <> '' then
                    if PostingDateFilter = '' then
                        Message(Text011)
                    else
                        Message(Text012);
            end;
        end else
            if PostingDateFilter = '' then
                Message(Text013)
            else
                Message(Text014);

        OnAfterFindRecords(Rec, DocNoFilter, PostingDateFilter);

        if UpdateForm then
            UpdateFormAfterFindRecords;

        if not HideDialog then
            Window.Close;
    end;

    local procedure FindLedgerEntries()
    begin
        FindGLEntries;
        FindVATEntries;
        FindCustEntries;
        FindReminderEntries;
        FindVendEntries;
        FindInvtEntries;
        FindResEntries;
        FindJobEntries;
        FindBankEntries;
        FindFAEntries;
        FindCapEntries;
        FindWhseEntries;
        FindServEntries;
        FindCostEntries;

        if GLCorrEntry.ReadPermission then begin
            GLCorrEntry.Reset;
            GLCorrEntry.SetCurrentKey("Document No.", "Posting Date");
            GLCorrEntry.SetFilter("Document No.", DocNoFilter);
            GLCorrEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"G/L Correspondence Entry", 0, GLCorrEntry.TableCaption, GLCorrEntry.Count);
        end;
        if GenJnlPostedLine.ReadPermission then begin
            GenJnlPostedLine.Reset;
            GenJnlPostedLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
            GenJnlPostedLine.SetFilter("Document No.", DocNoFilter);
            GenJnlPostedLine.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Gen. Journal Line Archive", 0, GenJnlPostedLine.TableCaption, GenJnlPostedLine.Count);
        end;
        if PostedItemRcptHeader.ReadPermission then begin
            PostedItemRcptHeader.Reset;
            PostedItemRcptHeader.SetFilter("No.", DocNoFilter);
            PostedItemRcptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Item Receipt Header", 0, PostedItemRcptHeader.TableCaption, PostedItemRcptHeader.Count);
        end;
        if PostedItemShptHeader.ReadPermission then begin
            PostedItemShptHeader.Reset;
            PostedItemShptHeader.SetFilter("No.", DocNoFilter);
            PostedItemShptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Item Shipment Header", 0, PostedItemShptHeader.TableCaption, PostedItemShptHeader.Count);
        end;
        if PostedFADocHeader.ReadPermission then begin
            PostedFADocHeader.Reset;
            PostedFADocHeader.SetFilter("No.", DocNoFilter);
            PostedFADocHeader.SetFilter("FA Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Posted FA Doc. Header", 0, PostedFADocHeader.TableCaption, PostedFADocHeader.Count);
        end;
        if VATLedgLinePurch.ReadPermission then begin
            VATLedgLinePurch.Reset;
            VATLedgLinePurch.SetCurrentKey("Document No.", "Document Date");
            VATLedgLinePurch.SetFilter("Document No.", DocNoFilter);
            VATLedgLinePurch.SetFilter("Document Date", PostingDateFilter);
            VATLedgLinePurch.SetRange(Type, VATLedgLinePurch.Type::Purchase);
            InsertIntoDocEntry(Rec, DATABASE::"VAT Ledger Line", 0, VATLedgLinePurch.TableCaption, VATLedgLinePurch.Count);
        end;
        if VATLedgLineSales.ReadPermission then begin
            VATLedgLineSales.Reset;
            VATLedgLineSales.SetCurrentKey("Document No.", "Document Date");
            VATLedgLineSales.SetFilter("Document No.", DocNoFilter);
            VATLedgLineSales.SetFilter("Document Date", PostingDateFilter);
            VATLedgLineSales.SetRange(Type, VATLedgLineSales.Type::Sales);
            InsertIntoDocEntry(Rec, DATABASE::"VAT Ledger Line", 0, VATLedgLineSales.TableCaption, VATLedgLineSales.Count);
        end;
        if TaxDiffLedgerEntry.ReadPermission then begin
            TaxDiffLedgerEntry.Reset;
            TaxDiffLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
            TaxDiffLedgerEntry.SetFilter("Document No.", DocNoFilter);
            TaxDiffLedgerEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Tax Diff. Ledger Entry", 0, TaxDiffLedgerEntry.TableCaption, TaxDiffLedgerEntry.Count);
        end;

        // HRP
        if PostedAbsenceHeader.ReadPermission then begin
            PostedAbsenceHeader.Reset;
            PostedAbsenceHeader.SetFilter("No.", DocNoFilter);
            PostedAbsenceHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Posted Absence Header", 0, PostedAbsenceHeader.TableCaption, PostedAbsenceHeader.Count);
        end;
        if EmplLedgEntry.ReadPermission then begin
            EmplLedgEntry.Reset;
            EmplLedgEntry.SetCurrentKey("Document No.", "Document Date");
            EmplLedgEntry.SetFilter("Document No.", DocNoFilter);
            EmplLedgEntry.SetFilter("Document Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Employee Ledger Entry", 0, EmplLedgEntry.TableCaption, EmplLedgEntry.Count);
        end;
        if EmplAbsenceEntry.ReadPermission then begin
            EmplAbsenceEntry.Reset;
            EmplAbsenceEntry.SetCurrentKey("Document No.", "Document Date");
            EmplAbsenceEntry.SetFilter("Document No.", DocNoFilter);
            EmplAbsenceEntry.SetFilter("Document Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Employee Absence Entry", 0, EmplAbsenceEntry.TableCaption, EmplAbsenceEntry.Count);
        end;
        if TimesheetDetail.ReadPermission then begin
            TimesheetDetail.Reset;
            TimesheetDetail.SetCurrentKey("Document No.", "Document Date");
            TimesheetDetail.SetFilter("Document No.", DocNoFilter);
            TimesheetDetail.SetFilter("Document Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Timesheet Detail", 0, TimesheetDetail.TableCaption, TimesheetDetail.Count);
        end;
        if PayrollLedgEntry.ReadPermission then begin
            PayrollLedgEntry.Reset;
            PayrollLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            PayrollLedgEntry.SetFilter("Document No.", DocNoFilter);
            PayrollLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Payroll Ledger Entry", 0, PayrollLedgEntry.TableCaption, PayrollLedgEntry.Count);
            if (NewHROrderNo <> '') and (NewHROrderDate <> 0D) then begin
                PayrollLedgEntry.Reset;
                PayrollLedgEntry.SetCurrentKey("HR Order No.", "HR Order Date");
                PayrollLedgEntry.SetRange("HR Order No.", NewHROrderNo);
                PayrollLedgEntry.SetRange("HR Order Date", NewHROrderDate);
                InsertIntoDocEntry(Rec, DATABASE::"Payroll Ledger Entry", 0, PayrollLedgEntry.TableCaption, PayrollLedgEntry.Count);
            end;
        end;
        if DtldPayrollLedgEntry.ReadPermission then begin
            DtldPayrollLedgEntry.Reset;
            DtldPayrollLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            DtldPayrollLedgEntry.SetFilter("Document No.", DocNoFilter);
            DtldPayrollLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(
              Rec, DATABASE::"Detailed Payroll Ledger Entry", 0, DtldPayrollLedgEntry.TableCaption, DtldPayrollLedgEntry.Count);
            if (NewHROrderNo <> '') and (NewHROrderDate <> 0D) then begin
                DtldPayrollLedgEntry.Reset;
                DtldPayrollLedgEntry.SetCurrentKey("HR Order No.", "HR Order Date");
                DtldPayrollLedgEntry.SetRange("HR Order No.", NewHROrderNo);
                DtldPayrollLedgEntry.SetRange("HR Order Date", NewHROrderDate);
                InsertIntoDocEntry(
                  Rec, DATABASE::"Detailed Payroll Ledger Entry", 0, DtldPayrollLedgEntry.TableCaption, DtldPayrollLedgEntry.Count);
            end;
        end;
    end;

    local procedure FindCustEntries()
    begin
        if CustLedgEntry.ReadPermission then begin
            CustLedgEntry.Reset;
            CustLedgEntry.SetCurrentKey("Document No.");
            CustLedgEntry.SetFilter("Document No.", DocNoFilter);
            CustLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Cust. Ledger Entry", 0, CustLedgEntry.TableCaption, CustLedgEntry.Count);
        end;
        if DtldCustLedgEntry.ReadPermission then begin
            DtldCustLedgEntry.Reset;
            DtldCustLedgEntry.SetCurrentKey("Document No.");
            DtldCustLedgEntry.SetFilter("Document No.", DocNoFilter);
            DtldCustLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Detailed Cust. Ledg. Entry", 0, DtldCustLedgEntry.TableCaption, DtldCustLedgEntry.Count);
        end;
    end;

    local procedure FindVendEntries()
    begin
        if VendLedgEntry.ReadPermission then begin
            VendLedgEntry.Reset;
            VendLedgEntry.SetCurrentKey("Document No.");
            VendLedgEntry.SetFilter("Document No.", DocNoFilter);
            VendLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Vendor Ledger Entry", 0, VendLedgEntry.TableCaption, VendLedgEntry.Count);
        end;
        if DtldVendLedgEntry.ReadPermission then begin
            DtldVendLedgEntry.Reset;
            DtldVendLedgEntry.SetCurrentKey("Document No.");
            DtldVendLedgEntry.SetFilter("Document No.", DocNoFilter);
            DtldVendLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Detailed Vendor Ledg. Entry", 0, DtldVendLedgEntry.TableCaption, DtldVendLedgEntry.Count);
        end;
    end;

    local procedure FindBankEntries()
    begin
        if BankAccLedgEntry.ReadPermission then begin
            BankAccLedgEntry.Reset;
            BankAccLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            BankAccLedgEntry.SetFilter("Document No.", DocNoFilter);
            BankAccLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Bank Account Ledger Entry", 0, BankAccLedgEntry.TableCaption, BankAccLedgEntry.Count);
        end;
        if CheckLedgEntry.ReadPermission then begin
            CheckLedgEntry.Reset;
            CheckLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            CheckLedgEntry.SetFilter("Document No.", DocNoFilter);
            CheckLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Check Ledger Entry", 0, CheckLedgEntry.TableCaption, CheckLedgEntry.Count);
        end;
    end;

    local procedure FindGLEntries()
    begin
        if GLEntry.ReadPermission then begin
            GLEntry.Reset;
            GLEntry.SetCurrentKey("Document No.", "Posting Date");
            GLEntry.SetFilter("Document No.", DocNoFilter);
            GLEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"G/L Entry", 0, GLEntry.TableCaption, GLEntry.Count);
        end;
    end;

    local procedure FindVATEntries()
    begin
        if VATEntry.ReadPermission then begin
            VATEntry.Reset;
            VATEntry.SetCurrentKey("Document No.", "Posting Date");
            VATEntry.SetFilter("Document No.", DocNoFilter);
            VATEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"VAT Entry", 0, VATEntry.TableCaption, VATEntry.Count);
        end;
    end;

    local procedure FindFAEntries()
    begin
        if FALedgEntry.ReadPermission then begin
            FALedgEntry.Reset;
            FALedgEntry.SetCurrentKey("Document No.", "Posting Date");
            FALedgEntry.SetFilter("Document No.", DocNoFilter);
            FALedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"FA Ledger Entry", 0, FALedgEntry.TableCaption, FALedgEntry.Count);
        end;
        if MaintenanceLedgEntry.ReadPermission then begin
            MaintenanceLedgEntry.Reset;
            MaintenanceLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            MaintenanceLedgEntry.SetFilter("Document No.", DocNoFilter);
            MaintenanceLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Maintenance Ledger Entry", 0, MaintenanceLedgEntry.TableCaption, MaintenanceLedgEntry.Count);
        end;
        if InsuranceCovLedgEntry.ReadPermission then begin
            InsuranceCovLedgEntry.Reset;
            InsuranceCovLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            InsuranceCovLedgEntry.SetFilter("Document No.", DocNoFilter);
            InsuranceCovLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(
              Rec, DATABASE::"Ins. Coverage Ledger Entry", 0, InsuranceCovLedgEntry.TableCaption, InsuranceCovLedgEntry.Count);
        end;
    end;

    local procedure FindInvtEntries()
    begin
        if ItemLedgEntry.ReadPermission then begin
            ItemLedgEntry.Reset;
            ItemLedgEntry.SetCurrentKey("Document No.");
            ItemLedgEntry.SetFilter("Document No.", DocNoFilter);
            ItemLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Item Ledger Entry", 0, ItemLedgEntry.TableCaption, ItemLedgEntry.Count);
        end;
        if ValueEntry.ReadPermission then begin
            ValueEntry.Reset;
            ValueEntry.SetCurrentKey("Document No.");
            ValueEntry.SetFilter("Document No.", DocNoFilter);
            ValueEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Value Entry", 0, ValueEntry.TableCaption, ValueEntry.Count);
        end;
        if PhysInvtLedgEntry.ReadPermission then begin
            PhysInvtLedgEntry.Reset;
            PhysInvtLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            PhysInvtLedgEntry.SetFilter("Document No.", DocNoFilter);
            PhysInvtLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Phys. Inventory Ledger Entry", 0, PhysInvtLedgEntry.TableCaption, PhysInvtLedgEntry.Count);
        end;
    end;

    local procedure FindReminderEntries()
    begin
        if ReminderEntry.ReadPermission then begin
            ReminderEntry.Reset;
            ReminderEntry.SetCurrentKey(Type, "No.");
            ReminderEntry.SetFilter("No.", DocNoFilter);
            ReminderEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Reminder/Fin. Charge Entry", 0, ReminderEntry.TableCaption, ReminderEntry.Count);
        end;
    end;

    local procedure FindResEntries()
    begin
        if ResLedgEntry.ReadPermission then begin
            ResLedgEntry.Reset;
            ResLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            ResLedgEntry.SetFilter("Document No.", DocNoFilter);
            ResLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Res. Ledger Entry", 0, ResLedgEntry.TableCaption, ResLedgEntry.Count);
        end;
    end;

    local procedure FindServEntries()
    begin
        if ServLedgerEntry.ReadPermission then begin
            ServLedgerEntry.Reset;
            ServLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
            ServLedgerEntry.SetFilter("Document No.", DocNoFilter);
            ServLedgerEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Service Ledger Entry", 0, ServLedgerEntry.TableCaption, ServLedgerEntry.Count);
        end;
        if WarrantyLedgerEntry.ReadPermission then begin
            WarrantyLedgerEntry.Reset;
            WarrantyLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
            WarrantyLedgerEntry.SetFilter("Document No.", DocNoFilter);
            WarrantyLedgerEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Warranty Ledger Entry", 0, WarrantyLedgerEntry.TableCaption, WarrantyLedgerEntry.Count);
        end;
    end;

    local procedure FindCapEntries()
    begin
        if CapacityLedgEntry.ReadPermission then begin
            CapacityLedgEntry.Reset;
            CapacityLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            CapacityLedgEntry.SetFilter("Document No.", DocNoFilter);
            CapacityLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Capacity Ledger Entry", 0, CapacityLedgEntry.TableCaption, CapacityLedgEntry.Count);
        end;
    end;

    local procedure FindCostEntries()
    begin
        if CostEntry.ReadPermission then begin
            CostEntry.Reset;
            CostEntry.SetCurrentKey("Document No.", "Posting Date");
            CostEntry.SetFilter("Document No.", DocNoFilter);
            CostEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Cost Entry", 0, CostEntry.TableCaption, CostEntry.Count);
        end;
    end;

    local procedure FindWhseEntries()
    begin
        if WhseEntry.ReadPermission then begin
            WhseEntry.Reset;
            WhseEntry.SetCurrentKey("Reference No.", "Registering Date");
            WhseEntry.SetFilter("Reference No.", DocNoFilter);
            WhseEntry.SetFilter("Registering Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Warehouse Entry", 0, WhseEntry.TableCaption, WhseEntry.Count);
        end;
    end;

    local procedure FindJobEntries()
    begin
        if JobLedgEntry.ReadPermission then begin
            JobLedgEntry.Reset;
            JobLedgEntry.SetCurrentKey("Document No.", "Posting Date");
            JobLedgEntry.SetFilter("Document No.", DocNoFilter);
            JobLedgEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Job Ledger Entry", 0, JobLedgEntry.TableCaption, JobLedgEntry.Count);
        end;
        if JobWIPEntry.ReadPermission then begin
            JobWIPEntry.Reset;
            JobWIPEntry.SetFilter("Document No.", DocNoFilter);
            JobWIPEntry.SetFilter("WIP Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Job WIP Entry", 0, JobWIPEntry.TableCaption, JobWIPEntry.Count);
        end;
        if JobWIPGLEntry.ReadPermission then begin
            JobWIPGLEntry.Reset;
            JobWIPGLEntry.SetCurrentKey("Document No.", "Posting Date");
            JobWIPGLEntry.SetFilter("Document No.", DocNoFilter);
            JobWIPGLEntry.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Job WIP G/L Entry", 0, JobWIPGLEntry.TableCaption, JobWIPGLEntry.Count);
        end;
    end;

    local procedure FindPostedDocuments()
    begin
        FindIncomingDocumentRecords;
        FindSalesShipmentHeader;
        FindSalesInvoiceHeader;
        FindReturnRcptHeader;
        FindSalesCrMemoHeader;
        FindServShipmentHeader;
        FindServInvoiceHeader;
        FindServCrMemoHeader;
        FindIssuedReminderHeader;
        FindIssuedFinChrgMemoHeader;
        FindPurchRcptHeader;
        FindPurchInvoiceHeader;
        FindReturnShptHeader;
        FindPurchCrMemoHeader;
        FindProdOrderHeader;
        FindPostedAssemblyHeader;
        FindTransShptHeader;
        FindTransRcptHeader;
        FindPstdPhysInvtOrderHdr;
        FindPostedWhseShptLine;
        FindPostedWhseRcptLine;
    end;

    local procedure FindIncomingDocumentRecords()
    begin
        if IncomingDocument.ReadPermission then begin
            IncomingDocument.Reset;
            IncomingDocument.SetFilter("Document No.", DocNoFilter);
            IncomingDocument.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Incoming Document", 0, IncomingDocument.TableCaption, IncomingDocument.Count);
        end;
    end;

    local procedure FindSalesShipmentHeader()
    begin
        if SalesShptHeader.ReadPermission then begin
            SalesShptHeader.Reset;
            SalesShptHeader.SetFilter("No.", DocNoFilter);
            SalesShptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Sales Shipment Header", 0, Text005, SalesShptHeader.Count);
        end;
    end;

    local procedure FindSalesInvoiceHeader()
    begin
        if SalesInvHeader.ReadPermission then begin
            SalesInvHeader.Reset;
            SalesInvHeader.SetFilter("No.", DocNoFilter);
            SalesInvHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Sales Invoice Header", 0, Text003, SalesInvHeader.Count);
        end;
    end;

    local procedure FindSalesCrMemoHeader()
    begin
        if SalesCrMemoHeader.ReadPermission then begin
            SalesCrMemoHeader.Reset;
            SalesCrMemoHeader.SetFilter("No.", DocNoFilter);
            SalesCrMemoHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Sales Cr.Memo Header", 0, Text004, SalesCrMemoHeader.Count);
        end;
    end;

    local procedure FindReturnRcptHeader()
    begin
        if ReturnRcptHeader.ReadPermission then begin
            ReturnRcptHeader.Reset;
            ReturnRcptHeader.SetFilter("No.", DocNoFilter);
            ReturnRcptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Return Receipt Header", 0, Text017, ReturnRcptHeader.Count);
        end;
    end;

    local procedure FindServShipmentHeader()
    begin
        if ServShptHeader.ReadPermission then begin
            ServShptHeader.Reset;
            ServShptHeader.SetFilter("No.", DocNoFilter);
            ServShptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Service Shipment Header", 0, sText005, ServShptHeader.Count);
        end;
    end;

    local procedure FindServInvoiceHeader()
    begin
        if ServInvHeader.ReadPermission then begin
            ServInvHeader.Reset;
            ServInvHeader.SetFilter("No.", DocNoFilter);
            ServInvHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Service Invoice Header", 0, sText003, ServInvHeader.Count);
        end;
    end;

    local procedure FindServCrMemoHeader()
    begin
        if ServCrMemoHeader.ReadPermission then begin
            ServCrMemoHeader.Reset;
            ServCrMemoHeader.SetFilter("No.", DocNoFilter);
            ServCrMemoHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Service Cr.Memo Header", 0, sText004, ServCrMemoHeader.Count);
        end;
    end;

    local procedure FindIssuedReminderHeader()
    begin
        if IssuedReminderHeader.ReadPermission then begin
            IssuedReminderHeader.Reset;
            IssuedReminderHeader.SetFilter("No.", DocNoFilter);
            IssuedReminderHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Issued Reminder Header", 0, Text006, IssuedReminderHeader.Count);
        end;
    end;

    local procedure FindIssuedFinChrgMemoHeader()
    begin
        if IssuedFinChrgMemoHeader.ReadPermission then begin
            IssuedFinChrgMemoHeader.Reset;
            IssuedFinChrgMemoHeader.SetFilter("No.", DocNoFilter);
            IssuedFinChrgMemoHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Issued Fin. Charge Memo Header", 0, Text007,
              IssuedFinChrgMemoHeader.Count);
        end;
    end;

    local procedure FindPurchRcptHeader()
    begin
        if PurchRcptHeader.ReadPermission then begin
            PurchRcptHeader.Reset;
            PurchRcptHeader.SetFilter("No.", DocNoFilter);
            PurchRcptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Purch. Rcpt. Header", 0, Text010, PurchRcptHeader.Count);
        end;
    end;

    local procedure FindPurchInvoiceHeader()
    begin
        if PurchInvHeader.ReadPermission then begin
            PurchInvHeader.Reset;
            PurchInvHeader.SetFilter("No.", DocNoFilter);
            PurchInvHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Purch. Inv. Header", 0, Text008, PurchInvHeader.Count);
        end;
    end;

    local procedure FindPurchCrMemoHeader()
    begin
        if PurchCrMemoHeader.ReadPermission then begin
            PurchCrMemoHeader.Reset;
            PurchCrMemoHeader.SetFilter("No.", DocNoFilter);
            PurchCrMemoHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Purch. Cr. Memo Hdr.", 0, Text009, PurchCrMemoHeader.Count);
        end;
    end;

    local procedure FindReturnShptHeader()
    begin
        if ReturnShptHeader.ReadPermission then begin
            ReturnShptHeader.Reset;
            ReturnShptHeader.SetFilter("No.", DocNoFilter);
            ReturnShptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Return Shipment Header", 0, Text018, ReturnShptHeader.Count);
        end;
    end;

    local procedure FindProdOrderHeader()
    begin
        if ProductionOrderHeader.ReadPermission then begin
            ProductionOrderHeader.Reset;
            ProductionOrderHeader.SetRange(
              Status,
              ProductionOrderHeader.Status::Released,
              ProductionOrderHeader.Status::Finished);
            ProductionOrderHeader.SetFilter("No.", DocNoFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Production Order", 0, Text99000000, ProductionOrderHeader.Count);
        end;
    end;

    local procedure FindPostedAssemblyHeader()
    begin
        if PostedAssemblyHeader.ReadPermission then begin
            PostedAssemblyHeader.Reset;
            PostedAssemblyHeader.SetFilter("No.", DocNoFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Posted Assembly Header", 0, Text025, PostedAssemblyHeader.Count);
        end;
    end;

    local procedure FindPostedWhseShptLine()
    begin
        if PostedWhseShptLine.ReadPermission then begin
            PostedWhseShptLine.Reset;
            PostedWhseShptLine.SetCurrentKey("Posted Source No.", "Posting Date");
            PostedWhseShptLine.SetFilter("Posted Source No.", DocNoFilter);
            PostedWhseShptLine.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Posted Whse. Shipment Line", 0,
              PostedWhseShptLine.TableCaption, PostedWhseShptLine.Count);
        end;
    end;

    local procedure FindPostedWhseRcptLine()
    begin
        if PostedWhseRcptLine.ReadPermission then begin
            PostedWhseRcptLine.Reset;
            PostedWhseRcptLine.SetCurrentKey("Posted Source No.", "Posting Date");
            PostedWhseRcptLine.SetFilter("Posted Source No.", DocNoFilter);
            PostedWhseRcptLine.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Posted Whse. Receipt Line", 0,
              PostedWhseRcptLine.TableCaption, PostedWhseRcptLine.Count);
        end;
    end;

    local procedure FindPstdPhysInvtOrderHdr()
    begin
        if PstdPhysInvtOrderHdr.ReadPermission then begin
            PstdPhysInvtOrderHdr.Reset;
            PstdPhysInvtOrderHdr.SetFilter("No.", DocNoFilter);
            PstdPhysInvtOrderHdr.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec,
              DATABASE::"Pstd. Phys. Invt. Order Hdr", 0, PstdPhysInvtOrderHdr.TableCaption, PstdPhysInvtOrderHdr.Count);
        end;
    end;

    local procedure FindTransShptHeader()
    begin
        if TransShptHeader.ReadPermission then begin
            TransShptHeader.Reset;
            TransShptHeader.SetFilter("No.", DocNoFilter);
            TransShptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Transfer Shipment Header", 0, Text019, TransShptHeader.Count);
        end;
    end;

    local procedure FindTransRcptHeader()
    begin
        if TransRcptHeader.ReadPermission then begin
            TransRcptHeader.Reset;
            TransRcptHeader.SetFilter("No.", DocNoFilter);
            TransRcptHeader.SetFilter("Posting Date", PostingDateFilter);
            InsertIntoDocEntry(Rec, DATABASE::"Transfer Receipt Header", 0, Text020, TransRcptHeader.Count);
        end;
    end;

    local procedure UpdateFormAfterFindRecords()
    begin
        OnBeforeUpdateFormAfterFindRecords;

        ShowEnable := DocExists;
        PrintEnable := DocExists;
        CurrPage.Update(false);
        DocExists := FindFirst;
        if DocExists then;
    end;

    procedure InsertIntoDocEntry(var TempDocumentEntry: Record "Document Entry" temporary; DocTableID: Integer; DocType: Option; DocTableName: Text[1024]; DocNoOfRecords: Integer)
    begin
        if DocNoOfRecords = 0 then
            exit;

        with TempDocumentEntry do begin
            Init;
            "Entry No." := "Entry No." + 1;
            "Table ID" := DocTableID;
            "Document Type" := DocType;
            "Table Name" := CopyStr(DocTableName, 1, MaxStrLen("Table Name"));
            "No. of Records" := DocNoOfRecords;
            Insert;
        end;
    end;

    local procedure NoOfRecords(TableID: Integer): Integer
    begin
        SetRange("Table ID", TableID);
        if not FindFirst then
            Init;
        SetRange("Table ID");
        exit("No. of Records");
    end;

    local procedure SetSource(PostingDate: Date; DocType2: Text[100]; DocNo: Text[50]; SourceType2: Integer; SourceNo2: Code[20])
    begin
        if SourceType2 = 0 then begin
            DocType := '';
            SourceType := '';
            SourceNo := '';
            SourceName := '';
        end else begin
            DocType := DocType2;
            SourceNo := SourceNo2;
            SetRange("Document No.", DocNo);
            SetRange("Posting Date", PostingDate);
            DocNoFilter := GetFilter("Document No.");
            PostingDateFilter := GetFilter("Posting Date");
            case SourceType2 of
                1:
                    begin
                        SourceType := Cust.TableCaption;
                        if not Cust.Get(SourceNo) then
                            Cust.Init;
                        SourceName := Cust.Name;
                    end;
                2:
                    begin
                        SourceType := Vend.TableCaption;
                        if not Vend.Get(SourceNo) then
                            Vend.Init;
                        SourceName := Vend.Name;
                    end;
            end;
        end;
        DocTypeEnable := SourceType2 <> 0;
        SourceTypeEnable := SourceType2 <> 0;
        SourceNoEnable := SourceType2 <> 0;
        SourceNameEnable := SourceType2 <> 0;
    end;

    local procedure SetSourceForPurchase()
    begin
        if NoOfRecords(DATABASE::"Vendor Ledger Entry") = 1 then begin
            VendLedgEntry.FindFirst;
            SetSource(
              VendLedgEntry."Posting Date", Format(VendLedgEntry."Document Type"), VendLedgEntry."Document No.",
              2, VendLedgEntry."Vendor No.");
        end;
        if NoOfRecords(DATABASE::"Detailed Vendor Ledg. Entry") = 1 then begin
            DtldVendLedgEntry.FindFirst;
            SetSource(
              DtldVendLedgEntry."Posting Date", Format(DtldVendLedgEntry."Document Type"), DtldVendLedgEntry."Document No.",
              2, DtldVendLedgEntry."Vendor No.");
        end;
        if NoOfRecords(DATABASE::"Purch. Inv. Header") = 1 then begin
            PurchInvHeader.FindFirst;
            SetSource(
              PurchInvHeader."Posting Date", Format("Table Name"), PurchInvHeader."No.",
              2, PurchInvHeader."Pay-to Vendor No.");
        end;
        if NoOfRecords(DATABASE::"Purch. Cr. Memo Hdr.") = 1 then begin
            PurchCrMemoHeader.FindFirst;
            SetSource(
              PurchCrMemoHeader."Posting Date", Format("Table Name"), PurchCrMemoHeader."No.",
              2, PurchCrMemoHeader."Pay-to Vendor No.");
        end;
        if NoOfRecords(DATABASE::"Return Shipment Header") = 1 then begin
            ReturnShptHeader.FindFirst;
            SetSource(
              ReturnShptHeader."Posting Date", Format("Table Name"), ReturnShptHeader."No.",
              2, ReturnShptHeader."Buy-from Vendor No.");
        end;
        if NoOfRecords(DATABASE::"Purch. Rcpt. Header") = 1 then begin
            PurchRcptHeader.FindFirst;
            SetSource(
              PurchRcptHeader."Posting Date", Format("Table Name"), PurchRcptHeader."No.",
              2, PurchRcptHeader."Buy-from Vendor No.");
        end;
        if NoOfRecords(DATABASE::"Posted Whse. Receipt Line") = 1 then begin
            PostedWhseRcptLine.FindFirst;
            SetSource(
              PostedWhseRcptLine."Posting Date", Format("Table Name"), PostedWhseRcptLine."Posted Source No.",
              2, '');
        end;
        if NoOfRecords(DATABASE::"Pstd. Phys. Invt. Order Hdr") = 1 then begin
            PstdPhysInvtOrderHdr.FindFirst;
            SetSource(
              PstdPhysInvtOrderHdr."Posting Date", Format("Table Name"), PstdPhysInvtOrderHdr."No.",
              3, '');
        end;
    end;

    local procedure SetSourceForSales()
    begin
        if NoOfRecords(DATABASE::"Cust. Ledger Entry") = 1 then begin
            CustLedgEntry.FindFirst;
            SetSource(
              CustLedgEntry."Posting Date", Format(CustLedgEntry."Document Type"), CustLedgEntry."Document No.",
              1, CustLedgEntry."Customer No.");
        end;
        if NoOfRecords(DATABASE::"Detailed Cust. Ledg. Entry") = 1 then begin
            DtldCustLedgEntry.FindFirst;
            SetSource(
              DtldCustLedgEntry."Posting Date", Format(DtldCustLedgEntry."Document Type"), DtldCustLedgEntry."Document No.",
              1, DtldCustLedgEntry."Customer No.");
        end;
        if NoOfRecords(DATABASE::"Sales Invoice Header") = 1 then begin
            SalesInvHeader.FindFirst;
            SetSource(
              SalesInvHeader."Posting Date", Format("Table Name"), SalesInvHeader."No.",
              1, SalesInvHeader."Bill-to Customer No.");
        end;
        if NoOfRecords(DATABASE::"Sales Cr.Memo Header") = 1 then begin
            SalesCrMemoHeader.FindFirst;
            SetSource(
              SalesCrMemoHeader."Posting Date", Format("Table Name"), SalesCrMemoHeader."No.",
              1, SalesCrMemoHeader."Bill-to Customer No.");
        end;
        if NoOfRecords(DATABASE::"Return Receipt Header") = 1 then begin
            ReturnRcptHeader.FindFirst;
            SetSource(
              ReturnRcptHeader."Posting Date", Format("Table Name"), ReturnRcptHeader."No.",
              1, ReturnRcptHeader."Sell-to Customer No.");
        end;
        if NoOfRecords(DATABASE::"Sales Shipment Header") = 1 then begin
            SalesShptHeader.FindFirst;
            SetSource(
              SalesShptHeader."Posting Date", Format("Table Name"), SalesShptHeader."No.",
              1, SalesShptHeader."Sell-to Customer No.");
        end;
        if NoOfRecords(DATABASE::"Posted Whse. Shipment Line") = 1 then begin
            PostedWhseShptLine.FindFirst;
            SetSource(
              PostedWhseShptLine."Posting Date", Format("Table Name"), PostedWhseShptLine."Posted Source No.",
              1, PostedWhseShptLine."Destination No.");
        end;
        if NoOfRecords(DATABASE::"Issued Reminder Header") = 1 then begin
            IssuedReminderHeader.FindFirst;
            SetSource(
              IssuedReminderHeader."Posting Date", Format("Table Name"), IssuedReminderHeader."No.",
              1, IssuedReminderHeader."Customer No.");
        end;
        if NoOfRecords(DATABASE::"Issued Fin. Charge Memo Header") = 1 then begin
            IssuedFinChrgMemoHeader.FindFirst;
            SetSource(
              IssuedFinChrgMemoHeader."Posting Date", Format("Table Name"), IssuedFinChrgMemoHeader."No.",
              1, IssuedFinChrgMemoHeader."Customer No.");
        end;
    end;

    local procedure SetSourceForService()
    begin
        if NoOfRecords(DATABASE::"Service Ledger Entry") = 1 then begin
            ServLedgerEntry.FindFirst;
            if ServLedgerEntry.Type = ServLedgerEntry.Type::"Service Contract" then
                SetSource(
                  ServLedgerEntry."Posting Date", Format(ServLedgerEntry."Document Type"), ServLedgerEntry."Document No.",
                  2, ServLedgerEntry."Service Contract No.")
            else
                SetSource(
                  ServLedgerEntry."Posting Date", Format(ServLedgerEntry."Document Type"), ServLedgerEntry."Document No.",
                  2, ServLedgerEntry."Service Order No.")
        end;
        if NoOfRecords(DATABASE::"Warranty Ledger Entry") = 1 then begin
            WarrantyLedgerEntry.FindFirst;
            SetSource(
              WarrantyLedgerEntry."Posting Date", '', WarrantyLedgerEntry."Document No.",
              2, WarrantyLedgerEntry."Service Order No.")
        end;
    end;

    local procedure SetSourceForServiceDoc()
    begin
        if NoOfRecords(DATABASE::"Service Invoice Header") = 1 then begin
            ServInvHeader.FindFirst;
            SetSource(
              ServInvHeader."Posting Date", Format("Table Name"), ServInvHeader."No.",
              1, ServInvHeader."Bill-to Customer No.");
        end;
        if NoOfRecords(DATABASE::"Service Cr.Memo Header") = 1 then begin
            ServCrMemoHeader.FindFirst;
            SetSource(
              ServCrMemoHeader."Posting Date", Format("Table Name"), ServCrMemoHeader."No.",
              1, ServCrMemoHeader."Bill-to Customer No.");
        end;
        if NoOfRecords(DATABASE::"Service Shipment Header") = 1 then begin
            ServShptHeader.FindFirst;
            SetSource(
              ServShptHeader."Posting Date", Format("Table Name"), ServShptHeader."No.",
              1, ServShptHeader."Customer No.");
        end;
    end;

    local procedure ShowRecords()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNavigateShowRecords(
          "Table ID", DocNoFilter, PostingDateFilter, ItemTrackingSearch, Rec, IsHandled,
          SalesInvHeader, SalesCrMemoHeader, PurchInvHeader, PurchCrMemoHeader, ServInvHeader, ServCrMemoHeader);
        if IsHandled then
            exit;

        if ItemTrackingSearch then
            ItemTrackingNavigateMgt.Show("Table ID")
        else
            case "Table ID" of
                DATABASE::"Incoming Document":
                    PAGE.Run(PAGE::"Incoming Document", IncomingDocument);
                DATABASE::"Sales Header":
                    ShowSalesHeaderRecords;
                DATABASE::"Sales Invoice Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Sales Invoice", SalesInvHeader)
                    else
                        PAGE.Run(PAGE::"Posted Sales Invoices", SalesInvHeader);
                DATABASE::"Sales Cr.Memo Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader)
                    else
                        PAGE.Run(PAGE::"Posted Sales Credit Memos", SalesCrMemoHeader);
                DATABASE::"Return Receipt Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Return Receipt", ReturnRcptHeader)
                    else
                        PAGE.Run(0, ReturnRcptHeader);
                DATABASE::"Sales Shipment Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Sales Shipment", SalesShptHeader)
                    else
                        PAGE.Run(0, SalesShptHeader);
                DATABASE::"Issued Reminder Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Issued Reminder", IssuedReminderHeader)
                    else
                        PAGE.Run(0, IssuedReminderHeader);
                DATABASE::"Issued Fin. Charge Memo Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Issued Finance Charge Memo", IssuedFinChrgMemoHeader)
                    else
                        PAGE.Run(0, IssuedFinChrgMemoHeader);
                DATABASE::"Purch. Inv. Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Purchase Invoice", PurchInvHeader)
                    else
                        PAGE.Run(PAGE::"Posted Purchase Invoices", PurchInvHeader);
                DATABASE::"Purch. Cr. Memo Hdr.":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHeader)
                    else
                        PAGE.Run(PAGE::"Posted Purchase Credit Memos", PurchCrMemoHeader);
                DATABASE::"Return Shipment Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Return Shipment", ReturnShptHeader)
                    else
                        PAGE.Run(0, ReturnShptHeader);
                DATABASE::"Purch. Rcpt. Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Purchase Receipt", PurchRcptHeader)
                    else
                        PAGE.Run(0, PurchRcptHeader);
                DATABASE::"Production Order":
                    PAGE.Run(0, ProductionOrderHeader);
                DATABASE::"Posted Assembly Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Assembly Order", PostedAssemblyHeader)
                    else
                        PAGE.Run(0, PostedAssemblyHeader);
                DATABASE::"Transfer Shipment Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Transfer Shipment", TransShptHeader)
                    else
                        PAGE.Run(0, TransShptHeader);
                DATABASE::"Transfer Receipt Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Transfer Receipt", TransRcptHeader)
                    else
                        PAGE.Run(0, TransRcptHeader);
                DATABASE::"Posted Whse. Shipment Line":
                    PAGE.Run(0, PostedWhseShptLine);
                DATABASE::"Posted Whse. Receipt Line":
                    PAGE.Run(0, PostedWhseRcptLine);
                DATABASE::"G/L Entry":
                    PAGE.Run(0, GLEntry);
                DATABASE::"VAT Entry":
                    PAGE.Run(0, VATEntry);
                DATABASE::"Detailed Cust. Ledg. Entry":
                    PAGE.Run(0, DtldCustLedgEntry);
                DATABASE::"Cust. Ledger Entry":
                    PAGE.Run(0, CustLedgEntry);
                DATABASE::"Reminder/Fin. Charge Entry":
                    PAGE.Run(0, ReminderEntry);
                DATABASE::"Vendor Ledger Entry":
                    PAGE.Run(0, VendLedgEntry);
                DATABASE::"Detailed Vendor Ledg. Entry":
                    PAGE.Run(0, DtldVendLedgEntry);
                DATABASE::"Item Ledger Entry":
                    PAGE.Run(0, ItemLedgEntry);
                DATABASE::"Value Entry":
                    PAGE.Run(0, ValueEntry);
                DATABASE::"Phys. Inventory Ledger Entry":
                    PAGE.Run(0, PhysInvtLedgEntry);
                DATABASE::"Res. Ledger Entry":
                    PAGE.Run(0, ResLedgEntry);
                DATABASE::"Job Ledger Entry":
                    PAGE.Run(0, JobLedgEntry);
                DATABASE::"Job WIP Entry":
                    PAGE.Run(0, JobWIPEntry);
                DATABASE::"Job WIP G/L Entry":
                    PAGE.Run(0, JobWIPGLEntry);
                DATABASE::"Bank Account Ledger Entry":
                    PAGE.Run(0, BankAccLedgEntry);
                DATABASE::"Check Ledger Entry":
                    PAGE.Run(0, CheckLedgEntry);
                DATABASE::"FA Ledger Entry":
                    PAGE.Run(0, FALedgEntry);
                DATABASE::"Maintenance Ledger Entry":
                    PAGE.Run(0, MaintenanceLedgEntry);
                DATABASE::"Ins. Coverage Ledger Entry":
                    PAGE.Run(0, InsuranceCovLedgEntry);
                DATABASE::"Capacity Ledger Entry":
                    PAGE.Run(0, CapacityLedgEntry);
                DATABASE::"Warehouse Entry":
                    PAGE.Run(0, WhseEntry);
                DATABASE::"Service Header":
                    ShowServiceHeaderRecords;
                DATABASE::"Service Invoice Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Service Invoice", ServInvHeader)
                    else
                        PAGE.Run(0, ServInvHeader);
                DATABASE::"Service Cr.Memo Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Service Credit Memo", ServCrMemoHeader)
                    else
                        PAGE.Run(0, ServCrMemoHeader);
                DATABASE::"Service Shipment Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Service Shipment", ServShptHeader)
                    else
                        PAGE.Run(0, ServShptHeader);
                DATABASE::"Service Ledger Entry":
                    PAGE.Run(0, ServLedgerEntry);
                DATABASE::"Warranty Ledger Entry":
                    PAGE.Run(0, WarrantyLedgerEntry);
                DATABASE::"Cost Entry":
                    PAGE.Run(0, CostEntry);
                DATABASE::"Pstd. Phys. Invt. Order Hdr":
                    PAGE.Run(0, PstdPhysInvtOrderHdr);
                DATABASE::"G/L Correspondence Entry":
                    PAGE.Run(0, GLCorrEntry);
                DATABASE::"Gen. Journal Line Archive":
                    PAGE.Run(0, GenJnlPostedLine);
                DATABASE::"Item Receipt Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Item Receipt", PostedItemRcptHeader)
                    else
                        PAGE.Run(0, PostedItemRcptHeader);
                DATABASE::"Item Shipment Header":
                    if "No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Item Shipment", PostedItemShptHeader)
                    else
                        PAGE.Run(0, PostedItemShptHeader);
                DATABASE::"Posted FA Doc. Header":
                    PAGE.Run(0, PostedFADocHeader);
                DATABASE::"VAT Ledger Line":
                    begin
                        if VATLedgLinePurch.FindFirst then
                            PAGE.Run(PAGE::"VAT Purchase Ledger Subform", VATLedgLinePurch);
                        if VATLedgLineSales.FindFirst then
                            PAGE.Run(PAGE::"VAT Sales Ledger Subform", VATLedgLineSales);
                    end;
                DATABASE::"Tax Diff. Ledger Entry":
                    PAGE.Run(0, TaxDiffLedgerEntry);
                DATABASE::"Posted Absence Header":
                    PAGE.Run(0, PostedAbsenceHeader);
                DATABASE::"Employee Ledger Entry":
                    PAGE.Run(0, EmplLedgEntry);
                DATABASE::"Employee Absence Entry":
                    PAGE.Run(0, EmplAbsenceEntry);
                DATABASE::"Timesheet Detail":
                    PAGE.Run(0, TimesheetDetail);
                DATABASE::"Payroll Ledger Entry":
                    PAGE.Run(0, PayrollLedgEntry);
                DATABASE::"Detailed Payroll Ledger Entry":
                    PAGE.Run(0, DtldPayrollLedgEntry);
            end;

        OnAfterNavigateShowRecords(
          "Table ID", DocNoFilter, PostingDateFilter, ItemTrackingSearch, Rec,
          SalesInvHeader, SalesCrMemoHeader, PurchInvHeader, PurchCrMemoHeader, ServInvHeader, ServCrMemoHeader);
    end;

    local procedure ShowSalesHeaderRecords()
    begin
        TestField("Table ID", DATABASE::"Sales Header");

        case "Document Type" of
            "Document Type"::Order:
                if "No. of Records" = 1 then
                    PAGE.Run(PAGE::"Sales Order", SOSalesHeader)
                else
                    PAGE.Run(0, SOSalesHeader);
            "Document Type"::Invoice:
                if "No. of Records" = 1 then
                    PAGE.Run(PAGE::"Sales Invoice", SISalesHeader)
                else
                    PAGE.Run(0, SISalesHeader);
            "Document Type"::"Return Order":
                if "No. of Records" = 1 then
                    PAGE.Run(PAGE::"Sales Return Order", SROSalesHeader)
                else
                    PAGE.Run(0, SROSalesHeader);
            "Document Type"::"Credit Memo":
                if "No. of Records" = 1 then
                    PAGE.Run(PAGE::"Sales Credit Memo", SCMSalesHeader)
                else
                    PAGE.Run(0, SCMSalesHeader);
        end;
    end;

    local procedure ShowServiceHeaderRecords()
    begin
        TestField("Table ID", DATABASE::"Service Header");

        case "Document Type" of
            "Document Type"::Order:
                if "No. of Records" = 1 then
                    PAGE.Run(PAGE::"Service Order", SOServHeader)
                else
                    PAGE.Run(0, SOServHeader);
            "Document Type"::Invoice:
                if "No. of Records" = 1 then
                    PAGE.Run(PAGE::"Service Invoice", SIServHeader)
                else
                    PAGE.Run(0, SIServHeader);
            "Document Type"::"Credit Memo":
                if "No. of Records" = 1 then
                    PAGE.Run(PAGE::"Service Credit Memo", SCMServHeader)
                else
                    PAGE.Run(0, SCMServHeader);
        end;
    end;

    local procedure SetPostingDate(PostingDate: Text)
    begin
        FilterTokens.MakeDateFilter(PostingDate);
        SetFilter("Posting Date", PostingDate);
        PostingDateFilter := GetFilter("Posting Date");
    end;

    local procedure SetDocNo(DocNo: Text)
    begin
        SetFilter("Document No.", DocNo);
        DocNoFilter := GetFilter("Document No.");
        PostingDateFilter := GetFilter("Posting Date");
    end;

    local procedure ClearSourceInfo()
    begin
        if DocExists then begin
            DocExists := false;
            DeleteAll;
            ShowEnable := false;
            SetSource(0D, '', '', 0, '');
            CurrPage.Update(false);
        end;
    end;

    local procedure MakeExtFilter(var DateFilter: Text; AddDate: Date; var DocNoFilter: Text; AddDocNo: Code[20])
    begin
        if DateFilter = '' then
            DateFilter := Format(AddDate)
        else
            if StrPos(DateFilter, Format(AddDate)) = 0 then
                if MaxStrLen(DateFilter) >= StrLen(DateFilter + '|' + Format(AddDate)) then
                    DateFilter := DateFilter + '|' + Format(AddDate)
                else
                    TooLongFilter;

        if DocNoFilter = '' then
            DocNoFilter := AddDocNo
        else
            if StrPos(DocNoFilter, AddDocNo) = 0 then
                if MaxStrLen(DocNoFilter) >= StrLen(DocNoFilter + '|' + AddDocNo) then
                    DocNoFilter := DocNoFilter + '|' + AddDocNo
                else
                    TooLongFilter;
    end;

    local procedure FindPush()
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') and
           (not ItemTrackingSearch) and
           ((ContactType <> 0) or (ContactNo <> '') or (ExtDocNo <> ''))
        then
            FindExtRecords
        else
            if ItemTrackingSearch and
               (DocNoFilter = '') and (PostingDateFilter = '') and
               (ContactType = 0) and (ContactNo = '') and (ExtDocNo = '')
            then
                FindTrackingRecords
            else
                FindRecords;
    end;

    local procedure TooLongFilter()
    begin
        if ContactNo = '' then
            Error(Text015);

        Error(Text016);
    end;

    local procedure FindUnpostedSalesDocs(DocType: Option; DocTableName: Text[100]; var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."SecurityFiltering"(SECURITYFILTER::Filtered);
        if SalesHeader.ReadPermission then begin
            SalesHeader.Reset;
            SalesHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
            SalesHeader.SetFilter("Sell-to Customer No.", ContactNo);
            SalesHeader.SetFilter("External Document No.", ExtDocNo);
            SalesHeader.SetRange("Document Type", DocType);
            InsertIntoDocEntry(Rec, DATABASE::"Sales Header", DocType, DocTableName, SalesHeader.Count);
        end;
    end;

    local procedure FindUnpostedServDocs(DocType: Option; DocTableName: Text[100]; var ServHeader: Record "Service Header")
    begin
        ServHeader."SecurityFiltering"(SECURITYFILTER::Filtered);
        if ServHeader.ReadPermission then
            if ExtDocNo = '' then begin
                ServHeader.Reset;
                ServHeader.SetCurrentKey("Customer No.");
                ServHeader.SetFilter("Customer No.", ContactNo);
                ServHeader.SetRange("Document Type", DocType);
                InsertIntoDocEntry(Rec, DATABASE::"Service Header", DocType, DocTableName, ServHeader.Count);
            end;
    end;

    local procedure FindTrackingRecords()
    var
        DocNoOfRecords: Integer;
    begin
        Window.Open(Text002);
        DeleteAll;
        "Entry No." := 0;

        Clear(ItemTrackingNavigateMgt);
        ItemTrackingNavigateMgt.FindTrackingRecords(SerialNoFilter, LotNoFilter, CDNoFilter, '', '');

        ItemTrackingNavigateMgt.Collect(TempRecordBuffer);
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
                    until TempRecordBuffer.Next = 0;

                InsertIntoDocEntry(Rec, TempRecordBuffer."Table No.", 0, TempRecordBuffer."Table Name", DocNoOfRecords);

                TempRecordBuffer.SetRange("Table No.");
            until TempRecordBuffer.Next = 0;

        OnAfterNavigateFindTrackingRecords(Rec, SerialNoFilter, LotNoFilter);

        DocExists := Find('-');

        UpdateFormAfterFindRecords;
        Window.Close;
    end;

    local procedure GetDocumentCount() DocCount: Integer
    begin
        DocCount :=
          NoOfRecords(DATABASE::"Sales Invoice Header") + NoOfRecords(DATABASE::"Sales Cr.Memo Header") +
          NoOfRecords(DATABASE::"Sales Shipment Header") + NoOfRecords(DATABASE::"Issued Reminder Header") +
          NoOfRecords(DATABASE::"Issued Fin. Charge Memo Header") + NoOfRecords(DATABASE::"Purch. Inv. Header") +
          NoOfRecords(DATABASE::"Return Shipment Header") + NoOfRecords(DATABASE::"Return Receipt Header") +
          NoOfRecords(DATABASE::"Purch. Cr. Memo Hdr.") + NoOfRecords(DATABASE::"Purch. Rcpt. Header") +
          NoOfRecords(DATABASE::"Service Invoice Header") + NoOfRecords(DATABASE::"Service Cr.Memo Header") +
          NoOfRecords(DATABASE::"Service Shipment Header") +
          NoOfRecords(DATABASE::"Transfer Shipment Header") + NoOfRecords(DATABASE::"Transfer Receipt Header");

        OnAfterGetDocumentCount(DocCount);
    end;

    procedure SetTracking(SerialNo: Code[50]; LotNo: Code[50]; CDNo: Code[30])
    begin
        NewSerialNo := SerialNo;
        NewLotNo := LotNo;
        NewCDNo := CDNo;
    end;

    local procedure ItemTrackingSearch(): Boolean
    begin
        exit((SerialNoFilter <> '') or (LotNoFilter <> '') or (CDNoFilter <> ''));
    end;

    local procedure ClearTrackingInfo()
    begin
        SerialNoFilter := '';
        LotNoFilter := '';
        CDNoFilter := '';
    end;

    local procedure ClearInfo()
    begin
        SetDocNo('');
        SetPostingDate('');
        ContactType := ContactType::" ";
        ContactNo := '';
        ExtDocNo := '';
    end;

    [Scope('OnPrem')]
    procedure SetHROrder(HROrderNo: Code[20]; HROrderDate: Date)
    begin
        NewHROrderNo := HROrderNo;
        NewHROrderDate := HROrderDate;
    end;

    local procedure DocNoFilterOnAfterValidate()
    begin
        ClearSourceInfo;
    end;

    local procedure PostingDateFilterOnAfterValida()
    begin
        ClearSourceInfo;
    end;

    local procedure ExtDocNoOnAfterValidate()
    begin
        ClearSourceInfo;
    end;

    local procedure ContactTypeOnAfterValidate()
    begin
        ClearSourceInfo;
    end;

    local procedure ContactNoOnAfterValidate()
    begin
        ClearSourceInfo;
    end;

    local procedure SerialNoFilterOnAfterValidate()
    begin
        ClearSourceInfo;
    end;

    local procedure LotNoFilterOnAfterValidate()
    begin
        ClearSourceInfo;
    end;

    local procedure CDNoFilterOnAfterValidate()
    begin
        ClearSourceInfo;
    end;

    procedure FindRecordsOnOpen()
    begin
        if (NewDocNo = '') and (NewPostingDate = 0D) and (NewSerialNo = '') and (NewLotNo = '') and (NewCDNo = '') then begin
            DeleteAll;
            ShowEnable := false;
            PrintEnable := false;
            SetSource(0D, '', '', 0, '');
        end else
            if (NewSerialNo <> '') or (NewLotNo <> '') or (NewCDNo <> '') then begin
                SetSource(0D, '', '', 0, '');
                if NewSerialNo <> '' then begin
                    SetRange("Serial No. Filter", NewSerialNo);
                    SerialNoFilter := GetFilter("Serial No. Filter");
                end;
                if NewLotNo <> '' then begin
                    SetRange("Lot No. Filter", NewLotNo);
                    LotNoFilter := GetFilter("Lot No. Filter");
                end;
                if NewCDNo <> '' then begin
                    SetRange("CD No. Filter", NewCDNo);
                    CDNoFilter := GetFilter("CD No. Filter");
                end;
                ClearInfo;
                FindTrackingRecords;
            end else begin
                SetRange("Document No.", NewDocNo);
                SetRange("Posting Date", NewPostingDate);
                DocNoFilter := GetFilter("Document No.");
                PostingDateFilter := GetFilter("Posting Date");
                ContactType := ContactType::" ";
                ContactNo := '';
                ExtDocNo := '';
                ClearTrackingInfo;
                FindRecords;
            end;
    end;

    procedure UpdateNavigateForm(UpdateFormFrom: Boolean)
    begin
        UpdateForm := UpdateFormFrom;
    end;

    procedure ReturnDocumentEntry(var TempDocumentEntry: Record "Document Entry" temporary)
    begin
        SetRange("Table ID");  // Clear filter.
        FindSet;
        repeat
            TempDocumentEntry.Init;
            TempDocumentEntry := Rec;
            TempDocumentEntry.Insert;
        until Next = 0;
    end;

    local procedure UpdateFindByGroupsVisibility()
    begin
        DocumentVisible := false;
        BusinessContactVisible := false;
        ItemReferenceVisible := false;

        case FindBasedOn of
            FindBasedOn::Document:
                DocumentVisible := true;
            FindBasedOn::"Business Contact":
                BusinessContactVisible := true;
            FindBasedOn::"Item Reference":
                ItemReferenceVisible := true;
        end;

        CurrPage.Update;
    end;

    local procedure FilterSelectionChanged()
    begin
        FilterSelectionChangedTxtVisible := true;
    end;

    local procedure GetCaptionText(): Text
    begin
        if "Table Name" <> '' then
            exit(StrSubstNo(PageCaptionTxt, "Table Name"));

        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocumentCount(var DocCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNavigateFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNavigateFindTrackingRecords(var DocumentEntry: Record "Document Entry"; SerialNoFilter: Text; LotNoFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNavigateShowRecords(TableID: Integer; DocNoFilter: Text; PostingDateFilter: Text; ItemTrackingSearch: Boolean; var TempDocumentEntry: Record "Document Entry" temporary; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecords(var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNavigateShowRecords(TableID: Integer; DocNoFilter: Text; PostingDateFilter: Text; ItemTrackingSearch: Boolean; var TempDocumentEntry: Record "Document Entry" temporary; var IsHandled: Boolean; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeUpdateFormAfterFindRecords()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordsOnAfterSetSource(var DocumentEntry: Record "Document Entry"; var PostingDate: Date; var DocType2: Text[100]; var DocNo: Code[20]; var SourceType2: Integer; var SourceNo: Code[20]; var DocNoFilter: Text; var PostingDateFilter: Text; var IsHandled: Boolean)
    begin
    end;
}

