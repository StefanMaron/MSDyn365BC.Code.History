table 10752 "SII Doc. Upload State"
{
    Caption = 'SII Doc. Upload States';

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            Caption = 'Id';
            NotBlank = true;
        }
        field(2; "Entry No"; Integer)
        {
            Caption = 'Entry No';
        }
        field(3; "Document Source"; Enum "SII Doc. Upload State Document Source")
        {
            Caption = 'Document Source';
            NotBlank = true;
        }
        field(4; "Document Type"; Enum "SII Doc. Upload State Document Type")
        {
            Caption = 'Document Type';
        }
        field(5; "Document No."; Code[35])
        {
            Caption = 'Document No.';
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(7; "Transaction Type"; Option)
        {
            Caption = 'Transaction Type';
            OptionCaption = 'Regular,Intracommunity,RetryAccepted,Collection In Cash';
            OptionMembers = Regular,Intracommunity,RetryAccepted,"Collection In Cash";
        }
        field(8; Status; Option)
        {
            Caption = 'Status';
            NotBlank = true;
            OptionCaption = 'Pending,Incorrect,Accepted,Accepted With Errors,Communication Error,Failed,Not Supported';
            OptionMembers = Pending,Incorrect,Accepted,"Accepted With Errors","Communication Error",Failed,"Not Supported";
        }
        field(9; "Is Credit Memo Removal"; Boolean)
        {
            Caption = 'Is Credit Memo Removal';
        }
        field(10; "Is Manual"; Boolean)
        {
            Caption = 'Is Manual';
        }
        field(11; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(12; "Corrected Doc. No."; Code[35])
        {
            Caption = 'Corrected Doc. No.';
            DataClassification = CustomerContent;
        }
        field(13; "Corr. Posting Date"; Date)
        {
            Caption = 'Corr. Posting Date';
            DataClassification = CustomerContent;
        }
        field(20; "Sales Invoice Type"; Option)
        {
            Caption = 'Sales Invoice Type';
            OptionCaption = ' ,F1 Invoice,F2 Simplified Invoice,F3 Invoice issued to replace simplified invoices,F4 Invoice summary entry,R1 Corrected Invoice,R2 Corrected Invoice (Art. 80.3),R3 Corrected Invoice (Art. 80.4),R4 Corrected Invoice (Other),R5 Corrected Invoice in Simplified Invoices';
            OptionMembers = " ","F1 Invoice","F2 Simplified Invoice","F3 Invoice issued to replace simplified invoices","F4 Invoice summary entry","R1 Corrected Invoice","R2 Corrected Invoice (Art. 80.3)","R3 Corrected Invoice (Art. 80.4)","R4 Corrected Invoice (Other)","R5 Corrected Invoice in Simplified Invoices";

            trigger OnValidate()
            begin
                if "Sales Invoice Type" <> 0 then begin
                    TestField("Document Source", "Document Source"::"Customer Ledger");
                    TestField("Document Type", "Document Type"::Invoice);
                end;
            end;
        }
        field(21; "Sales Cr. Memo Type"; Option)
        {
            Caption = 'Sales Cr. Memo Type';
            OptionCaption = ' ,R1 Corrected Invoice,R2 Corrected Invoice (Art. 80.3),R3 Corrected Invoice (Art. 80.4),R4 Corrected Invoice (Other),R5 Corrected Invoice in Simplified Invoices,F1 Invoice,F2 Simplified Invoice';
            OptionMembers = " ","R1 Corrected Invoice","R2 Corrected Invoice (Art. 80.3)","R3 Corrected Invoice (Art. 80.4)","R4 Corrected Invoice (Other)","R5 Corrected Invoice in Simplified Invoices","F1 Invoice","F2 Simplified Invoice";

            trigger OnValidate()
            begin
                if "Sales Cr. Memo Type" <> 0 then begin
                    TestField("Document Source", "Document Source"::"Customer Ledger");
                    TestField("Document Type", "Document Type"::"Credit Memo");
                end;
            end;
        }
        field(22; "Sales Special Scheme Code"; Option)
        {
            Caption = 'Sales Special Scheme Code';
            OptionCaption = ' ,01 General,02 Export,03 Special System,04 Gold,05 Travel Agencies,06 Groups of Entities,07 Special Cash,08  IPSI / IGIC,09 Travel Agency Services,10 Third Party,11 Business Withholding,12 Business not Withholding,13 Business Withholding and not Withholding,14 Invoice Work Certification,15 Invoice of Consecutive Nature,16 First Half 2017';
            OptionMembers = " ","01 General","02 Export","03 Special System","04 Gold","05 Travel Agencies","06 Groups of Entities","07 Special Cash","08  IPSI / IGIC","09 Travel Agency Services","10 Third Party","11 Business Withholding","12 Business not Withholding","13 Business Withholding and not Withholding","14 Invoice Work Certification","15 Invoice of Consecutive Nature","16 First Half 2017";

            trigger OnValidate()
            begin
                if "Sales Special Scheme Code" <> 0 then
                    TestField("Document Source", "Document Source"::"Customer Ledger");
            end;
        }
        field(23; "Purch. Invoice Type"; Option)
        {
            Caption = 'Purch. Invoice Type';
            OptionCaption = ' ,F1 Invoice,F2 Simplified Invoice,F3 Invoice issued to replace simplified invoices,F4 Invoice summary entry,F5 Imports (DUA),F6 Accounting support material,Customs - Complementary Liquidation,R1 Corrected Invoice,R2 Corrected Invoice (Art. 80.3),R3 Corrected Invoice (Art. 80.4),R4 Corrected Invoice (Other),R5 Corrected Invoice in Simplified Invoices';
            OptionMembers = " ","F1 Invoice","F2 Simplified Invoice","F3 Invoice issued to replace simplified invoices","F4 Invoice summary entry","F5 Imports (DUA)","F6 Accounting support material","Customs - Complementary Liquidation","R1 Corrected Invoice","R2 Corrected Invoice (Art. 80.3)","R3 Corrected Invoice (Art. 80.4)","R4 Corrected Invoice (Other)","R5 Corrected Invoice in Simplified Invoices";

            trigger OnValidate()
            begin
                if "Purch. Invoice Type" <> 0 then begin
                    TestField("Document Source", "Document Source"::"Vendor Ledger");
                    TestField("Document Type", "Document Type"::Invoice);
                end;
            end;
        }
        field(24; "Purch. Cr. Memo Type"; Option)
        {
            Caption = 'Purch. Cr. Memo Type';
            OptionCaption = ' ,R1 Corrected Invoice,R2 Corrected Invoice (Art. 80.3),R3 Corrected Invoice (Art. 80.4),R4 Corrected Invoice (Other),R5 Corrected Invoice in Simplified Invoices,F1 Invoice,F2 Simplified Invoice';
            OptionMembers = " ","R1 Corrected Invoice","R2 Corrected Invoice (Art. 80.3)","R3 Corrected Invoice (Art. 80.4)","R4 Corrected Invoice (Other)","R5 Corrected Invoice in Simplified Invoices","F1 Invoice","F2 Simplified Invoice";

            trigger OnValidate()
            begin
                if "Purch. Cr. Memo Type" <> 0 then begin
                    TestField("Document Source", "Document Source"::"Vendor Ledger");
                    TestField("Document Type", "Document Type"::"Credit Memo");
                end;
            end;
        }
        field(25; "Purch. Special Scheme Code"; Option)
        {
            Caption = 'Purch. Special Scheme Code';
            OptionCaption = ' ,01 General,02 Special System Activities,03 Special System,04 Gold,05 Travel Agencies,06 Groups of Entities,07 Special Cash,08  IPSI / IGIC,09 Intra-Community Acquisition,12 Business Premises Leasing Operations,13 Import (Without DUA),14 First Half 2017';
            OptionMembers = " ","01 General","02 Special System Activities","03 Special System","04 Gold","05 Travel Agencies","06 Groups of Entities","07 Special Cash","08  IPSI / IGIC","09 Intra-Community Acquisition","12 Business Premises Leasing Operations","13 Import (Without DUA)","14 First Half 2017";

            trigger OnValidate()
            begin
                if "Purch. Special Scheme Code" <> 0 then
                    TestField("Document Source", "Document Source"::"Vendor Ledger");
            end;
        }
        field(30; "CV No."; Code[20])
        {
            Caption = 'CV No.';
            TableRelation = IF ("Document Source" = CONST("Customer Ledger")) Customer
            ELSE
            IF ("Document Source" = CONST("Vendor Ledger")) Vendor;
        }
        field(31; "Total Amount In Cash"; Decimal)
        {
            Caption = 'Total Amount In Cash';

            trigger OnValidate()
            begin
                if "Total Amount In Cash" <> 0 then
                    TestField("Transaction Type", "Transaction Type"::"Collection In Cash");
            end;
        }
        field(40; "Retry Accepted"; Boolean)
        {
            Caption = 'Retry Accepted';
        }
        field(41; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(42; "CV Name"; Text[100])
        {
            Caption = 'CV Name';
        }
        field(43; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
        }
        field(44; IDType; Option)
        {
            Caption = 'IDType';
            OptionCaption = ' ,02-VAT Registration No.,03-Passport,04-ID Document,05-Certificate Of Residence,06-Other Probative Document,07-Not On The Census';
            OptionMembers = " ","02-VAT Registration No.","03-Passport","04-ID Document","05-Certificate Of Residence","06-Other Probative Document","07-Not On The Census";
        }
        field(50; "Inv. Entry No"; Integer)
        {
            Caption = 'Inv. Entry No';
            DataClassification = SystemMetadata;
        }
        field(60; "Succeeded Company Name"; Text[250])
        {
            Caption = 'Succeeded Company Name';
        }
        field(61; "Succeeded VAT Registration No."; Text[20])
        {
            Caption = 'Succeeded VAT Registration No.';
        }
        field(70; "Version No."; Option)
        {
            Caption = 'Version No.';
            OptionCaption = '1.1,1.0,1.1bis';
            OptionMembers = "1.1","1.0","2.1";
        }
        field(80; "Accepted By User ID"; Code[50])
        {
            Caption = 'Accepted By User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(81; "Accepted Date Time"; DateTime)
        {
            Caption = 'Accepted Date Time';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; "Entry No")
        {
        }
        key(Key3; Status, "Is Manual")
        {
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure CreateNewRequest(EntryNo: Integer; DocumentSource: Option "Customer Ledger","Vendor Ledger","Detailed Customer Ledger","Detailed Vendor Ledger"; DocumentType: Option ,Payment,Invoice,"Credit Memo"; DocumentNo: Code[35]; ExternalDocumentNo: Code[35]; PostingDate: Date)
    begin
        CreateNewRequestInternal(EntryNo, 0, DocumentSource, DocumentType, DocumentNo, ExternalDocumentNo, PostingDate);
    end;

    [Scope('OnPrem')]
    procedure CreateNewCollectionsInCashRequest(CustomerNo: Code[20]; PostingDate: Date; TotalAmount: Decimal): Boolean
    var
        Customer: Record Customer;
        SIIHistory: Record "SII History";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
    begin
        if not SIIManagement.IsSIISetupEnabled then
            exit;

        SIIDocUploadState.SetRange("Posting Date", PostingDate);
        SIIDocUploadState.SetRange("CV No.", CustomerNo);
        SIIDocUploadState.SetRange("Transaction Type", SIIDocUploadState."Transaction Type"::"Collection In Cash");
        if SIIDocUploadState.FindFirst then begin
            if SIIDocUploadState."Total Amount In Cash" = TotalAmount then
                exit(false);
            SIIDocUploadState.Validate("Total Amount In Cash", TotalAmount);
            SIIDocUploadState.Validate("Retry Accepted",
              SIIDocUploadState.Status in [SIIDocUploadState.Status::Accepted, SIIDocUploadState.Status::"Accepted With Errors"]);
            SIIDocUploadState.Modify(true);
            SIIHistory.CreateNewRequest(
              SIIDocUploadState.Id, SIIHistory."Upload Type"::"Collection In Cash", 4, false, SIIDocUploadState."Retry Accepted");
            exit(true);
        end;
        SIIDocUploadState.Init();
        SIIDocUploadState."Document Source" := SIIDocUploadState."Document Source"::"Customer Ledger";
        SIIDocUploadState."Posting Date" := PostingDate;
        SetStatus(SIIDocUploadState);
        SIIDocUploadState."Transaction Type" := SIIDocUploadState."Transaction Type"::"Collection In Cash";
        SIIDocUploadState.Validate("CV No.", CustomerNo);
        Customer.Get(SIIDocUploadState."CV No.");
        SIIDocUploadState.Validate("VAT Registration No.", Customer."VAT Registration No.");
        SIIDocUploadState.Validate("CV Name", Customer.Name);
        SIIDocUploadState.Validate("Country/Region Code", Customer."Country/Region Code");
        SIIDocUploadState.Validate("Total Amount In Cash", TotalAmount);
        SIIDocUploadState.Insert();
        SIIHistory.CreateNewRequest(SIIDocUploadState.Id, SIIHistory."Upload Type"::"Collection In Cash", 4, false, false);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CreateNewVendPmtRequest(PmtEntryNo: Integer; InvEntryNo: Integer; DocumentNo: Code[35]; PostingDate: Date)
    begin
        CreateNewRequestInternal(
          PmtEntryNo, InvEntryNo, "Document Source"::"Detailed Vendor Ledger", "Document Type"::Payment, DocumentNo, '', PostingDate);
    end;

    [Scope('OnPrem')]
    procedure CreateNewCustPmtRequest(PmtEntryNo: Integer; InvEntryNo: Integer; DocumentNo: Code[30]; PostingDate: Date)
    begin
        CreateNewRequestInternal(
          PmtEntryNo, InvEntryNo, "Document Source"::"Detailed Customer Ledger", "Document Type"::Payment, DocumentNo, '', PostingDate);
    end;

    local procedure CreateNewRequestInternal(EntryNo: Integer; InvEntryNo: Integer; DocumentSource: Enum "SII Doc. Upload State Document Source"; DocumentType: Enum "SII Doc. Upload State Document Type"; DocumentNo: Code[35]; ExternalDocumentNo: Code[35]; PostingDate: Date)
    var
        SIIHistory: Record "SII History";
        SIIDocUploadState: Record "SII Doc. Upload State";
        TempSIIDocUploadState: Record "SII Doc. Upload State" temporary;
        SIIManagement: Codeunit "SII Management";
        IsCVPayment: Boolean;
    begin
        if not SIIManagement.IsSIISetupEnabled then
            exit;

        IsCVPayment := DocumentSource in [SIIDocUploadState."Document Source"::"Detailed Customer Ledger",
                                          SIIDocUploadState."Document Source"::"Detailed Vendor Ledger"];
        if IsCVPayment then
            SIIDocUploadState.SetRange("Inv. Entry No", InvEntryNo)
        else
            SIIDocUploadState.SetRange("Entry No", EntryNo);
        SIIDocUploadState.SetRange("Document Source", DocumentSource);
        if SIIDocUploadState.FindFirst then begin
            if IsCVPayment then begin
                // Create additional request to handle one more partial payment if no such request in state Pending
                SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
                SIIHistory.SetRange(Status, SIIHistory.Status::Pending);
                if SIIHistory.IsEmpty then
                    SIIHistory.CreateNewRequest(SIIDocUploadState.Id, SIIHistory."Upload Type"::Regular, 4, false, true);
            end;
            exit;
        end;

        TempSIIDocUploadState.Init();
        ValidateDocInfo(TempSIIDocUploadState, EntryNo, DocumentSource, DocumentType, DocumentNo);
        SIIDocUploadState.Init();
        SIIDocUploadState := TempSIIDocUploadState;
        SIIDocUploadState."Document No." := DocumentNo;
        SIIDocUploadState."External Document No." := ExternalDocumentNo;
        SIIDocUploadState."Posting Date" := PostingDate;
        SIIDocUploadState."Transaction Type" := SIIDocUploadState."Transaction Type"::Regular;
        SIIDocUploadState."Inv. Entry No" := InvEntryNo;
        SIIDocUploadState.GetCorrectionInfo(
          SIIDocUploadState."Corrected Doc. No.", SIIDocUploadState."Corr. Posting Date", SIIDocUploadState."Posting Date");
        SIIDocUploadState."Version No." := GetSIIVersionNo();
        SetStatus(SIIDocUploadState);
        SIIDocUploadState.Insert();

        SIIHistory.CreateNewRequest(SIIDocUploadState.Id, SIIHistory."Upload Type"::Regular, 4, false, false);
    end;

    [Scope('OnPrem')]
    procedure CreateCommunicationErrorRetries()
    var
        SIIHistory: Record "SII History";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        SIIDocUploadState.SetRange(Status, SIIDocUploadState.Status::"Communication Error");

        if SIIDocUploadState.FindSet then begin
            repeat
                // We want latest first. Ideally we'd use something like 'by date desc', but since NAV does not allow us to do that,
                // we rely on PK and that the date does not change in a weird way.
                SIIHistory.Reset();
                SIIHistory.Ascending(false);
                SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
                SIIHistory.SetRange("Is Manual", false);

                SIIHistory.SetRange("Upload Type", SIIHistory."Upload Type"::Regular);
                // If the latest doc is in "CommunicationError" state, we issue a retry.
                CreateCommunicationErrorRetryRequest(SIIHistory);
            until SIIDocUploadState.Next = 0;
        end;
    end;

    local procedure CreateCommunicationErrorRetryRequest(var SIIHistory: Record "SII History")
    begin
        if SIIHistory.FindFirst then
            if SIIHistory.Status = SIIHistory.Status::"Communication Error" then
                SIIHistory.CreateNewRequest(
                  SIIHistory."Document State Id", SIIHistory."Upload Type",
                  SIIHistory."Retries Left", false, false);
    end;

    local procedure SetStatus(var SIIDocUploadState: Record "SII Doc. Upload State")
    begin
        SIIDocUploadState.Status := Status::Pending;
    end;

    [Scope('OnPrem')]
    procedure UpdateDocInfoOnSIIDocUploadState(DocFieldNo: Integer)
    begin
        if not (Status in [Status::Pending, Status::Incorrect, Status::"Accepted With Errors"]) then
            FieldError(Status);
        UpdateFieldOnSIIDOcUploadState(DocFieldNo);
    end;

    [Scope('OnPrem')]
    procedure UpdateFieldOnSIIDOcUploadState(FieldNo: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(Rec);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(FieldRef.Value);
        RecRef.Modify(true);
        RecRef.SetTable(Rec);
    end;

    [Scope('OnPrem')]
    procedure GetSIIDocUploadStateByCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        Reset;
        SetRange("Document Source", "Document Source"::"Customer Ledger");
        case CustLedgEntry."Document Type" of
            CustLedgEntry."Document Type"::Invoice:
                SetRange("Document Type", "Document Type"::Invoice);
            CustLedgEntry."Document Type"::"Credit Memo":
                SetRange("Document Type", "Document Type"::"Credit Memo");
            else
                exit;
        end;
        SetRange("Entry No", CustLedgEntry."Entry No.");
        FindFirst;
    end;

    [Scope('OnPrem')]
    procedure GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        Reset;
        SetRange("Document Source", "Document Source"::"Vendor Ledger");
        case VendorLedgerEntry."Document Type" of
            VendorLedgerEntry."Document Type"::Invoice:
                SetRange("Document Type", "Document Type"::Invoice);
            VendorLedgerEntry."Document Type"::"Credit Memo":
                SetRange("Document Type", "Document Type"::"Credit Memo");
            else
                exit;
        end;
        SetRange("Entry No", VendorLedgerEntry."Entry No.");
        FindFirst;
    end;

    [Scope('OnPrem')]
    procedure GetSIIDocUploadStateByDocument(DocSource: Option; DocType: Option; PostingDate: Date; DocNo: Code[20]): Boolean
    begin
        SetRange("Document Source", DocSource);
        SetRange("Document Type", DocType);
        SetRange("Posting Date", PostingDate);
        SetRange("Document No.", DocNo);
        exit(FindLast);
    end;

    local procedure GetSIIVersionNo(): Integer
    begin
        if Date2DMY(WorkDate(), 3) >= 2021 then
            exit("Version No."::"2.1");
        exit("Version No."::"1.1");
    end;
    
    [Scope('OnPrem')]
    procedure ValidateDocInfo(var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary; EntryNo: Integer; DocumentSource: Enum "SII Doc. Upload State Document Source"; DocumentType: Enum "SII Doc. Upload State Document Type"; DocumentNo: Code[35])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServiceHeader: Record "Service Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SIIManagement: Codeunit "SII Management";
    begin
        TempSIIDocUploadState.Validate("Entry No", EntryNo);
        TempSIIDocUploadState.Validate("Document Source", DocumentSource);
        TempSIIDocUploadState.Validate("Document Type", DocumentType);
        TempSIIDocUploadState.Validate("Is Credit Memo Removal", TempSIIDocUploadState.IsCreditMemoRemoval);
        case DocumentSource of
            "Document Source"::"Customer Ledger":
                case DocumentType of
                    "Document Type"::Invoice:
                        begin
                            if SalesInvoiceHeader.Get(DocumentNo) then
                                if not SIIManagement.IsAllowedSalesInvType(SalesInvoiceHeader."Invoice Type") then
                                    SalesInvoiceHeader.FieldError("Invoice Type");
                            if SalesInvoiceHeader."No." = '' then begin
                                // Get Service Header instead of Service Invoice Header because it's not inserted yet
                                ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Invoice);
                                ServiceHeader.SetRange("Posting No.", DocumentNo);
                                if ServiceHeader.FindFirst then begin
                                    if not SIIManagement.IsAllowedServInvType(ServiceHeader."Invoice Type") then
                                        ServiceHeader.FieldError("Invoice Type");
                                    // Increase Invoice Type and Special Scheme Code because in SII Doc. Upload state there is blank option in the beginning
                                    TempSIIDocUploadState.UpdateSalesSIIDocUploadStateInfo(
                                      ServiceHeader."Bill-to Customer No.", ServiceHeader."Invoice Type" + 1, 0, ServiceHeader."Special Scheme Code" + 1,
                                      ServiceHeader."Succeeded Company Name", ServiceHeader."Succeeded VAT Registration No.", ServiceHeader."ID Type");
                                end else begin
                                    CustLedgerEntry.Get(EntryNo);
                                    TempSIIDocUploadState.UpdateSalesSIIDocUploadStateInfo(
                                      CustLedgerEntry."Customer No.", CustLedgerEntry."Invoice Type" + 1, 0, CustLedgerEntry."Special Scheme Code" + 1,
                                      CustLedgerEntry."Succeeded Company Name", CustLedgerEntry."Succeeded VAT Registration No.",
                                      CustLedgerEntry."ID Type");
                                end;
                            end else
                                TempSIIDocUploadState.UpdateSalesSIIDocUploadStateInfo(
                                  SalesInvoiceHeader."Bill-to Customer No.", SalesInvoiceHeader."Invoice Type" + 1, 0,
                                  SalesInvoiceHeader."Special Scheme Code" + 1, SalesInvoiceHeader."Succeeded Company Name",
                                  SalesInvoiceHeader."Succeeded VAT Registration No.", SalesInvoiceHeader."ID Type");
                        end;
                    "Document Type"::"Credit Memo":
                        if SalesCrMemoHeader.Get(DocumentNo) then
                            TempSIIDocUploadState.UpdateSalesSIIDocUploadStateInfo(
                              SalesCrMemoHeader."Bill-to Customer No.", 0, SalesCrMemoHeader."Cr. Memo Type" + 1,
                              SalesCrMemoHeader."Special Scheme Code" + 1, SalesCrMemoHeader."Succeeded Company Name",
                              SalesCrMemoHeader."Succeeded VAT Registration No.", SalesCrMemoHeader."ID Type")
                        else begin
                            ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::"Credit Memo");
                            ServiceHeader.SetRange("Posting No.", DocumentNo);
                            if ServiceHeader.FindFirst then
                                TempSIIDocUploadState.UpdateSalesSIIDocUploadStateInfo(
                                  ServiceHeader."Bill-to Customer No.", 0, ServiceHeader."Cr. Memo Type" + 1, ServiceHeader."Special Scheme Code" + 1,
                                  ServiceHeader."Succeeded Company Name", ServiceHeader."Succeeded VAT Registration No.", ServiceHeader."ID Type")
                            else begin
                                CustLedgerEntry.Get(EntryNo);
                                TempSIIDocUploadState.UpdateSalesSIIDocUploadStateInfo(
                                  CustLedgerEntry."Customer No.", 0, CustLedgerEntry."Cr. Memo Type" + 1, CustLedgerEntry."Special Scheme Code" + 1,
                                  CustLedgerEntry."Succeeded Company Name", CustLedgerEntry."Succeeded VAT Registration No.",
                                  CustLedgerEntry."ID Type");
                            end;
                        end;
                end;
            "Document Source"::"Vendor Ledger":
                case DocumentType of
                    "Document Type"::Invoice:
                        if PurchInvHeader.Get(DocumentNo) then
                            TempSIIDocUploadState.UpdatePurchSIIDocUploadState(
                              PurchInvHeader."Pay-to Vendor No.", PurchInvHeader."Invoice Type" + 1, 0, PurchInvHeader."Special Scheme Code" + 1,
                              PurchInvHeader."Succeeded Company Name", PurchInvHeader."Succeeded VAT Registration No.", PurchInvHeader."ID Type")
                        else begin
                            VendLedgEntry.Get(EntryNo);
                            TempSIIDocUploadState.UpdatePurchSIIDocUploadState(
                              VendLedgEntry."Vendor No.", VendLedgEntry."Invoice Type" + 1, 0, VendLedgEntry."Special Scheme Code" + 1,
                              VendLedgEntry."Succeeded Company Name", VendLedgEntry."Succeeded VAT Registration No.", VendLedgEntry."ID Type");
                        end;
                    "Document Type"::"Credit Memo":
                        if PurchCrMemoHdr.Get(DocumentNo) then
                            TempSIIDocUploadState.UpdatePurchSIIDocUploadState(
                              PurchCrMemoHdr."Pay-to Vendor No.", 0, PurchCrMemoHdr."Cr. Memo Type" + 1, PurchCrMemoHdr."Special Scheme Code" + 1,
                              PurchCrMemoHdr."Succeeded Company Name", PurchCrMemoHdr."Succeeded VAT Registration No.", PurchCrMemoHdr."ID Type")
                        else begin
                            VendLedgEntry.Get(EntryNo);
                            TempSIIDocUploadState.UpdatePurchSIIDocUploadState(
                              VendLedgEntry."Vendor No.", 0, VendLedgEntry."Cr. Memo Type" + 1, VendLedgEntry."Special Scheme Code" + 1,
                              VendLedgEntry."Succeeded Company Name", VendLedgEntry."Succeeded VAT Registration No.", VendLedgEntry."ID Type");
                        end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure IsCreditMemoRemoval(): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        if ("Document Source" = "Document Source"::"Customer Ledger") and ("Document Type" = "Document Type"::"Credit Memo") then
            if CustLedgerEntry.Get("Entry No") then begin
                if SalesCrMemoHeader.Get(CustLedgerEntry."Document No.") then
                    exit(SalesCrMemoHeader."Correction Type" = SalesCrMemoHeader."Correction Type"::Removal);
                if ServiceCrMemoHeader.Get(CustLedgerEntry."Document No.") then
                    exit(ServiceCrMemoHeader."Correction Type" = ServiceCrMemoHeader."Correction Type"::Removal);
            end;

        if ("Document Source" = "Document Source"::"Vendor Ledger") and ("Document Type" = "Document Type"::"Credit Memo") then
            if VendorLedgerEntry.Get("Entry No") then
                if PurchCrMemoHdr.Get(VendorLedgerEntry."Document No.") then
                    exit(PurchCrMemoHdr."Correction Type" = PurchCrMemoHdr."Correction Type"::Removal);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetCorrectionInfo(var CorrectedDocNo: Code[35]; var CorrectionDate: Date; PostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        CorrectedDocNo := '';
        CorrectionDate := 0D;
        if ("Document Source" in ["Document Source"::"Detailed Customer Ledger", "Document Source"::"Detailed Vendor Ledger"]) or
           ("Document Type" in ["Document Type"::Payment, "Document Type"::Invoice])
        then
            exit;

        if "Document Source" = "Document Source"::"Customer Ledger" then begin
            if SalesCrMemoHeader.Get("Document No.") then
                GetCorrInfoFromCustLedgEntry(CorrectedDocNo, CorrectionDate, SalesCrMemoHeader."Corrected Invoice No.")
            else begin
                CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
                CustLedgerEntry.SetRange("Document No.", "Document No.");
                CustLedgerEntry.SetRange("Posting Date", PostingDate);
                if CustLedgerEntry.FindFirst then
                    GetCorrInfoFromCustLedgEntry(CorrectedDocNo, CorrectionDate, CustLedgerEntry."Corrected Invoice No.");
            end;
            exit;
        end;

        if PurchCrMemoHdr.Get("Document No.") then
            GetCorrInfoFromVendLedgEntry(CorrectedDocNo, CorrectionDate, PurchCrMemoHdr."Corrected Invoice No.")
        else begin
            VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
            VendorLedgerEntry.SetRange("Document No.", "Document No.");
            VendorLedgerEntry.SetRange("Posting Date", PostingDate);
            if VendorLedgerEntry.FindFirst then
                GetCorrInfoFromVendLedgEntry(CorrectedDocNo, CorrectionDate, VendorLedgerEntry."Corrected Invoice No.");
        end;
    end;

    local procedure GetCorrInfoFromCustLedgEntry(var CorrectedDocNo: Code[35]; var CorrectionDate: Date; DocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if DocNo = '' then
            exit;

        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", DocNo);
        if CustLedgerEntry.FindFirst then begin
            CorrectedDocNo := CustLedgerEntry."Document No.";
            CorrectionDate := CustLedgerEntry."Posting Date";
        end;
    end;

    local procedure GetCorrInfoFromVendLedgEntry(var CorrectedDocNo: Code[35]; var CorrectionDate: Date; DocNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if DocNo = '' then
            exit;

        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", DocNo);
        if VendorLedgerEntry.FindFirst then begin
            if VendorLedgerEntry."External Document No." = '' then
                CorrectedDocNo := VendorLedgerEntry."Document No."
            else
                CorrectedDocNo := VendorLedgerEntry."External Document No.";
            CorrectionDate := VendorLedgerEntry."Document Date";
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateSalesSIIDocUploadStateInfo(CustNo: Code[20]; InvType: Option; CrMemoType: Option; SpecialSchemeCode: Option; SucceededCompanyName: Text[250]; SucceededVATRegNo: Text[20]; NewIDType: Option)
    begin
        Validate("CV No.", CustNo);
        if InvType = 0 then
            Validate("Sales Cr. Memo Type", CrMemoType)
        else
            Validate("Sales Invoice Type", InvType);
        Validate("Sales Special Scheme Code", SpecialSchemeCode);
        Validate("Succeeded Company Name", SucceededCompanyName);
        Validate("Succeeded VAT Registration No.", SucceededVATRegNo);
        Validate(IDType, NewIDType);
    end;

    [Scope('OnPrem')]
    procedure UpdatePurchSIIDocUploadState(VendNo: Code[20]; InvType: Option; CrMemoType: Option; SpecialSchemeCode: Option; SucceededCompanyName: Text[250]; SucceededVATRegNo: Text[20]; NewIDType: Option)
    begin
        Validate("CV No.", VendNo);
        if InvType = 0 then
            Validate("Purch. Cr. Memo Type", CrMemoType)
        else
            Validate("Purch. Invoice Type", InvType);
        Validate("Purch. Special Scheme Code", SpecialSchemeCode);
        Validate("Succeeded Company Name", SucceededCompanyName);
        Validate("Succeeded VAT Registration No.", SucceededVATRegNo);
        Validate(IDType, NewIDType);
    end;
    procedure GetSpecialSchemeCodes(var RegimeCodes: array[3] of Code[2])
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        i: Integer;
    begin
        case "Document Source" of
            "Document Source"::"Customer Ledger":
                begin
                    case "Document Type" of
                        "Document Type"::Invoice:
                            SIISalesDocumentSchemeCode.SetRange(
                              "Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
                        "Document Type"::"Credit Memo":
                            SIISalesDocumentSchemeCode.SetRange(
                              "Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo");
                        else
                            exit;
                    end;
                    SIISalesDocumentSchemeCode.SetRange("Document No.", "Document No.");
                    if SIISalesDocumentSchemeCode.FindSet() then begin
                        repeat
                            i += 1;
                            RegimeCodes[i] := CopyStr(Format(SIISalesDocumentSchemeCode."Special Scheme Code"), 1, 2);
                        until (SIISalesDocumentSchemeCode.Next() = 0) or (i = ArrayLen(RegimeCodes));
                        exit;
                    end;
                    RegimeCodes[1] := CopyStr(Format("Sales Special Scheme Code"), 1, 2);
                end;
            "Document Source"::"Vendor Ledger":
                begin
                    case "Document Type" of
                        "Document Type"::Invoice:
                            SIIPurchDocSchemeCode.SetRange(
                              "Document Type", SIIPurchDocSchemeCode."Document Type"::"Posted Invoice");
                        "Document Type"::"Credit Memo":
                            SIIPurchDocSchemeCode.SetRange(
                              "Document Type", SIIPurchDocSchemeCode."Document Type"::"Posted Credit Memo");
                        else
                            exit;
                    end;
                    SIIPurchDocSchemeCode.SetRange("Document No.", "Document No.");
                    if SIIPurchDocSchemeCode.FindSet() then begin
                        repeat
                            i += 1;
                            RegimeCodes[i] := CopyStr(Format(SIIPurchDocSchemeCode."Special Scheme Code"), 1, 2);
                        until (SIIPurchDocSchemeCode.Next() = 0) or (i = ArrayLen(RegimeCodes));
                        exit;
                    end;
                    RegimeCodes[1] := CopyStr(Format("Purch. Special Scheme Code"), 1, 2);
                end;
        end;
    end;
    	
}

