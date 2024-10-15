table 114 "Sales Cr.Memo Header"
{
    Caption = 'Sales Cr.Memo Header';
    DataCaptionFields = "No.", "Sell-to Customer Name";
    DrillDownPageID = "Posted Sales Credit Memos";
    LookupPageID = "Posted Sales Credit Memos";

    fields
    {
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
        }
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
        }
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code WHERE("Customer No." = FIELD("Sell-to Customer No."));
        }
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
        }
        field(14; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
        }
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
        }
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
        }
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(25; "Payment Discount %"; Decimal)
        {
            Caption = 'Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            Editable = false;
            TableRelation = "Customer Posting Group";
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(33; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;
        }
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        field(37; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
        }
        field(40; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = Exist("Sales Comment Line" WHERE("Document Type" = CONST("Posted Credit Memo"),
                                                            "No." = FIELD("No."),
                                                            "Document Line No." = CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(53; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
            begin
                CustLedgEntry.SetCurrentKey("Document No.");
                CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                OnLookupAppliesToDocNoOnAfterSetFilters(CustLedgEntry, Rec);
                PAGE.Run(0, CustLedgEntry);
            end;
        }
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account";
        }
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Cr.Memo Line".Amount WHERE("Document No." = FIELD("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Cr.Memo Line"."Amount Including VAT" WHERE("Document No." = FIELD("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(73; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(75; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
        }
        field(76; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(79; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
        }
        field(80; "Sell-to Customer Name 2"; Text[50])
        {
            Caption = 'Sell-to Customer Name 2';
        }
        field(81; "Sell-to Address"; Text[100])
        {
            Caption = 'Sell-to Address';
        }
        field(82; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';
        }
        field(83; "Sell-to City"; Text[30])
        {
            Caption = 'Sell-to City';
            TableRelation = "Post Code".City;
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(84; "Sell-to Contact"; Text[100])
        {
            Caption = 'Sell-to Contact';
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(88; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(89; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';
        }
        field(90; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(94; "Bal. Account Type"; enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(97; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(98; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(106; "Package Tracking No."; Text[30])
        {
            Caption = 'Package Tracking No.';
        }
        field(107; "Pre-Assigned No. Series"; Code[20])
        {
            Caption = 'Pre-Assigned No. Series';
            TableRelation = "No. Series";
        }
        field(108; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(111; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
        }
        field(112; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(113; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(119; "VAT Base Discount %"; Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(134; "Prepmt. Cr. Memo No. Series"; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            TableRelation = "No. Series";
        }
        field(136; "Prepayment Credit Memo"; Boolean)
        {
            Caption = 'Prepayment Credit Memo';
        }
        field(137; "Prepayment Order No."; Code[20])
        {
            Caption = 'Prepayment Order No.';
        }
        field(163; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Company Bank Account Code';
            TableRelation = "Bank Account" where("Currency Code" = FIELD("Currency Code"));
        }
        field(171; "Sell-to Phone No."; Text[30])
        {
            Caption = 'Sell-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(172; "Sell-to E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
        }
        field(179; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            Editable = false;
        }
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
            DataClassification = CustomerContent;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(710; "Document Exchange Identifier"; Text[50])
        {
            Caption = 'Document Exchange Identifier';
        }
        field(711; "Document Exchange Status"; Enum "Sales Document Exchange Status")
        {
            Caption = 'Document Exchange Status';
        }
        field(712; "Doc. Exch. Original Identifier"; Text[50])
        {
            Caption = 'Doc. Exch. Original Identifier';
        }
        field(1302; Paid; Boolean)
        {
            CalcFormula = - Exist("Cust. Ledger Entry" WHERE("Entry No." = FIELD("Cust. Ledger Entry No."),
                                                             Open = FILTER(true)));
            Caption = 'Paid';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1303; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Detailed Cust. Ledg. Entry".Amount WHERE("Cust. Ledger Entry No." = FIELD("Cust. Ledger Entry No.")));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1304; "Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Cust. Ledger Entry No.';
            Editable = false;
            TableRelation = "Cust. Ledger Entry"."Entry No.";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(1305; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Cr.Memo Line"."Inv. Discount Amount" WHERE("Document No." = FIELD("No.")));
            Caption = 'Invoice Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1310; Cancelled; Boolean)
        {
            CalcFormula = Exist("Cancelled Document" WHERE("Source ID" = CONST(114),
                                                            "Cancelled Doc. No." = FIELD("No.")));
            Caption = 'Cancelled';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1311; Corrective; Boolean)
        {
            CalcFormula = Exist("Cancelled Document" WHERE("Source ID" = CONST(112),
                                                            "Cancelled By Doc. No." = FIELD("No.")));
            Caption = 'Corrective';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(5052; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
            TableRelation = Contact;
        }
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            TableRelation = Contact;
        }
        field(5055; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = Opportunity;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(5794; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code WHERE("Shipping Agent Code" = FIELD("Shipping Agent Code"));
        }
        field(6601; "Return Order No."; Code[20])
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Return Order No.';
        }
        field(6602; "Return Order No. Series"; Code[20])
        {
            Caption = 'Return Order No. Series';
            TableRelation = "No. Series";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
        }
        field(7200; "Get Return Receipt Used"; Boolean)
        {
            Caption = 'Get Return Receipt Used';
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '15.0';
        }
        field(8001; "Draft Cr. Memo SystemId"; Guid)
        {
            Caption = 'Draft Cr. Memo System Id';
            DataClassification = SystemMetadata;
        }
        field(12400; "External Document Text"; Text[100])
        {
            Caption = 'External Document Text';
        }
        field(12410; "Consignor No."; Code[20])
        {
            Caption = 'Consignor No.';
            TableRelation = Vendor;
        }
        field(12440; "Corrective Document"; Boolean)
        {
            Caption = 'Corrective Document';
        }
        field(12441; "Corrected Doc. Type"; Option)
        {
            Caption = 'Corrected Doc. Type';
            OptionCaption = ' ,Invoice,Credit Memo';
            OptionMembers = " ",Invoice,"Credit Memo";
        }
        field(12442; "Corrected Doc. No."; Code[20])
        {
            Caption = 'Corrected Doc. No.';
            TableRelation = IF ("Corrected Doc. Type" = CONST(Invoice)) "Sales Invoice Header"
            ELSE
            IF ("Corrected Doc. Type" = CONST("Credit Memo")) "Sales Cr.Memo Header";
        }
        field(12443; "Original Doc. Type"; Option)
        {
            Caption = 'Original Doc. Type';
            OptionCaption = ' ,Invoice,Credit Memo';
            OptionMembers = " ",Invoice,"Credit Memo";
        }
        field(12444; "Original Doc. No."; Code[20])
        {
            Caption = 'Original Doc. No.';
        }
        field(12445; "VAT Entry Type"; Code[15])
        {
            Caption = 'VAT Entry Type';
        }
        field(12446; "Corrective Doc. Type"; Option)
        {
            Caption = 'Corrective Doc. Type';
            OptionCaption = ' ,Correction,Revision';
            OptionMembers = " ",Correction,Revision;
        }
        field(12447; "Revision No."; Code[20])
        {
            Caption = 'Revision No.';
        }
        field(12451; "Act Signed by Name"; Text[30])
        {
            Caption = 'Act Signed by Name';
        }
        field(12452; "Act Signed by Position"; Text[30])
        {
            Caption = 'Act Signed by Position';
        }
        field(12480; "KPP Code"; Code[10])
        {
            Caption = 'KPP Code';
        }
        field(12485; "Orig. Invoice No."; Code[20])
        {
            Caption = 'Orig. Invoice No.';
        }
        field(12486; "Include In Purch. VAT Ledger"; Boolean)
        {
            Caption = 'Include In Purch. VAT Ledger';
        }
        field(12490; "Agreement No."; Code[20])
        {
            Caption = 'Agreement No.';
            TableRelation = "Customer Agreement"."No." WHERE("Customer No." = FIELD("Bill-to Customer No."));
        }
        field(12498; "Additional VAT Ledger Sheet"; Boolean)
        {
            Caption = 'Additional VAT Ledger Sheet';
        }
        field(12499; "Corrected Document Date"; Date)
        {
            Caption = 'Corrected Document Date';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Pre-Assigned No.")
        {
        }
        key(Key3; "Return Order No.")
        {
        }
        key(Key4; "Sell-to Customer No.")
        {
        }
        key(Key5; "Prepayment Order No.")
        {
        }
        key(Key6; "Bill-to Customer No.")
        {
        }
        key(Key7; "Posting Date")
        {
        }
        key(Key8; "Document Exchange Status")
        {
        }
        key(Key9; "Salesperson Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Sell-to Customer No.", "Bill-to Customer No.", "Posting Date", "Posting Description")
        {
        }
        fieldgroup(Brick; "No.", "Sell-to Customer Name", Amount, "Due Date", "Amount Including VAT")
        {
        }
    }

    trigger OnDelete()
    var
        PostedDeferralHeader: Record "Posted Deferral Header";
        PostSalesDelete: Codeunit "PostSales-Delete";
    begin
        PostSalesDelete.IsDocumentDeletionAllowed("Posting Date");
        TestField("No. Printed");
        LockTable();
        PostSalesDelete.DeleteSalesCrMemoLines(Rec);

        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::"Posted Credit Memo");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.DeleteAll();

        DocSignMgt.DeletePostedDocSign(DATABASE::"Sales Cr.Memo Header", "No.");

        ApprovalsMgmt.DeletePostedApprovalEntries(RecordId);
        PostedDeferralHeader.DeleteForDoc(
            "Deferral Document Type"::Sales.AsInteger(), '', '',
            SalesCommentLine."Document Type"::"Posted Credit Memo".AsInteger(), "No.");
    end;

    var
        SalesCommentLine: Record "Sales Comment Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        DimMgt: Codeunit DimensionManagement;
        UserSetupMgt: Codeunit "User Setup Management";
        DocSignMgt: Codeunit "Doc. Signature Management";

    procedure SendRecords()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        DocumentTypeTxt: Text[50];
        IsHandled: Boolean;
    begin
        DocumentTypeTxt := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        IsHandled := false;
        OnBeforeSendRecords(DummyReportSelections, Rec, DocumentTypeTxt, IsHandled);
        if IsHandled then
            exit;

        DocumentSendingProfile.SendCustomerRecords(
          DummyReportSelections.Usage::"S.Cr.Memo".AsInteger(), Rec, DocumentTypeTxt, "Bill-to Customer No.", "No.",
          FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    local procedure SendRecords(ShowRequestForm: Boolean; SendAsEmail: Boolean)
    var
        ReportSelection: Record "Report Selections";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReportSelectionTmp: Record "Report Selections" temporary;
        TempSalesHeader: Record "Sales Header" temporary;
        CorrDocMgt: Codeunit "Corrective Document Mgt.";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendRecords(ReportSelection, Rec, '', IsHandled);
        if IsHandled then
            exit;

        with SalesCrMemoHeader do begin
            Copy(Rec);
            CorrDocMgt.FillSalesCrMemoCorrHeader(TempSalesHeader, SalesCrMemoHeader);
            if CorrDocMgt.IsCorrDocument(TempSalesHeader) then begin
                if SendAsEmail then
                    ReportSelection.SendEmailToCust(
                      ReportSelection.Usage::CSCM.AsInteger(), SalesCrMemoHeader, "No.", '', ShowRequestForm, "Bill-to Customer No.")
                else
                    ReportSelection.PrintWithDialogForCust(
                      ReportSelection.Usage::CSCM, SalesCrMemoHeader, ShowRequestForm, FieldNo("Bill-to Customer No."));
            end else begin
                if SendAsEmail then
                    ReportSelection.SendEmailToCust(
                      ReportSelection.Usage::"S.Cr.Memo".AsInteger(), SalesCrMemoHeader, "No.",
                      ReportDistributionMgt.GetFullDocumentTypeText(SalesCrMemoHeader), ShowRequestForm, "Bill-to Customer No.")
                else
                    ReportSelection.PrintWithDialogForCust(
                      ReportSelection.Usage::"S.Cr.Memo", SalesCrMemoHeader, ShowRequestForm, FieldNo("Bill-to Customer No."));
            end;
        end;
    end;

    procedure SendProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    var
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        DocumentTypeTxt: Text[50];
        IsHandled: Boolean;
    begin
        DocumentTypeTxt := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        IsHandled := false;
        OnBeforeSendProfile(DummyReportSelections, Rec, DocumentTypeTxt, IsHandled, DocumentSendingProfile);
        if IsHandled then
            exit;

        DocumentSendingProfile.Send(
          DummyReportSelections.Usage::"S.Cr.Memo".AsInteger(), Rec, "No.", "Bill-to Customer No.",
          DocumentTypeTxt, FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    procedure StartTrackingSite()
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        TestField("Shipping Agent Code");
        ShippingAgent.Get("Shipping Agent Code");
        HyperLink(ShippingAgent.GetTrackingInternetAddr("Package Tracking No."));
    end;

    procedure PrintRecords(ShowRequestPage: Boolean)
    var
        DummyReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(DummyReportSelections, Rec, ShowRequestPage, IsHandled);
        if IsHandled then
            exit;

        SendRecords(ShowRequestPage, false);
    end;

    procedure EmailRecords(ShowRequestPage: Boolean)
    var
        DummyReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEmailRecords(DummyReportSelections, Rec, '', ShowRequestPage, IsHandled);
        if IsHandled then
            exit;

        SendRecords(ShowRequestPage, true);
    end;

    procedure PrintToDocumentAttachment(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := SalesCrMemoHeader.Count() = 1;
        if SalesCrMemoHeader.FindSet() then
            repeat
                DoPrintToDocumentAttachment(SalesCrMemoHeader, ShowNotificationAction);
            until SalesCrMemoHeader.Next() = 0;
    end;

    local procedure DoPrintToDocumentAttachment(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; ShowNotificationAction: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        SalesCrMemoHeader.SetRecFilter();
        ReportSelections.SaveAsDocumentAttachment(
            ReportSelections.Usage::"S.Cr.Memo".AsInteger(), SalesCrMemoHeader, SalesCrMemoHeader."No.", SalesCrMemoHeader."Bill-to Customer No.", ShowNotificationAction);
    end;

    procedure Navigate()
    var
        NavigatePage: Page Navigate;
    begin
        NavigatePage.SetDoc("Posting Date", "No.");
        NavigatePage.SetRec(Rec);
        NavigatePage.Run();
    end;

    procedure LookupAdjmtValueEntries()
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", "No.");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Credit Memo");
        ValueEntry.SetRange(Adjustment, true);
        PAGE.RunModal(0, ValueEntry);
    end;

    procedure GetCustomerVATRegistrationNumber(): Text
    begin
        exit("VAT Registration No.");
    end;

    procedure GetCustomerVATRegistrationNumberLbl(): Text
    begin
        exit(FieldCaption("VAT Registration No."));
    end;

    procedure GetCustomerGlobalLocationNumber(): Text
    begin
        exit('');
    end;

    procedure GetCustomerGlobalLocationNumberLbl(): Text
    begin
        exit('');
    end;

    procedure GetLegalStatement(): Text
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        exit(SalesSetup.GetLegalStatement());
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."));
    end;

    procedure SetSecurityFilterOnRespCenter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetupMgt.GetSalesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetSalesFilter());
            FilterGroup(0);
        end;
    end;

    [Scope('OnPrem')]
    procedure FindReturnReceipts(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DocNoFilter: Text[250];
        I: Integer;
        Text12400: Label 'Length of the Document No. filter should not exceed 1024.';
    begin
        DocNoFilter := '';
        I := 0;

        SalesCrMemoLine.Reset();
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
        SalesCrMemoLine.SetFilter(Quantity, '>%1', 0);
        if SalesCrMemoLine.Find('-') then
            repeat
                ValueEntry.Reset();
                ValueEntry.SetCurrentKey("Item No.", "Posting Date", "Document No.");
                ValueEntry.SetRange("Document No.", SalesCrMemoHeader."No.");
                ValueEntry.SetRange("Posting Date", SalesCrMemoHeader."Posting Date");
                ValueEntry.SetRange("Item No.", SalesCrMemoLine."No.");
                if ValueEntry.Find('-') then
                    repeat
                        ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                        ReturnReceiptHeader.Get(ItemLedgEntry."Document No.");
                        I := I + 1;
                        if I = 1 then
                            DocNoFilter := ReturnReceiptHeader."No."
                        else begin
                            if StrPos('|' + DocNoFilter + '|', '|' + ReturnReceiptHeader."No." + '|') = 0 then
                                if (StrLen(DocNoFilter) + StrLen(ReturnReceiptHeader."No.")) < MaxStrLen(DocNoFilter) then
                                    DocNoFilter := DocNoFilter + '|' + ReturnReceiptHeader."No."
                                else
                                    Error(Text12400);
                        end;
                    until ValueEntry.Next() = 0;
            until SalesCrMemoLine.Next() = 0;
        if DocNoFilter = '' then
            DocNoFilter := '.';
        ReturnReceiptHeader.Reset();
        ReturnReceiptHeader.SetFilter("No.", DocNoFilter);
        PAGE.Run(PAGE::"Posted Return Receipts", ReturnReceiptHeader);
    end;

    procedure GetDocExchStatusStyle(): Text
    begin
        case "Document Exchange Status" of
            "Document Exchange Status"::"Not Sent":
                exit('Standard');
            "Document Exchange Status"::"Sent to Document Exchange Service":
                exit('Ambiguous');
            "Document Exchange Status"::"Delivered to Recipient":
                exit('Favorable');
            else
                exit('Unfavorable');
        end;
    end;

    procedure ShowActivityLog()
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.ShowEntries(RecordId);
    end;

    procedure DocExchangeStatusIsSent(): Boolean
    begin
        exit("Document Exchange Status" <> "Document Exchange Status"::"Not Sent");
    end;

    procedure ShowCanceledOrCorrInvoice()
    begin
        CalcFields(Cancelled, Corrective);
        case true of
            Cancelled:
                ShowCorrectiveInvoice();
            Corrective:
                ShowCancelledInvoice();
        end;
    end;

    procedure ShowCorrectiveInvoice()
    var
        CancelledDocument: Record "Cancelled Document";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        CalcFields(Cancelled);
        if not Cancelled then
            exit;

        if CancelledDocument.FindSalesCancelledCrMemo("No.") then begin
            SalesInvHeader.Get(CancelledDocument."Cancelled By Doc. No.");
            PAGE.Run(PAGE::"Posted Sales Invoice", SalesInvHeader);
        end;
    end;

    procedure ShowCancelledInvoice()
    var
        CancelledDocument: Record "Cancelled Document";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        CalcFields(Corrective);
        if not Corrective then
            exit;

        if CancelledDocument.FindSalesCorrectiveCrMemo("No.") then begin
            SalesInvHeader.Get(CancelledDocument."Cancelled Doc. No.");
            PAGE.Run(PAGE::"Posted Sales Invoice", SalesInvHeader);
        end;
    end;

    procedure GetWorkDescription(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Work Description");
        "Work Description".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmailRecords(var ReportSelections: Record "Report Selections"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocTxt: Text; ShowDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var ReportSelections: Record "Report Selections"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; ShowRequestPage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendProfile(var ReportSelections: Record "Report Selections"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocTxt: Text; var IsHandled: Boolean; var DocumentSendingProfile: Record "Document Sending Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendRecords(var ReportSelections: Record "Report Selections"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocTxt: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;
}

