table 36 "Sales Header"
{
    Caption = 'Sales Header';
    DataCaptionFields = "No.", "Sell-to Customer Name";
    LookupPageID = "Sales List";
    Permissions = tabledata "Assemble-to-Order Link" = rmid,
                  tabledata "Assembly Header" = m;

    fields
    {
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                StandardCodesMgt: Codeunit "Standard Codes Mgt.";
                IsHandled: Boolean;
            begin
                CheckCreditLimitIfLineNotInsertedYet;
                if "No." = '' then
                    InitRecord;
                TestStatusOpen;
                if ("Sell-to Customer No." <> xRec."Sell-to Customer No.") and
                   (xRec."Sell-to Customer No." <> '')
                then begin
                    if ("Opportunity No." <> '') and ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) then
                        Error(
                          Text062,
                          FieldCaption("Sell-to Customer No."),
                          FieldCaption("Opportunity No."),
                          "Opportunity No.",
                          "Document Type");
                    if GetHideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, SellToCustomerTxt);
                    if Confirmed then begin
                        SalesLine.SetRange("Document Type", "Document Type");
                        SalesLine.SetRange("Document No.", "No.");
                        if "Sell-to Customer No." = '' then begin
                            if SalesLine.FindFirst then
                                Error(
                                  Text005,
                                  FieldCaption("Sell-to Customer No."));
                            Init;
                            OnValidateSellToCustomerNoAfterInit(Rec, xRec);
                            GetSalesSetup;
                            "No. Series" := xRec."No. Series";
                            InitRecord;
                            InitNoSeries;
                            exit;
                        end;

                        CheckShipmentInfo(SalesLine, false);
                        CheckPrepmtInfo(SalesLine);
                        CheckReturnInfo(SalesLine, false);

                        SalesLine.Reset();
                    end else begin
                        Rec := xRec;
                        exit;
                    end;
                end;

                if ("Document Type" = "Document Type"::Order) and
                   (xRec."Sell-to Customer No." <> "Sell-to Customer No.")
                then begin
                    SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter("Purch. Order Line No.", '<>0');
                    if not SalesLine.IsEmpty() then
                        Error(
                          Text006,
                          FieldCaption("Sell-to Customer No."));
                    SalesLine.Reset();
                end;

                GetCust("Sell-to Customer No.");
                IsHandled := false;
                OnValidateSellToCustomerNoOnBeforeCheckBlockedCustOnDocs(Rec, Cust, IsHandled);
                if not IsHandled then
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, false);
                if not ApplicationAreaMgmt.IsSalesTaxEnabled then
                    Cust.TestField("Gen. Bus. Posting Group");
                OnAfterCheckSellToCust(Rec, xRec, Cust, CurrFieldNo);

                CopySellToCustomerAddressFieldsFromCustomer(Cust);

                if "Sell-to Customer No." = xRec."Sell-to Customer No." then
                    if ShippedSalesLinesExist or ReturnReceiptExist then begin
                        TestField("VAT Bus. Posting Group", xRec."VAT Bus. Posting Group");
                        TestField("Gen. Bus. Posting Group", xRec."Gen. Bus. Posting Group");
                    end;

                "Sell-to IC Partner Code" := Cust."IC Partner Code";
                "Send IC Document" := ("Sell-to IC Partner Code" <> '') and ("IC Direction" = "IC Direction"::Outgoing);

                UpdateShipToCodeFromCust();
                SetBillToCustomerNo(Cust);

                GetShippingTime(FieldNo("Sell-to Customer No."));

                if (xRec."Sell-to Customer No." <> "Sell-to Customer No.") or
                   (xRec."Currency Code" <> "Currency Code") or
                   (xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group") or
                   (xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group")
                then
                    RecreateSalesLines(SellToCustomerTxt);

                if not SkipSellToContact then
                    UpdateSellToCont("Sell-to Customer No.");

                OnValidateSellToCustomerNoOnBeforeRecallModifyAddressNotification(Rec, xRec);
                if (xRec."Sell-to Customer No." <> '') and (xRec."Sell-to Customer No." <> "Sell-to Customer No.") then
                    RecallModifyAddressNotification(GetModifyCustomerAddressNotificationId);
            end;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    GetSalesSetup;
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                end;
            end;
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate()
            var
#if not CLEAN18
                CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
#endif
                IsHandled: Boolean;
            begin
                TestStatusOpen;
                BilltoCustomerNoChanged := xRec."Bill-to Customer No." <> "Bill-to Customer No.";
                if BilltoCustomerNoChanged then
                    if xRec."Bill-to Customer No." = '' then
                        InitRecord
                    else begin
                        if GetHideValidationDialog or not GuiAllowed then
                            Confirmed := true
                        else
                            Confirmed := Confirm(ConfirmChangeQst, false, BillToCustomerTxt);
                        if Confirmed then begin
                            OnValidateBillToCustomerNoOnAfterConfirmed(Rec);

                            SalesLine.SetRange("Document Type", "Document Type");
                            SalesLine.SetRange("Document No.", "No.");

                            CheckShipmentInfo(SalesLine, true);
                            CheckPrepmtInfo(SalesLine);
                            CheckReturnInfo(SalesLine, true);

                            SalesLine.Reset();
                        end else
                            "Bill-to Customer No." := xRec."Bill-to Customer No.";
                    end;

                GetCust("Bill-to Customer No.");
                IsHandled := false;
                OnValidateBillToCustomerNoOnBeforeCheckBlockedCustOnDocs(Rec, Cust, IsHandled);
                if not IsHandled then
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, false);
                Cust.TestField("Customer Posting Group");
                PostingSetupMgt.CheckCustPostingGroupReceivablesAccount("Customer Posting Group");
                CheckCreditLimit;
                OnAfterCheckBillToCust(Rec, xRec, Cust);

                SetBillToCustomerAddressFieldsFromCustomer(Cust);

                if not BilltoCustomerNoChanged then
                    if ShippedSalesLinesExist then begin
                        TestField("Customer Disc. Group", xRec."Customer Disc. Group");
                        TestField("Currency Code", xRec."Currency Code");
                    end;

#if not CLEAN18
                if not CustomerTemplMgt.IsEnabled() then
                    CreateDim(
                      DATABASE::Customer, "Bill-to Customer No.",
                      DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                      DATABASE::Campaign, "Campaign No.",
                      DATABASE::"Responsibility Center", "Responsibility Center",
                      DATABASE::"Customer Template", "Bill-to Customer Template Code")
                else
#endif
                    CreateDim(
                      DATABASE::Customer, "Bill-to Customer No.",
                      DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                      DATABASE::Campaign, "Campaign No.",
                      DATABASE::"Responsibility Center", "Responsibility Center",
                      DATABASE::"Customer Templ.", "Bill-to Customer Templ. Code");

                Validate("Payment Terms Code");
                Validate("Prepmt. Payment Terms Code");
                Validate("Payment Method Code");
                Validate("Currency Code");
                Validate("Prepayment %");

                if (xRec."Sell-to Customer No." = "Sell-to Customer No.") and
                   (xRec."Bill-to Customer No." <> "Bill-to Customer No.")
                then begin
                    RecreateSalesLines(BillToCustomerTxt);
                    BilltoCustomerNoChanged := false;
                end;
                if not SkipBillToContact then
                    UpdateBillToCont("Bill-to Customer No.");

                "Bill-to IC Partner Code" := Cust."IC Partner Code";
                "Send IC Document" := ("Bill-to IC Partner Code" <> '') and ("IC Direction" = "IC Direction"::Outgoing);

                OnValidateBillToCustomerNoOnBeforeRecallModifyAddressNotification(Rec, xRec);
                if (xRec."Bill-to Customer No." <> '') and (xRec."Bill-to Customer No." <> "Bill-to Customer No.") then
                    RecallModifyAddressNotification(GetModifyBillToCustomerAddressNotificationId);
            end;
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                Customer: Record Customer;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBillToName(Rec, Customer, IsHandled);
                if IsHandled then
                    exit;

                if "Bill-to Customer No." <> '' then
                    Customer.Get("Bill-to Customer No.");

                if Customer.LookupCustomer(Customer) then begin
                    xRec := Rec;
                    "Bill-to Name" := Customer.Name;
                    Validate("Bill-to Customer No.", Customer."No.");
                end;
            end;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                OnBeforeValidateBillToCustomerName(Rec, Customer);

                if ShouldSearchForCustomerByName("Bill-to Customer No.") then
                    Validate("Bill-to Customer No.", Customer.GetCustNo("Bill-to Name"));
            end;
        }
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
        }
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            TableRelation = IF ("Bill-to Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Bill-to Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Bill-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                ModifyBillToCustomerAddress;
            end;
        }
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';

            trigger OnLookup()
            var
                Contact: Record Contact;
            begin
                Contact.FilterGroup(2);
                LookupContact("Bill-to Customer No.", "Bill-to Contact No.", Contact);
                if PAGE.RunModal(0, Contact) = ACTION::LookupOK then
                    Validate("Bill-to Contact No.", Contact."No.");
                Contact.FilterGroup(0);
            end;

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code WHERE("Customer No." = FIELD("Sell-to Customer No."));

            trigger OnValidate()
            var
                ShipToAddr: Record "Ship-to Address";
                IsHandled: Boolean;
                CopyShipToAddress: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipToCode(Rec, xRec, Cust, ShipToAddr, IsHandled);
                if IsHandled then
                    exit;

                if ("Document Type" = "Document Type"::Order) and
                   (xRec."Ship-to Code" <> "Ship-to Code")
                then begin
                    SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter("Purch. Order Line No.", '<>0');
                    if not SalesLine.IsEmpty() then
                        Error(
                          Text006,
                          FieldCaption("Ship-to Code"));
                    SalesLine.Reset();
                end;

                CopyShipToAddress := not IsCreditDocType;
                OnValidateShipToCodeOnBeforeCopyShipToAddress(Rec, xRec, CopyShipToAddress);
                if CopyShipToAddress then
                    if "Ship-to Code" <> '' then begin
                        if xRec."Ship-to Code" <> '' then begin
                            GetCust("Sell-to Customer No.");
                            SetCustomerLocationCode();
                            "Tax Area Code" := Cust."Tax Area Code";
                        end;
                        ShipToAddr.Get("Sell-to Customer No.", "Ship-to Code");
                        SetShipToCustomerAddressFieldsFromShipToAddr(ShipToAddr);
                    end else
                        if "Sell-to Customer No." <> '' then begin
                            GetCust("Sell-to Customer No.");
                            CopyShipToCustomerAddressFieldsFromCust(Cust);
                        end;

                GetShipmentMethodCode();
                GetShippingTime(FieldNo("Ship-to Code"));

                if (xRec."Sell-to Customer No." = "Sell-to Customer No.") and
                   (xRec."Ship-to Code" <> "Ship-to Code")
                then
                    if (xRec."VAT Country/Region Code" <> "VAT Country/Region Code") or
                       (xRec."Tax Area Code" <> "Tax Area Code")
                    then
                        RecreateSalesLines(FieldCaption("Ship-to Code"))
                    else begin
                        if xRec."Shipping Agent Code" <> "Shipping Agent Code" then
                            MessageIfSalesLinesExist(FieldCaption("Shipping Agent Code"));
                        if xRec."Shipping Agent Service Code" <> "Shipping Agent Service Code" then
                            MessageIfSalesLinesExist(FieldCaption("Shipping Agent Service Code"));
                        OnValidateShipToCodeOnBeforeValidateTaxLiable(Rec, xRec);
                        if xRec."Tax Liable" <> "Tax Liable" then
                            Validate("Tax Liable");
                    end;
            end;
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
            TableRelation = IF ("Ship-to Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Ship-to Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Ship-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupShipToCity(Rec, PostCode);

                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");

                OnAfterLookupShipToCity(Rec, PostCode);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
        }
        field(19; "Order Date"; Date)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Order Date';

            trigger OnValidate()
            begin
                if ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) and
                   not ("Order Date" = xRec."Order Date")
                then
                    PriceMessageIfSalesLinesExist(FieldCaption("Order Date"));
            end;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
                NeedUpdateCurrencyFactor: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostingDate(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Posting Date");
                TestNoSeriesDate(
                  "Posting No.", "Posting No. Series",
                  FieldCaption("Posting No."), FieldCaption("Posting No. Series"));
                TestNoSeriesDate(
                  "Prepayment No.", "Prepayment No. Series",
                  FieldCaption("Prepayment No."), FieldCaption("Prepayment No. Series"));
                TestNoSeriesDate(
                  "Prepmt. Cr. Memo No.", "Prepmt. Cr. Memo No. Series",
                  FieldCaption("Prepmt. Cr. Memo No."), FieldCaption("Prepmt. Cr. Memo No. Series"));

                IsHandled := false;
                OnValidatePostingDateOnBeforeAssignDocumentDate(Rec, IsHandled);
                if not IsHandled then
                    if "Incoming Document Entry No." = 0 then
                        Validate("Document Date", "Posting Date");

                if ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) and
                   not ("Posting Date" = xRec."Posting Date")
                then
                    PriceMessageIfSalesLinesExist(FieldCaption("Posting Date"));

                NeedUpdateCurrencyFactor := "Currency Code" <> '';
                OnValidatePostingDateOnBeforeCheckNeedUpdateCurrencyFactor(Rec, Confirmed, NeedUpdateCurrencyFactor);
                if NeedUpdateCurrencyFactor then begin
                    UpdateCurrencyFactor;
                    if ("Currency Factor" <> xRec."Currency Factor") and not CalledFromWhseDoc then
                        ConfirmCurrencyFactorUpdate();
                end;

                if "Posting Date" <> xRec."Posting Date" then
                    if DeferralHeadersExist then
                        ConfirmUpdateDeferralDate;
                SynchronizeAsmHeader;
            end;
        }
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';

            trigger OnValidate()
            begin
                UpdateSalesLinesByFieldNo(FieldNo("Shipment Date"), CurrFieldNo <> 0);
            end;
        }
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                    PaymentTerms.Get("Payment Terms Code");
                    if IsCreditDocType and not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeValidateDueDate(Rec, xRec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            Validate("Due Date", "Document Date");
                        Validate("Pmt. Discount Date", 0D);
                        Validate("Payment Discount %", 0);
                    end else begin
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalcDueDate(Rec, xRec, FieldNo("Payment Terms Code"), CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalcPmtDiscDate(Rec, xRec, FieldNo("Payment Terms Code"), CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                        if not UpdateDocumentDate then
                            Validate("Payment Discount %", PaymentTerms."Discount %")
                    end;
                end else begin
                    IsHandled := false;
                    OnValidatePaymentTermsCodeOnBeforeValidateDueDateWhenBlank(Rec, xRec, CurrFieldNo, IsHandled);
                    if not IsHandled then
                        Validate("Due Date", "Document Date");
                    if not UpdateDocumentDate then begin
                        Validate("Pmt. Discount Date", 0D);
                        Validate("Payment Discount %", 0);
                    end;
                end;
                if xRec."Payment Terms Code" = "Prepmt. Payment Terms Code" then begin
                    if xRec."Prepayment Due Date" = 0D then begin
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalculatePrepaymentDueDate(Rec, xRec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Prepayment Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                    end;
                    Validate("Prepmt. Payment Terms Code", "Payment Terms Code");
                end;
            end;
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

            trigger OnValidate()
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date"), FieldNo("Document Date")]) then
                    TestStatusOpen;
                GLSetup.Get();
                if "Payment Discount %" < GLSetup."VAT Tolerance %" then
                    "VAT Base Discount %" := "Payment Discount %"
                else
                    "VAT Base Discount %" := GLSetup."VAT Tolerance %";
                Validate("VAT Base Discount %");
            end;
        }
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipmentMethodCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen;
            end;
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            begin
                TestStatusOpen;
                if ("Location Code" <> xRec."Location Code") and
                   (xRec."Sell-to Customer No." = "Sell-to Customer No.")
                then
                    MessageIfSalesLinesExist(FieldCaption("Location Code"));

                UpdateShipToAddress;
                UpdateOutboundWhseHandlingTime;
            end;
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2),
                                                          Blocked = CONST(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
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
            TableRelation = Currency;

            trigger OnValidate()
            var
                StandardCodesMgt: Codeunit "Standard Codes Mgt.";
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date")]) or ("Currency Code" <> xRec."Currency Code") then
                    TestStatusOpen;
                if (CurrFieldNo <> FieldNo("Currency Code")) and ("Currency Code" = xRec."Currency Code") then
                    UpdateCurrencyFactor
                else
                    if "Currency Code" <> xRec."Currency Code" then
                        UpdateCurrencyFactor
                    else
                        if "Currency Code" <> '' then begin
                            UpdateCurrencyFactor;
                            if "Currency Factor" <> xRec."Currency Factor" then
                                ConfirmCurrencyFactorUpdate();
                        end;

                if ("No." <> '') and ("Currency Code" <> xRec."Currency Code") then
                    StandardCodesMgt.CheckShowSalesRecurringLinesNotification(Rec);
            end;
        }
        field(33; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Currency Factor" <> xRec."Currency Factor" then
                    UpdateSalesLinesByFieldNo(FieldNo("Currency Factor"), false);
            end;
        }
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                MessageIfSalesLinesExist(FieldCaption("Customer Price Group"));
            end;
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';

            trigger OnValidate()
            var
                SalesLine: Record "Sales Line";
                Currency: Record Currency;
                RecalculatePrice: Boolean;
                VatFactor: Decimal;
                LineInvDiscAmt: Decimal;
                InvDiscRounding: Decimal;
            begin
                TestStatusOpen;

                if "Prices Including VAT" <> xRec."Prices Including VAT" then begin
                    SalesLine.SetRange("Document Type", "Document Type");
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter("Job Contract Entry No.", '<>%1', 0);
                    if SalesLine.Find('-') then begin
                        SalesLine.TestField("Job No.", '');
                        SalesLine.TestField("Job Contract Entry No.", 0);
                    end;

                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", "Document Type");
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter("Unit Price", '<>%1', 0);
                    SalesLine.SetFilter("VAT %", '<>%1', 0);
                    if SalesLine.FindFirst then begin
                        RecalculatePrice := ConfirmRecalculatePrice(SalesLine);
                        OnAfterConfirmSalesPrice(Rec, SalesLine, RecalculatePrice);
                        SalesLine.SetSalesHeader(Rec);

                        if "Currency Code" = '' then
                            Currency.InitRoundingPrecision
                        else
                            Currency.Get("Currency Code");
                        SalesLine.LockTable();
                        LockTable();
                        SalesLine.FindSet();
                        repeat
                            SalesLine.TestField("Quantity Invoiced", 0);
                            SalesLine.TestField("Prepmt. Amt. Inv.", 0);
                            if not RecalculatePrice then begin
                                SalesLine."VAT Difference" := 0;
                                SalesLine.UpdateAmounts;
                            end else begin
                                VatFactor := 1 + SalesLine."VAT %" / 100;
                                if VatFactor = 0 then
                                    VatFactor := 1;
                                if not "Prices Including VAT" then
                                    VatFactor := 1 / VatFactor;
                                if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Full VAT" then
                                    VatFactor := 1;
                                SalesLine."Unit Price" :=
                                  Round(SalesLine."Unit Price" * VatFactor, Currency."Unit-Amount Rounding Precision");
                                SalesLine."Line Discount Amount" :=
                                  Round(
                                    SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Line Discount %" / 100,
                                    Currency."Amount Rounding Precision");
                                LineInvDiscAmt := InvDiscRounding + SalesLine."Inv. Discount Amount" * VatFactor;
                                SalesLine."Inv. Discount Amount" := Round(LineInvDiscAmt, Currency."Amount Rounding Precision");
                                InvDiscRounding := LineInvDiscAmt - SalesLine."Inv. Discount Amount";
                                if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Full VAT" then
                                    SalesLine."Line Amount" := SalesLine."Amount Including VAT"
                                else
                                    if "Prices Including VAT" then
                                        SalesLine."Line Amount" := SalesLine."Amount Including VAT" + SalesLine."Inv. Discount Amount"
                                    else
                                        SalesLine."Line Amount" := SalesLine.Amount + SalesLine."Inv. Discount Amount";
                                UpdatePrepmtAmounts(SalesLine);
                            end;
                            OnValidatePricesIncludingVATOnBeforeSalesLineModify(Rec, SalesLine, Currency, RecalculatePrice);
                            SalesLine.Modify();
                        until SalesLine.Next() = 0;
                    end;
                    OnAfterChangePricesIncludingVAT(Rec);
                end;
            end;
        }
        field(37; "Invoice Disc. Code"; Code[20])
        {
            AccessByPermission = TableData "Cust. Invoice Disc." = R;
            Caption = 'Invoice Disc. Code';

            trigger OnValidate()
            begin
                TestStatusOpen;
                MessageIfSalesLinesExist(FieldCaption("Invoice Disc. Code"));
            end;
        }
        field(40; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                MessageIfSalesLinesExist(FieldCaption("Customer Disc. Group"));
            end;
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnValidate()
            begin
                MessageIfSalesLinesExist(FieldCaption("Language Code"));
            end;
        }
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            var
                ApprovalEntry: Record "Approval Entry";
                EnumAssignmentMgt: Codeunit "Enum Assignment Management";
#if not CLEAN18
                CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
#endif
            begin
                ValidateSalesPersonOnSalesHeader(Rec, false, false);

                ApprovalEntry.SetRange("Table ID", DATABASE::"Sales Header");
                ApprovalEntry.SetRange("Document Type", EnumAssignmentMgt.GetSalesApprovalDocumentType("Document Type"));
                ApprovalEntry.SetRange("Document No.", "No.");
                ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Created, ApprovalEntry.Status::Open);
                if not ApprovalEntry.IsEmpty() then
                    Error(Text053, FieldCaption("Salesperson Code"));

#if not CLEAN18
                if not CustomerTemplMgt.IsEnabled() then
                    CreateDim(
                      DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                      DATABASE::Customer, "Bill-to Customer No.",
                      DATABASE::Campaign, "Campaign No.",
                      DATABASE::"Responsibility Center", "Responsibility Center",
                      DATABASE::"Customer Template", "Bill-to Customer Template Code")
                else
#endif
                    CreateDim(
                      DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                      DATABASE::Customer, "Bill-to Customer No.",
                      DATABASE::Campaign, "Campaign No.",
                      DATABASE::"Responsibility Center", "Responsibility Center",
                      DATABASE::"Customer Templ.", "Bill-to Customer Templ. Code");
            end;
        }
        field(45; "Order Class"; Code[10])
        {
            Caption = 'Order Class';
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = Exist("Sales Comment Line" WHERE("Document Type" = FIELD("Document Type"),
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
                GenJnlLine: Record "Gen. Journal Line";
                GenJnlApply: Codeunit "Gen. Jnl.-Apply";
                ApplyCustEntries: Page "Apply Customer Entries";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupAppliesToDocNo(Rec, CustLedgEntry, IsHandled);
                if IsHandled then
                    exit;

                TestField("Bal. Account No.", '');
                CustLedgEntry.SetApplyToFilters("Bill-to Customer No.", "Applies-to Doc. Type".AsInteger(), "Applies-to Doc. No.", Amount);
                OnAfterSetApplyToFilters(CustLedgEntry, Rec);

                ApplyCustEntries.SetSales(Rec, CustLedgEntry, SalesHeader.FieldNo("Applies-to Doc. No."));
                ApplyCustEntries.SetTableView(CustLedgEntry);
                ApplyCustEntries.SetRecord(CustLedgEntry);
                ApplyCustEntries.LookupMode(true);
                if ApplyCustEntries.RunModal = ACTION::LookupOK then begin
                    ApplyCustEntries.GetCustLedgEntry(CustLedgEntry);
                    GenJnlApply.CheckAgainstApplnCurrency(
                      "Currency Code", CustLedgEntry."Currency Code", GenJnlLine."Account Type"::Customer, true);
                    "Applies-to Doc. Type" := CustLedgEntry."Document Type";
                    "Applies-to Doc. No." := CustLedgEntry."Document No.";
                    OnAfterAppliesToDocNoOnLookup(Rec, CustLedgEntry);
                end;
                Clear(ApplyCustEntries);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAppliesToDocNo(Rec, CustLedgEntry, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Applies-to Doc. No." <> '' then
                    TestField("Bal. Account No.", '');

                if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (xRec."Applies-to Doc. No." <> '') and
                   ("Applies-to Doc. No." <> '')
                then begin
                    CustLedgEntry.SetAmountToApply("Applies-to Doc. No.", "Bill-to Customer No.");
                    CustLedgEntry.SetAmountToApply(xRec."Applies-to Doc. No.", "Bill-to Customer No.");
                end else
                    if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (xRec."Applies-to Doc. No." = '') then
                        CustLedgEntry.SetAmountToApply("Applies-to Doc. No.", "Bill-to Customer No.")
                    else
                        if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and ("Applies-to Doc. No." = '') then
                            CustLedgEntry.SetAmountToApply(xRec."Applies-to Doc. No.", "Bill-to Customer No.");
            end;
        }
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account";

            trigger OnValidate()
            begin
                if "Bal. Account No." <> '' then
                    case "Bal. Account Type" of
                        "Bal. Account Type"::"G/L Account":
                            begin
                                GLAcc.Get("Bal. Account No.");
                                GLAcc.CheckGLAcc;
                                GLAcc.TestField("Direct Posting", true);
                            end;
                        "Bal. Account Type"::"Bank Account":
                            begin
                                BankAcc.Get("Bal. Account No.");
                                BankAcc.TestField(Blocked, false);
                                BankAcc.TestField("Currency Code", "Currency Code");
                            end;
                    end;
            end;
        }
        field(56; "Recalculate Invoice Disc."; Boolean)
        {
            CalcFormula = Exist("Sales Line" WHERE("Document Type" = FIELD("Document Type"),
                                                    "Document No." = FIELD("No."),
                                                    "Recalculate Invoice Disc." = CONST(true)));
            Caption = 'Recalculate Invoice Disc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; Ship; Boolean)
        {
            Caption = 'Ship';
            Editable = false;
        }
        field(58; Invoice; Boolean)
        {
            Caption = 'Invoice';
        }
        field(59; "Print Posted Documents"; Boolean)
        {
            Caption = 'Print Posted Documents';
        }
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Line".Amount WHERE("Document Type" = FIELD("Document Type"),
                                                         "Document No." = FIELD("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Line"."Amount Including VAT" WHERE("Document Type" = FIELD("Document Type"),
                                                                         "Document No." = FIELD("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Shipping No."; Code[20])
        {
            Caption = 'Shipping No.';
        }
        field(63; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
        }
        field(64; "Last Shipping No."; Code[20])
        {
            Caption = 'Last Shipping No.';
            Editable = false;
            TableRelation = "Sales Shipment Header";
        }
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            Editable = false;
            TableRelation = "Sales Invoice Header";
        }
        field(66; "Prepayment No."; Code[20])
        {
            Caption = 'Prepayment No.';
        }
        field(67; "Last Prepayment No."; Code[20])
        {
            Caption = 'Last Prepayment No.';
            TableRelation = "Sales Invoice Header";
        }
        field(68; "Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No.';
        }
        field(69; "Last Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Last Prepmt. Cr. Memo No.';
            TableRelation = "Sales Cr.Memo Header";
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            var
                Customer: Record Customer;
                VATRegistrationLog: Record "VAT Registration Log";
                VATRegistrationNoFormat: Record "VAT Registration No. Format";
                VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
                VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                ResultRecRef: RecordRef;
                ApplicableCountryCode: Code[10];
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVATRegistrationNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                "VAT Registration No." := UpperCase("VAT Registration No.");
                if "VAT Registration No." = xRec."VAT Registration No." then
                    exit;

                GLSetup.GetRecordOnce;
                case GLSetup."Bill-to/Sell-to VAT Calc." of
                    GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.":
                        if not Customer.Get("Bill-to Customer No.") then
                            exit;
                    GLSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.":
                        if not Customer.Get("Sell-to Customer No.") then
                            exit;
                end;

                if "VAT Registration No." = Customer."VAT Registration No." then
                    exit;

                if not VATRegistrationNoFormat.Test("VAT Registration No.", Customer."Country/Region Code", Customer."No.", DATABASE::Customer) then
                    exit;

                Customer."VAT Registration No." := "VAT Registration No.";
                ApplicableCountryCode := Customer."Country/Region Code";
                if ApplicableCountryCode = '' then
                    ApplicableCountryCode := VATRegistrationNoFormat."Country/Region Code";

                if not VATRegNoSrvConfig.VATRegNoSrvIsEnabled then begin
                    Customer.Modify(true);
                    exit;
                end;

                VATRegistrationLogMgt.CheckVIESForVATNo(
                    ResultRecRef, VATRegistrationLog, Customer, Customer."No.",
                    ApplicableCountryCode, VATRegistrationLog."Account Type"::Customer.AsInteger());

                if VATRegistrationLog.Status = VATRegistrationLog.Status::Valid then begin
                    Message(ValidVATNoMsg);
                    Customer.Modify(true);
                end else
                    Message(InvalidVatRegNoMsg);
            end;
        }
        field(71; "Combine Shipments"; Boolean)
        {
            Caption = 'Combine Shipments';
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

            trigger OnValidate()
            begin
                TestStatusOpen;
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then begin
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        "VAT Bus. Posting Group" := GenBusPostingGrp."Def. VAT Bus. Posting Group";
                    RecreateSalesLines(FieldCaption("Gen. Bus. Posting Group"));
                end;
            end;
        }
        field(75; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
        }
        field(76; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";

            trigger OnValidate()
            begin
                UpdateSalesLinesByFieldNo(FieldNo("Transaction Type"), false);
            end;
        }
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";

            trigger OnValidate()
            begin
                UpdateSalesLinesByFieldNo(FieldNo("Transport Method"), false);
            end;
        }
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(79; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                CustomerName: Text;
            begin
                CustomerName := "Sell-to Customer Name";
                LookupSellToCustomerName(CustomerName);
                "Sell-to Customer Name" := CopyStr(CustomerName, 1, MaxStrLen("Sell-to Customer Name"));
            end;

            trigger OnValidate()
            var
                Customer: Record Customer;
                EnvInfoProxy: Codeunit "Env. Info Proxy";
                LookupStateManager: Codeunit "Lookup State Manager";
                StandardCodesMgt: Codeunit "Standard Codes Mgt.";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSellToCustomerName(Rec, Customer, IsHandled);
                if IsHandled then begin
                    if LookupStateManager.IsRecordSaved() then
                        LookupStateManager.ClearSavedRecord();
                    exit;
                end;

                if LookupStateManager.IsRecordSaved() then begin
                    Customer := LookupStateManager.GetSavedRecord();
                    if Customer."No." <> '' then begin
                        LookupStateManager.ClearSavedRecord();
                        Validate("Sell-to Customer No.", Customer."No.");

                        GetShippingTime(FieldNo("Sell-to Customer Name"));
                        if "No." <> '' then
                            StandardCodesMgt.CheckCreateSalesRecurringLines(Rec);
                        exit;
                    end;
                end;

                if not EnvInfoProxy.IsInvoicing and ShouldSearchForCustomerByName("Sell-to Customer No.") then
                    Validate("Sell-to Customer No.", Customer.GetCustNo("Sell-to Customer Name"));

                GetShippingTime(FieldNo("Sell-to Customer Name"));
            end;
        }
        field(80; "Sell-to Customer Name 2"; Text[50])
        {
            Caption = 'Sell-to Customer Name 2';
        }
        field(81; "Sell-to Address"; Text[100])
        {
            Caption = 'Sell-to Address';

            trigger OnValidate()
            begin
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to Address"));
                ModifyCustomerAddress;
            end;
        }
        field(82; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';

            trigger OnValidate()
            begin
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to Address 2"));
                ModifyCustomerAddress;
            end;
        }
        field(83; "Sell-to City"; Text[30])
        {
            Caption = 'Sell-to City';
            TableRelation = IF ("Sell-to Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Sell-to Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Sell-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to City"));
                ModifyCustomerAddress;
            end;
        }
        field(84; "Sell-to Contact"; Text[100])
        {
            Caption = 'Sell-to Contact';

            trigger OnLookup()
            var
                Contact: Record Contact;
            begin
                if "Document Type" <> "Document Type"::Quote then
                    if "Sell-to Customer No." = '' then
                        exit;

                Contact.FilterGroup(2);
                LookupContact("Sell-to Customer No.", "Sell-to Contact No.", Contact);
                if PAGE.RunModal(0, Contact) = ACTION::LookupOK then
                    Validate("Sell-to Contact No.", Contact."No.");
                Contact.FilterGroup(0);
            end;

            trigger OnValidate()
            begin
                ModifyCustomerAddress;
            end;
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupBillToPostCode(Rec, PostCode);

                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                OnBeforeValidateBillToPostCode(Rec, PostCode);

                PostCode.ValidatePostCode(
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                ModifyBillToCustomerAddress;
            end;
        }
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress;
            end;
        }
        field(88; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            TableRelation = IF ("Sell-to Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Sell-to Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Sell-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupSellToPostCode(Rec, PostCode);

                PostCode.LookupPostCode("Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                OnBeforeValidateSellToPostCode(Rec, PostCode);

                PostCode.ValidatePostCode(
                  "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to Post Code"));
                ModifyCustomerAddress;
            end;
        }
        field(89; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';

            trigger OnValidate()
            begin
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to County"));
                ModifyCustomerAddress;
            end;
        }
        field(90; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to Country/Region Code"));
                ModifyCustomerAddress;
                Validate("Ship-to Country/Region Code");
            end;
        }
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            TableRelation = IF ("Ship-to Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Ship-to Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Ship-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupShipToPostCode(Rec, PostCode);

                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");

                OnAfterLookupShipToPostCode(Rec, PostCode);
            end;

            trigger OnValidate()
            begin
                OnBeforeValidateShipToPostCode(Rec, PostCode);

                PostCode.ValidatePostCode(
                  "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
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

            trigger OnValidate()
            begin
                UpdateSalesLinesByFieldNo(FieldNo("Exit Point"), false);
            end;
        }
        field(98; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDocumentDate(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if xRec."Document Date" <> "Document Date" then
                    UpdateDocumentDate := true;
                Validate("Payment Terms Code");
                Validate("Prepmt. Payment Terms Code");

                if UpdateDocumentDate and ("Document Type" = "Document Type"::Quote) and ("Document Date" <> 0D) then
                    CalcQuoteValidUntilDate;
            end;
        }
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';

            trigger OnValidate()
            var
                WhseSalesRelease: Codeunit "Whse.-Sales Release";
            begin
                if (xRec."External Document No." <> "External Document No.") and (Status = Status::Released) and
                   ("Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"])
                then
                    WhseSalesRelease.UpdateExternalDocNoForReleasedOrder(Rec);
            end;
        }
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;

            trigger OnValidate()
            begin
                UpdateSalesLinesByFieldNo(FieldNo(Area), false);
            end;
        }
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";

            trigger OnValidate()
            begin
                UpdateSalesLinesByFieldNo(FieldNo("Transaction Specification"), false);
            end;
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            var
                SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
            begin
                PaymentMethod.Init();
                if "Payment Method Code" <> '' then
                    PaymentMethod.Get("Payment Method Code");
                if PaymentMethod."Direct Debit" then begin
                    "Direct Debit Mandate ID" := SEPADirectDebitMandate.GetDefaultMandate("Bill-to Customer No.", "Due Date");
                    if "Payment Terms Code" = '' then
                        "Payment Terms Code" := PaymentMethod."Direct Debit Pmt. Terms Code";
                end else
                    "Direct Debit Mandate ID" := '';
                "Bal. Account Type" := PaymentMethod."Bal. Account Type";
                "Bal. Account No." := PaymentMethod."Bal. Account No.";
                if "Bal. Account No." <> '' then begin
                    TestField("Applies-to Doc. No.", '');
                    TestField("Applies-to ID", '');
                    Clear("Payment Service Set ID");
                end;
            end;
        }
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShippingAgentCode(Rec, IsHandled, xRec, CurrFieldNo);
                if IsHandled then
                    exit;

                TestStatusOpen;
                if xRec."Shipping Agent Code" = "Shipping Agent Code" then
                    exit;

                "Shipping Agent Service Code" := '';
                GetShippingTime(FieldNo("Shipping Agent Code"));

                OnValidateShippingAgentCodeOnBeforeUpdateLines(Rec, CurrFieldNo, HideValidationDialog);
                UpdateSalesLinesByFieldNo(FieldNo("Shipping Agent Code"), CurrFieldNo <> 0);
            end;
        }
        field(106; "Package Tracking No."; Text[30])
        {
            Caption = 'Package Tracking No.';
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(108; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                with SalesHeader do begin
                    SalesHeader := Rec;
                    GetSalesSetup;
                    TestNoSeries;
                    if NoSeriesMgt.LookupSeries(GetPostingNoSeriesCode, "Posting No. Series") then
                        Validate("Posting No. Series");
                    Rec := SalesHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Posting No. Series" <> '' then begin
                    GetSalesSetup;
                    TestNoSeries;
                    NoSeriesMgt.TestSeries(GetPostingNoSeriesCode, "Posting No. Series");
                end;
                TestField("Posting No.", '');
            end;
        }
        field(109; "Shipping No. Series"; Code[20])
        {
            Caption = 'Shipping No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupShippingNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                with SalesHeader do begin
                    SalesHeader := Rec;
                    GetSalesSetup;
                    SalesSetup.TestField("Posted Shipment Nos.");
                    if NoSeriesMgt.LookupSeries(SalesSetup."Posted Shipment Nos.", "Shipping No. Series") then
                        Validate("Shipping No. Series");
                    Rec := SalesHeader;
                end;
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShippingNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Shipping No. Series" <> '' then begin
                    GetSalesSetup;
                    SalesSetup.TestField("Posted Shipment Nos.");
                    NoSeriesMgt.TestSeries(SalesSetup."Posted Shipment Nos.", "Shipping No. Series");
                end;
                TestField("Shipping No.", '');
            end;
        }
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                TestStatusOpen;
                ValidateTaxAreaCode;
                MessageIfSalesLinesExist(FieldCaption("Tax Area Code"));
            end;
        }
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                TestStatusOpen;
                MessageIfSalesLinesExist(FieldCaption("Tax Liable"));
            end;
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen;
                if xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group" then
                    RecreateSalesLines(FieldCaption("VAT Bus. Posting Group"));
            end;
        }
        field(117; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Reserve';
            InitValue = Optional;
        }
        field(118; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            var
                TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
                CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
            begin
                if "Applies-to ID" <> '' then
                    TestField("Bal. Account No.", '');
                if ("Applies-to ID" <> xRec."Applies-to ID") and (xRec."Applies-to ID" <> '') then begin
                    CustLedgEntry.SetCurrentKey("Customer No.", Open);
                    CustLedgEntry.SetRange("Customer No.", "Bill-to Customer No.");
                    CustLedgEntry.SetRange(Open, true);
                    CustLedgEntry.SetRange("Applies-to ID", xRec."Applies-to ID");
                    if CustLedgEntry.FindFirst then
                        CustEntrySetApplID.SetApplId(CustLedgEntry, TempCustLedgEntry, '');
                    CustLedgEntry.Reset();
                end;
            end;
        }
        field(119; "VAT Base Discount %"; Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date"), FieldNo("Document Date")]) then
                    TestStatusOpen;
                GLSetup.Get();
                if "VAT Base Discount %" > GLSetup."VAT Tolerance %" then
                    Error(
                      Text007,
                      FieldCaption("VAT Base Discount %"),
                      GLSetup.FieldCaption("VAT Tolerance %"),
                      GLSetup.TableCaption);

                if ("VAT Base Discount %" = xRec."VAT Base Discount %") and (CurrFieldNo <> 0) then
                    exit;

                UpdateSalesLineAmounts;
            end;
        }
        field(120; Status; Enum "Sales Document Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(121; "Invoice Discount Calculation"; Option)
        {
            Caption = 'Invoice Discount Calculation';
            Editable = false;
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        field(122; "Invoice Discount Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Invoice Discount Value';
            Editable = false;
        }
        field(123; "Send IC Document"; Boolean)
        {
            Caption = 'Send IC Document';

            trigger OnValidate()
            begin
                if "Send IC Document" then begin
                    if "Bill-to IC Partner Code" = '' then
                        TestField("Sell-to IC Partner Code");
                    TestField("IC Direction", "IC Direction"::Outgoing);
                end;
            end;
        }
        field(124; "IC Status"; Enum "Sales Document IC Status")
        {
            Caption = 'IC Status';
        }
        field(125; "Sell-to IC Partner Code"; Code[20])
        {
            Caption = 'Sell-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(126; "Bill-to IC Partner Code"; Code[20])
        {
            Caption = 'Bill-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(129; "IC Direction"; Option)
        {
            Caption = 'IC Direction';
            OptionCaption = 'Outgoing,Incoming';
            OptionMembers = Outgoing,Incoming;

            trigger OnValidate()
            begin
                if "IC Direction" = "IC Direction"::Incoming then
                    "Send IC Document" := false;
            end;
        }
        field(130; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if xRec."Prepayment %" <> "Prepayment %" then
                    UpdateSalesLinesByFieldNo(FieldNo("Prepayment %"), CurrFieldNo <> 0);
            end;
        }
        field(131; "Prepayment No. Series"; Code[20])
        {
            Caption = 'Prepayment No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                with SalesHeader do begin
                    SalesHeader := Rec;
                    GetSalesSetup;
                    SalesSetup.TestField("Posted Prepmt. Inv. Nos.");
                    if NoSeriesMgt.LookupSeries(GetPostingPrepaymentNoSeriesCode, "Prepayment No. Series") then
                        Validate("Prepayment No. Series");
                    Rec := SalesHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Prepayment No. Series" <> '' then begin
                    GetSalesSetup;
                    SalesSetup.TestField("Posted Prepmt. Inv. Nos.");
                    NoSeriesMgt.TestSeries(GetPostingPrepaymentNoSeriesCode, "Prepayment No. Series");
                end;
                TestField("Prepayment No.", '');
            end;
        }
        field(132; "Compress Prepayment"; Boolean)
        {
            Caption = 'Compress Prepayment';
            InitValue = true;
        }
        field(133; "Prepayment Due Date"; Date)
        {
            Caption = 'Prepayment Due Date';
        }
        field(134; "Prepmt. Cr. Memo No. Series"; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                with SalesHeader do begin
                    SalesHeader := Rec;
                    GetSalesSetup;
                    SalesSetup.TestField("Posted Prepmt. Cr. Memo Nos.");
                    if NoSeriesMgt.LookupSeries(GetPostingPrepaymentNoSeriesCode, "Prepmt. Cr. Memo No. Series") then
                        Validate("Prepmt. Cr. Memo No. Series");
                    Rec := SalesHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Prepmt. Cr. Memo No." <> '' then begin
                    GetSalesSetup;
                    SalesSetup.TestField("Posted Prepmt. Cr. Memo Nos.");
                    NoSeriesMgt.TestSeries(GetPostingPrepaymentNoSeriesCode, "Prepmt. Cr. Memo No. Series");
                end;
                TestField("Prepmt. Cr. Memo No.", '');
            end;
        }
        field(135; "Prepmt. Posting Description"; Text[100])
        {
            Caption = 'Prepmt. Posting Description';
        }
        field(138; "Prepmt. Pmt. Discount Date"; Date)
        {
            Caption = 'Prepmt. Pmt. Discount Date';
        }
        field(139; "Prepmt. Payment Terms Code"; Code[10])
        {
            Caption = 'Prepmt. Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            var
                PaymentTerms: Record "Payment Terms";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePrepmtPaymentTermsCode(Rec, xRec, FieldNo("Prepmt. Payment Terms Code"), CurrFieldNo, UpdateDocumentDate, IsHandled);
                if IsHandled then
                    exit;

                if ("Prepmt. Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                    PaymentTerms.Get("Prepmt. Payment Terms Code");
                    if IsCreditDocType and not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
                        IsHandled := false;
                        OnValidatePrepmtPaymentTermsCodeOnCaseIfOnBeforeValidatePrepaymentDueDate(Rec, xRec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            Validate("Prepayment Due Date", "Document Date");
                        Validate("Prepmt. Pmt. Discount Date", 0D);
                        Validate("Prepmt. Payment Discount %", 0);
                    end else begin
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalcDueDate(Rec, xRec, FieldNo("Prepmt. Payment Terms Code"), CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Prepayment Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalcPmtDiscDate(Rec, xRec, FieldNo("Prepmt. Payment Terms Code"), CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Prepmt. Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                        if not UpdateDocumentDate then
                            Validate("Prepmt. Payment Discount %", PaymentTerms."Discount %")
                    end;
                end else begin
                    IsHandled := false;
                    OnPrepmtPaymentTermsCodeOnCaseElseOnBeforeValidatePrepaymentDueDate(Rec, xRec, CurrFieldNo, IsHandled);
                    if not IsHandled then
                        Validate("Prepayment Due Date", "Document Date");
                    if not UpdateDocumentDate then begin
                        Validate("Prepmt. Pmt. Discount Date", 0D);
                        Validate("Prepmt. Payment Discount %", 0);
                    end;
                end;
            end;
        }
        field(140; "Prepmt. Payment Discount %"; Decimal)
        {
            Caption = 'Prepmt. Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date"), FieldNo("Document Date")]) then
                    TestStatusOpen;
                GLSetup.Get();
                if "Payment Discount %" < GLSetup."VAT Tolerance %" then
                    "VAT Base Discount %" := "Payment Discount %"
                else
                    "VAT Base Discount %" := GLSetup."VAT Tolerance %";
                Validate("VAT Base Discount %");
            end;
        }
        field(151; "Quote No."; Code[20])
        {
            Caption = 'Quote No.';
            Editable = false;
        }
        field(152; "Quote Valid Until Date"; Date)
        {
            Caption = 'Quote Valid To Date';
        }
        field(153; "Quote Sent to Customer"; DateTime)
        {
            Caption = 'Quote Sent to Customer';
            Editable = false;
        }
        field(154; "Quote Accepted"; Boolean)
        {
            Caption = 'Quote Accepted';

            trigger OnValidate()
            begin
                if "Quote Accepted" then begin
                    "Quote Accepted Date" := WorkDate;
                    OnAfterSalesQuoteAccepted(Rec);
                end else
                    "Quote Accepted Date" := 0D;
            end;
        }
        field(155; "Quote Accepted Date"; Date)
        {
            Caption = 'Quote Accepted Date';
            Editable = false;
        }
        field(160; "Job Queue Status"; Option)
        {
            Caption = 'Job Queue Status';
            Editable = false;
            OptionCaption = ' ,Scheduled for Posting,Error,Posting';
            OptionMembers = " ","Scheduled for Posting",Error,Posting;

            trigger OnLookup()
            var
                JobQueueEntry: Record "Job Queue Entry";
            begin
                if "Job Queue Status" = "Job Queue Status"::" " then
                    exit;
                JobQueueEntry.ShowStatusMsg("Job Queue Entry ID");
            end;
        }
        field(161; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            Editable = false;
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";

            trigger OnValidate()
            var
                IncomingDocument: Record "Incoming Document";
            begin
                if "Incoming Document Entry No." = xRec."Incoming Document Entry No." then
                    exit;
                if "Incoming Document Entry No." = 0 then
                    IncomingDocument.RemoveReferenceToWorkingDocument(xRec."Incoming Document Entry No.")
                else
                    IncomingDocument.SetSalesDoc(Rec);
            end;
        }
        field(166; "Last Email Sent Time"; DateTime)
        {
            CalcFormula = Max("O365 Document Sent History"."Created Date-Time" WHERE("Document Type" = FIELD("Document Type"),
                                                                                      "Document No." = FIELD("No."),
                                                                                      Posted = CONST(false)));
            Caption = 'Last Email Sent Time';
            FieldClass = FlowField;
        }
        field(167; "Last Email Sent Status"; Option)
        {
            CalcFormula = Lookup("O365 Document Sent History"."Job Last Status" WHERE("Document Type" = FIELD("Document Type"),
                                                                                       "Document No." = FIELD("No."),
                                                                                       Posted = CONST(false),
                                                                                       "Created Date-Time" = FIELD("Last Email Sent Time")));
            Caption = 'Last Email Sent Status';
            FieldClass = FlowField;
            OptionCaption = 'Not Sent,In Process,Finished,Error';
            OptionMembers = "Not Sent","In Process",Finished,Error;
        }
        field(168; "Sent as Email"; Boolean)
        {
            CalcFormula = Exist("O365 Document Sent History" WHERE("Document Type" = FIELD("Document Type"),
                                                                    "Document No." = FIELD("No."),
                                                                    Posted = CONST(false),
                                                                    "Job Last Status" = CONST(Finished)));
            Caption = 'Sent as Email';
            FieldClass = FlowField;
        }
        field(169; "Last Email Notif Cleared"; Boolean)
        {
            CalcFormula = Lookup("O365 Document Sent History".NotificationCleared WHERE("Document Type" = FIELD("Document Type"),
                                                                                         "Document No." = FIELD("No."),
                                                                                         Posted = CONST(false),
                                                                                         "Created Date-Time" = FIELD("Last Email Sent Time")));
            Caption = 'Last Email Notif Cleared';
            FieldClass = FlowField;
        }
        field(170; IsTest; Boolean)
        {
            Caption = 'IsTest';
            Editable = false;
        }
        field(171; "Sell-to Phone No."; Text[30])
        {
            Caption = 'Sell-to Phone No.';
            ExtendedDatatype = PhoneNo;

            trigger OnValidate()
            var
                Char: DotNet Char;
                i: Integer;
            begin
                for i := 1 to StrLen("Sell-to Phone No.") do
                    if Char.IsLetter("Sell-to Phone No."[i]) then
                        Error(PhoneNoCannotContainLettersErr);
            end;
        }
        field(172; "Sell-to E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "Sell-to E-Mail" = '' then
                    exit;
                MailManagement.CheckValidEmailAddresses("Sell-to E-Mail");
            end;
        }
        field(175; "Payment Instructions Id"; Integer)
        {
            Caption = 'Payment Instructions Id';
            TableRelation = "O365 Payment Instructions";
            ObsoleteState = Pending;
            ObsoleteReason = 'Microsoft Invoicing is not supported in Business Central';
            ObsoleteTag = '18.0';
        }
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
        }
        field(300; "Amt. Ship. Not Inv. (LCY)"; Decimal)
        {
            CalcFormula = Sum("Sales Line"."Shipped Not Invoiced (LCY)" WHERE("Document Type" = FIELD("Document Type"),
                                                                               "Document No." = FIELD("No.")));
            Caption = 'Amount Shipped Not Invoiced (LCY) Incl. VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(301; "Amt. Ship. Not Inv. (LCY) Base"; Decimal)
        {
            CalcFormula = Sum("Sales Line"."Shipped Not Inv. (LCY) No VAT" WHERE("Document Type" = FIELD("Document Type"),
                                                                                  "Document No." = FIELD("No.")));
            Caption = 'Amount Shipped Not Invoiced (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDocDim;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(600; "Payment Service Set ID"; Integer)
        {
            Caption = 'Payment Service Set ID';
        }
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" WHERE("Customer No." = FIELD("Bill-to Customer No."),
                                                               Closed = CONST(false),
                                                               Blocked = CONST(false));
        }
        field(1305; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Sales Line"."Inv. Discount Amount" WHERE("Document No." = FIELD("No."),
                                                                         "Document Type" = FIELD("Document Type")));
            Caption = 'Invoice Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5043; "No. of Archived Versions"; Integer)
        {
            CalcFormula = Max("Sales Header Archive"."Version No." WHERE("Document Type" = FIELD("Document Type"),
                                                                          "No." = FIELD("No."),
                                                                          "Doc. No. Occurrence" = FIELD("Doc. No. Occurrence")));
            Caption = 'No. of Archived Versions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
#if not CLEAN18
            var
                CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
#endif
            begin
#if not CLEAN18
                if not CustomerTemplMgt.IsEnabled() then
                    CreateDim(
                      DATABASE::Campaign, "Campaign No.",
                      DATABASE::Customer, "Bill-to Customer No.",
                      DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                      DATABASE::"Responsibility Center", "Responsibility Center",
                      DATABASE::"Customer Template", "Bill-to Customer Template Code")
                else
#endif
                    CreateDim(
                      DATABASE::Campaign, "Campaign No.",
                      DATABASE::Customer, "Bill-to Customer No.",
                      DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                      DATABASE::"Responsibility Center", "Responsibility Center",
                      DATABASE::"Customer Templ.", "Bill-to Customer Templ. Code")
            end;
        }
        field(5051; "Sell-to Customer Template Code"; Code[10])
        {
            Caption = 'Sell-to Customer Template Code';
#if not CLEAN18
            TableRelation = "Customer Template";
#endif
            ObsoleteReason = 'Will be removed with other functionality related to "old" templates. Replaced by "Sell-to Customer Templ. Code".';
#if not CLEAN18
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#endif

#if not CLEAN18
            trigger OnValidate()
            var
                SellToCustTemplate: Record "Customer Template";
            begin
                TestField("Document Type", "Document Type"::Quote);
                TestStatusOpen;

                if not InsertMode and
                   ("Sell-to Customer Template Code" <> xRec."Sell-to Customer Template Code") and
                   (xRec."Sell-to Customer Template Code" <> '')
                then begin
                    if GetHideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Sell-to Customer Template Code"));
                    if Confirmed then begin
                        if InitFromTemplate("Sell-to Customer Template Code", FieldCaption("Sell-to Customer Template Code")) then
                            exit
                    end else begin
                        "Sell-to Customer Template Code" := xRec."Sell-to Customer Template Code";
                        exit;
                    end;
                end;

                if SellToCustTemplate.Get("Sell-to Customer Template Code") then
                    CopyFromSellToCustTemplate(SellToCustTemplate);

                if not InsertMode and
                   ((xRec."Sell-to Customer Template Code" <> "Sell-to Customer Template Code") or
                    (xRec."Currency Code" <> "Currency Code"))
                then
                    RecreateSalesLines(FieldCaption("Sell-to Customer Template Code"));
            end;
#endif
        }
        field(5052; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupSellToContactNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Sell-to Customer No." <> '' then
                    if Cont.Get("Sell-to Contact No.") then
                        Cont.SetRange("Company No.", Cont."Company No.")
                    else
                        if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Sell-to Customer No.") then
                            Cont.SetRange("Company No.", ContBusinessRelation."Contact No.")
                        else
                            Cont.SetRange("No.", '');

                if "Sell-to Contact No." <> '' then
                    if Cont.Get("Sell-to Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    xRec := Rec;
                    Validate("Sell-to Contact No.", Cont."No.");
                end;
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                Opportunity: Record Opportunity;
                IsHandled: Boolean;
            begin
                TestStatusOpen;

                if "Sell-to Contact No." <> '' then
                    if Cont.Get("Sell-to Contact No.") then
                        Cont.CheckIfPrivacyBlockedGeneric;

                if ("Sell-to Contact No." <> xRec."Sell-to Contact No.") and
                   (xRec."Sell-to Contact No." <> '')
                then begin
                    if ("Sell-to Contact No." = '') and ("Opportunity No." <> '') then
                        Error(Text049, FieldCaption("Sell-to Contact No."));
                    IsHandled := false;
                    OnBeforeConfirmSellToContactNoChange(Rec, xRec, CurrFieldNo, Confirmed, IsHandled);
                    if not IsHandled then
                        if GetHideValidationDialog or not GuiAllowed then
                            Confirmed := true
                        else
                            Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Sell-to Contact No."));
                    if Confirmed then begin
                        if InitFromContact("Sell-to Contact No.", "Sell-to Customer No.", FieldCaption("Sell-to Contact No.")) then
                            exit;
                        if "Opportunity No." <> '' then begin
                            Opportunity.Get("Opportunity No.");
                            if Opportunity."Contact No." <> "Sell-to Contact No." then begin
                                Modify;
                                Opportunity.Validate("Contact No.", "Sell-to Contact No.");
                                Opportunity.Modify();
                            end
                        end;
                    end else begin
                        Rec := xRec;
                        exit;
                    end;
                end;

                if ("Sell-to Customer No." <> '') and ("Sell-to Contact No." <> '') then
                    CheckContactRelatedToCustomerCompany("Sell-to Contact No.", "Sell-to Customer No.", CurrFieldNo);

                if "Sell-to Contact No." <> '' then
                    if Cont.Get("Sell-to Contact No.") then
                        if ("Salesperson Code" = '') and (Cont."Salesperson Code" <> '') then
                            Validate("Salesperson Code", Cont."Salesperson Code");

                UpdateSellToCust("Sell-to Contact No.");
                UpdateSellToCustTemplateCode;
                UpdateShipToContact;
            end;
        }
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupBillToContactNo(IsHandled);
                if IsHandled then
                    exit;

                if "Bill-to Customer No." <> '' then
                    if Cont.Get("Bill-to Contact No.") then
                        Cont.SetRange("Company No.", Cont."Company No.")
                    else
                        if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Bill-to Customer No.") then
                            Cont.SetRange("Company No.", ContBusinessRelation."Contact No.")
                        else
                            Cont.SetRange("No.", '');

                if "Bill-to Contact No." <> '' then
                    if Cont.Get("Bill-to Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    xRec := Rec;
                    Validate("Bill-to Contact No.", Cont."No.");
                end;
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                IsHandled: Boolean;
            begin
                TestStatusOpen;

                if "Bill-to Contact No." <> '' then
                    if Cont.Get("Bill-to Contact No.") then
                        Cont.CheckIfPrivacyBlockedGeneric;

                if ("Bill-to Contact No." <> xRec."Bill-to Contact No.") and
                   (xRec."Bill-to Contact No." <> '')
                then begin
                    IsHandled := false;
                    OnBeforeConfirmBillToContactNoChange(Rec, xRec, CurrFieldNo, Confirmed, IsHandled);
                    if not IsHandled then
                        if GetHideValidationDialog or (not GuiAllowed) then
                            Confirmed := true
                        else
                            Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Bill-to Contact No."));
                    if Confirmed then begin
                        if InitFromContact("Bill-to Contact No.", "Bill-to Customer No.", FieldCaption("Bill-to Contact No.")) then
                            exit;
                    end else begin
                        "Bill-to Contact No." := xRec."Bill-to Contact No.";
                        exit;
                    end;
                end;

                if ("Bill-to Customer No." <> '') and ("Bill-to Contact No." <> '') then
                    CheckContactRelatedToCustomerCompany("Bill-to Contact No.", "Bill-to Customer No.", CurrFieldNo);

                UpdateBillToCust("Bill-to Contact No.");
            end;
        }
        field(5054; "Bill-to Customer Template Code"; Code[10])
        {
            Caption = 'Bill-to Customer Template Code';
#if not CLEAN18
            TableRelation = "Customer Template";
#endif
            ObsoleteReason = 'Will be removed with other functionality related to "old" templates. Replaced by "Bill-to Customer Templ. Code".';
#if not CLEAN18
            ObsoleteState = Pending;
            ObsoleteTag = '18.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '21.0';
#endif

#if not CLEAN18
            trigger OnValidate()
            var
                BillToCustTemplate: Record "Customer Template";
            begin
                TestField("Document Type", "Document Type"::Quote);
                TestStatusOpen;

                if not InsertMode and
                   ("Bill-to Customer Template Code" <> xRec."Bill-to Customer Template Code") and
                   (xRec."Bill-to Customer Template Code" <> '')
                then begin
                    if GetHideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Bill-to Customer Template Code"));
                    if Confirmed then begin
                        if InitFromTemplate("Bill-to Customer Template Code", FieldCaption("Bill-to Customer Template Code")) then
                            exit
                    end else begin
                        "Bill-to Customer Template Code" := xRec."Bill-to Customer Template Code";
                        exit;
                    end;
                end;

                Validate("Ship-to Code", '');
                if BillToCustTemplate.Get("Bill-to Customer Template Code") then begin
                    BillToCustTemplate.TestField("Customer Posting Group");
                    "Customer Posting Group" := BillToCustTemplate."Customer Posting Group";
                    "Invoice Disc. Code" := BillToCustTemplate."Invoice Disc. Code";
                    "Customer Price Group" := BillToCustTemplate."Customer Price Group";
                    "Customer Disc. Group" := BillToCustTemplate."Customer Disc. Group";
                    "Allow Line Disc." := BillToCustTemplate."Allow Line Disc.";
                    Validate("Payment Terms Code", BillToCustTemplate."Payment Terms Code");
                    Validate("Payment Method Code", BillToCustTemplate."Payment Method Code");
                    "Prices Including VAT" := BillToCustTemplate."Prices Including VAT";
                    "Shipment Method Code" := BillToCustTemplate."Shipment Method Code";
                end;

                CreateDim(
                  DATABASE::"Customer Template", "Bill-to Customer Template Code",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center");

                OnValidateBilltoCustomerTemplateCodeBeforeRecreateSalesLines(Rec, CurrFieldNo);

                if not InsertMode and
                   (xRec."Sell-to Customer Template Code" = "Sell-to Customer Template Code") and
                   (xRec."Bill-to Customer Template Code" <> "Bill-to Customer Template Code")
                then
                    RecreateSalesLines(FieldCaption("Bill-to Customer Template Code"));
            end;
#endif
        }
        field(5055; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = IF ("Document Type" = FILTER(<> Order)) Opportunity."No." WHERE("Contact No." = FIELD("Sell-to Contact No."),
                                                                                          Closed = CONST(false))
            ELSE
            IF ("Document Type" = CONST(Order)) Opportunity."No." WHERE("Contact No." = FIELD("Sell-to Contact No."),
                                                                                                                                                          "Sales Document No." = FIELD("No."),
                                                                                                                                                          "Sales Document Type" = CONST(Order));

            trigger OnValidate()
            begin
                LinkSalesDocWithOpportunity(xRec."Opportunity No.");
            end;
        }
        field(5056; "Sell-to Customer Templ. Code"; Code[20])
        {
            Caption = 'Sell-to Customer Template Code';
            TableRelation = "Customer Templ.";

            trigger OnValidate()
            var
                SellToCustTemplate: Record "Customer Templ.";
            begin
                TestField("Document Type", "Document Type"::Quote);
                TestStatusOpen();

                if not InsertMode and
                   ("Sell-to Customer Templ. Code" <> xRec."Sell-to Customer Templ. Code") and
                   (xRec."Sell-to Customer Templ. Code" <> '')
                then begin
                    if GetHideValidationDialog() or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Sell-to Customer Templ. Code"));
                    if Confirmed then begin
                        if InitFromTemplate("Sell-to Customer Templ. Code", FieldCaption("Sell-to Customer Templ. Code")) then
                            exit
                    end else begin
                        "Sell-to Customer Templ. Code" := xRec."Sell-to Customer Templ. Code";
                        exit;
                    end;
                end;

                if SellToCustTemplate.Get("Sell-to Customer Templ. Code") then
                    CopyFromNewSellToCustTemplate(SellToCustTemplate);

                if not InsertMode and
                   ((xRec."Sell-to Customer Templ. Code" <> "Sell-to Customer Templ. Code") or
                    (xRec."Currency Code" <> "Currency Code"))
                then
                    RecreateSalesLines(CopyStr(FieldCaption("Sell-to Customer Templ. Code"), 1, 100));
            end;
        }
        field(5057; "Bill-to Customer Templ. Code"; Code[20])
        {
            Caption = 'Bill-to Customer Template Code';
            TableRelation = "Customer Templ.";

            trigger OnValidate()
            var
                BillToCustTemplate: Record "Customer Templ.";
            begin
                TestField("Document Type", "Document Type"::Quote);
                TestStatusOpen();

                if not InsertMode and
                   ("Bill-to Customer Templ. Code" <> xRec."Bill-to Customer Templ. Code") and
                   (xRec."Bill-to Customer Templ. Code" <> '')
                then begin
                    if GetHideValidationDialog() or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Bill-to Customer Templ. Code"));
                    if Confirmed then begin
                        if InitFromTemplate("Bill-to Customer Templ. Code", FieldCaption("Bill-to Customer Templ. Code")) then
                            exit
                    end else begin
                        "Bill-to Customer Templ. Code" := xRec."Bill-to Customer Templ. Code";
                        exit;
                    end;
                end;

                Validate("Ship-to Code", '');
                if BillToCustTemplate.Get("Bill-to Customer Templ. Code") then
                    InitFromBillToCustTemplate(BillToCustTemplate);

                CreateDim(
                  DATABASE::"Customer Templ.", "Bill-to Customer Templ. Code",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center");

                OnValidateBilltoCustomerTemplCodeOnBeforeRecreateSalesLines(Rec, CurrFieldNo);

                if not InsertMode and
                   (xRec."Sell-to Customer Templ. Code" = "Sell-to Customer Templ. Code") and
                   (xRec."Bill-to Customer Templ. Code" <> "Bill-to Customer Templ. Code")
                then
                    RecreateSalesLines(CopyStr(FieldCaption("Bill-to Customer Templ. Code"), 1, 100));
            end;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";

            trigger OnValidate()
#if not CLEAN18
            var
                CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
#endif
            begin
                TestStatusOpen;
                if not UserSetupMgt.CheckRespCenter(0, "Responsibility Center") then
                    Error(
                      Text027,
                      RespCenter.TableCaption, UserSetupMgt.GetSalesFilter);

                UpdateLocationCode('');
                UpdateOutboundWhseHandlingTime;
                UpdateShipToAddress;

#if not CLEAN18
                if not CustomerTemplMgt.IsEnabled() then
                    CreateDim(
                      DATABASE::"Responsibility Center", "Responsibility Center",
                      DATABASE::Customer, "Bill-to Customer No.",
                      DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                      DATABASE::Campaign, "Campaign No.",
                      DATABASE::"Customer Template", "Bill-to Customer Template Code")
                else
#endif
                    CreateDim(
                      DATABASE::"Responsibility Center", "Responsibility Center",
                      DATABASE::Customer, "Bill-to Customer No.",
                      DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                      DATABASE::Campaign, "Campaign No.",
                      DATABASE::"Customer Templ.", "Bill-to Customer Templ. Code");

                if xRec."Responsibility Center" <> "Responsibility Center" then begin
                    RecreateSalesLines(FieldCaption("Responsibility Center"));
                    "Assigned User ID" := '';
                end;
            end;
        }
        field(5750; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipping Advice';

            trigger OnValidate()
            begin
                TestStatusOpen;
                if InventoryPickConflict("Document Type", "No.", "Shipping Advice") then
                    Error(Text066, FieldCaption("Shipping Advice"), Format("Shipping Advice"), TableCaption);
                if WhseShipmentConflict("Document Type", "No.", "Shipping Advice") then
                    Error(Text070, FieldCaption("Shipping Advice"), Format("Shipping Advice"), TableCaption);
                WhseSourceHeader.SalesHeaderVerifyChange(Rec, xRec);
            end;
        }

        field(5751; "Shipped Not Invoiced"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Exist("Sales Line" WHERE("Document Type" = FIELD("Document Type"),
                                                    "Document No." = FIELD("No."),
                                                    "Qty. Shipped Not Invoiced" = FILTER(<> 0)));
            Caption = 'Shipped Not Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            CalcFormula = Min("Sales Line"."Completely Shipped" WHERE("Document Type" = FIELD("Document Type"),
                                                                       "Document No." = FIELD("No."),
                                                                       Type = FILTER(<> " "),
                                                                       "Location Code" = FIELD("Location Filter")));
            Caption = 'Completely Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5753; "Posting from Whse. Ref."; Integer)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Posting from Whse. Ref.';
        }
        field(5754; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(5755; Shipped; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Exist("Sales Line" WHERE("Document Type" = FIELD("Document Type"),
                                                    "Document No." = FIELD("No."),
                                                    "Qty. Shipped (Base)" = FILTER(<> 0)));
            Caption = 'Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5756; "Last Shipment Date"; Date)
        {
            CalcFormula = Lookup("Sales Shipment Header"."Shipment Date" WHERE("No." = FIELD("Last Shipping No.")));
            Caption = 'Last Shipment Date';
            FieldClass = FlowField;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                CheckPromisedDeliveryDate();

                if "Requested Delivery Date" <> xRec."Requested Delivery Date" then
                    UpdateSalesLinesByFieldNo(FieldNo("Requested Delivery Date"), CurrFieldNo <> 0);
            end;
        }
        field(5791; "Promised Delivery Date"; Date)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Promised Delivery Date';

            trigger OnValidate()
            begin
                TestStatusOpen;
                if "Promised Delivery Date" <> xRec."Promised Delivery Date" then
                    UpdateSalesLinesByFieldNo(FieldNo("Promised Delivery Date"), CurrFieldNo <> 0);
            end;
        }
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                TestStatusOpen;
                if "Shipping Time" <> xRec."Shipping Time" then
                    UpdateSalesLinesByFieldNo(FieldNo("Shipping Time"), CurrFieldNo <> 0);
            end;
        }
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData "Warehouse Shipment Header" = R;
            Caption = 'Outbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TestStatusOpen;
                if ("Outbound Whse. Handling Time" <> xRec."Outbound Whse. Handling Time") and
                   (xRec."Sell-to Customer No." = "Sell-to Customer No.")
                then
                    UpdateSalesLinesByFieldNo(FieldNo("Outbound Whse. Handling Time"), CurrFieldNo <> 0);
            end;
        }
        field(5794; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code WHERE("Shipping Agent Code" = FIELD("Shipping Agent Code"));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShippingAgentServiceCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen;
                GetShippingTime(FieldNo("Shipping Agent Service Code"));
                UpdateSalesLinesByFieldNo(FieldNo("Shipping Agent Service Code"), CurrFieldNo <> 0);
            end;
        }
        field(5795; "Late Order Shipping"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = Exist("Sales Line" WHERE("Document Type" = FIELD("Document Type"),
                                                    "Sell-to Customer No." = FIELD("Sell-to Customer No."),
                                                    "Document No." = FIELD("No."),
                                                    "Shipment Date" = FIELD("Date Filter"),
                                                    "Outstanding Quantity" = FILTER(<> 0)));
            Caption = 'Late Order Shipping';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5796; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5800; Receive; Boolean)
        {
            Caption = 'Receive';
        }
        field(5801; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
        }
        field(5802; "Return Receipt No. Series"; Code[20])
        {
            Caption = 'Return Receipt No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupReturnReceiptNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                with SalesHeader do begin
                    SalesHeader := Rec;
                    GetSalesSetup;
                    SalesSetup.TestField("Posted Return Receipt Nos.");
                    if NoSeriesMgt.LookupSeries(SalesSetup."Posted Return Receipt Nos.", "Return Receipt No. Series") then
                        Validate("Return Receipt No. Series");
                    Rec := SalesHeader;
                end;
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateReturnReceiptNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Return Receipt No. Series" <> '' then begin
                    GetSalesSetup;
                    SalesSetup.TestField("Posted Return Receipt Nos.");
                    NoSeriesMgt.TestSeries(SalesSetup."Posted Return Receipt Nos.", "Return Receipt No. Series");
                end;
                TestField("Return Receipt No.", '');
            end;
        }
        field(5803; "Last Return Receipt No."; Code[20])
        {
            Caption = 'Last Return Receipt No.';
            Editable = false;
            TableRelation = "Return Receipt Header";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';

            trigger OnValidate()
            begin
                TestStatusOpen;
                MessageIfSalesLinesExist(FieldCaption("Allow Line Disc."));
            end;
        }
        field(7200; "Get Shipment Used"; Boolean)
        {
            Caption = 'Get Shipment Used';
            Editable = false;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            ObsoleteState = Pending;
            ObsoleteReason = 'This functionality will be replaced by the systemID field';
            ObsoleteTag = '15.0';
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";

            trigger OnValidate()
            begin
                if not UserSetupMgt.CheckRespCenter(0, "Responsibility Center", "Assigned User ID") then
                    Error(
                      Text061, "Assigned User ID",
                      RespCenter.TableCaption, UserSetupMgt.GetSalesFilter("Assigned User ID"));
            end;
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", "Document Type")
        {
        }
        key(Key3; "Document Type", "Sell-to Customer No.")
        {
        }
        key(Key4; "Document Type", "Bill-to Customer No.")
        {
        }
        key(Key5; "Document Type", "Combine Shipments", "Bill-to Customer No.", "Currency Code", "EU 3-Party Trade", "Dimension Set ID")
        {
        }
        key(Key6; "Sell-to Customer No.", "External Document No.")
        {
        }
        key(Key7; "Document Type", "Sell-to Contact No.")
        {
        }
        key(Key8; "Bill-to Contact No.")
        {
        }
        key(Key9; "Incoming Document Entry No.")
        {
        }
        key(Key10; "Document Date")
        {
        }
        key(Key11; "Shipment Date", Status, "Location Code", "Responsibility Center")
        {
        }
        key(Key12; "Salesperson Code")
        {
        }
        key(Key13; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Sell-to Customer Name", Amount, "Sell-to Contact", "Amount Including VAT")
        {
        }
        fieldgroup(Brick; "No.", "Sell-to Customer Name", Amount, "Sell-to Contact", "Amount Including VAT")
        {
        }
    }

    trigger OnDelete()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        PostSalesDelete: Codeunit "PostSales-Delete";
        ArchiveManagement: Codeunit ArchiveManagement;
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        ShowPostedDocsToPrint: Boolean;
    begin
        if not UserSetupMgt.CheckRespCenter(0, "Responsibility Center") then
            Error(
              Text022,
              RespCenter.TableCaption, UserSetupMgt.GetSalesFilter);

        ArchiveManagement.AutoArchiveSalesDocument(Rec);
        PostSalesDelete.DeleteHeader(
          Rec, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader,
          SalesInvHeaderPrepmt, SalesCrMemoHeaderPrepmt);
        UpdateOpportunity;

        Validate("Applies-to ID", '');
        Validate("Incoming Document Entry No.", 0);

        DeleteRecordInApprovalRequest();
        SalesLine.Reset();
        SalesLine.LockTable();

        WhseRequest.SetRange("Source Type", DATABASE::"Sales Line");
        WhseRequest.SetRange("Source Subtype", "Document Type");
        WhseRequest.SetRange("Source No.", "No.");
        if not WhseRequest.IsEmpty() then
            WhseRequest.DeleteAll(true);

        DeleteAllSalesLines();

        ShowPostedDocsToPrint := (SalesShptHeader."No." <> '') or
           (SalesInvHeader."No." <> '') or
           (SalesCrMemoHeader."No." <> '') or
           (ReturnRcptHeader."No." <> '') or
           (SalesInvHeaderPrepmt."No." <> '') or
           (SalesCrMemoHeaderPrepmt."No." <> '');
        OnBeforeShowPostedDocsToPrintCreatedMsg(ShowPostedDocsToPrint);
        if ShowPostedDocsToPrint then
            Message(PostedDocsToPrintCreatedMsg);

        if EnvInfoProxy.IsInvoicing and CustInvoiceDisc.Get(SalesHeader."Invoice Disc. Code") then
            CustInvoiceDisc.Delete(); // Cleanup of autogenerated cust. invoice discounts
    end;

    trigger OnInsert()
    var
        O365SalesInvoiceMgmt: Codeunit "O365 Sales Invoice Mgmt";
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
    begin
        InitInsert;
        InsertMode := true;

        SetSellToCustomerFromFilter;

        if GetFilterContNo <> '' then
            Validate("Sell-to Contact No.", GetFilterContNo);

        Validate("Payment Instructions Id", O365SalesInvoiceMgmt.GetDefaultPaymentInstructionsId);

        if "Salesperson Code" = '' then
            SetDefaultSalesperson;

        if "Sell-to Customer No." <> '' then
            StandardCodesMgt.CheckCreateSalesRecurringLines(Rec);

        // Remove view filters so that the cards does not show filtered view notification
        SetView('');

        OnAfterOnInsert(Rec);
    end;

    trigger OnRename()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRename(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        Error(Text003, TableCaption);
    end;

    var
        Text003: Label 'You cannot rename a %1.';
        ConfirmChangeQst: Label 'Do you want to change %1?', Comment = '%1 = a Field Caption like Currency Code';
        Text005: Label 'You cannot reset %1 because the document still has one or more lines.';
        Text006: Label 'You cannot change %1 because the order is associated with one or more purchase orders.';
        Text007: Label '%1 cannot be greater than %2 in the %3 table.';
        Text009: Label 'Deleting this document will cause a gap in the number series for shipments. An empty shipment %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text012: Label 'Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text014: Label 'Deleting this document will cause a gap in the number series for posted credit memos. An empty posted credit memo %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        RecreateSalesLinesMsg: Label 'If you change %1, the existing sales lines will be deleted and new sales lines based on the new information on the header will be created.\\Do you want to continue?', Comment = '%1: FieldCaption';
        ResetItemChargeAssignMsg: Label 'If you change %1, the existing sales lines will be deleted and new sales lines based on the new information on the header will be created.\The amount of the item charge assignment will be reset to 0.\\Do you want to continue?', Comment = '%1: FieldCaption';
        LinesNotUpdatedMsg: Label 'You have changed %1 on the sales header, but it has not been changed on the existing sales lines.', Comment = 'You have changed Order Date on the sales header, but it has not been changed on the existing sales lines.';
        LinesNotUpdatedDateMsg: Label 'You have changed the %1 on the sales order, which might affect the prices and discounts on the sales order lines. You should review the lines and manually update prices and discounts if needed.', Comment = '%1: OrderDate';
        Text019: Label 'You must update the existing sales lines manually.';
        AffectExchangeRateMsg: Label 'The change may affect the exchange rate that is used for price calculation on the sales lines.';
        Text021: Label 'Do you want to update the exchange rate?';
        Text022: Label 'You cannot delete this document. Your identification is set up to process from %1 %2 only.';
        Text024: Label 'You have modified the %1 field. The recalculation of VAT may cause penny differences, so you must check the amounts afterward. Do you want to update the %2 field on the lines to reflect the new value of %1?';
        Text027: Label 'Your identification is set up to process from %1 %2 only.';
        Text028: Label 'You cannot change the %1 when the %2 has been filled in.';
        Text030: Label 'Deleting this document will cause a gap in the number series for return receipts. An empty return receipt %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text031: Label 'You have modified %1.\\Do you want to update the lines?', Comment = 'You have modified Shipment Date.\\Do you want to update the lines?';
        ReadingDataSkippedMsg: Label 'Loading field %1 will be skipped because there was an error when reading the data.\To fix the current data, contact your administrator.\Alternatively, you can overwrite the current data by entering data in the field.', Comment = '%1=field caption';
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        CurrExchRate: Record "Currency Exchange Rate";
        PostCode: Record "Post Code";
        BankAcc: Record "Bank Account";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        SalesInvHeaderPrepmt: Record "Sales Invoice Header";
        SalesCrMemoHeaderPrepmt: Record "Sales Cr.Memo Header";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        RespCenter: Record "Responsibility Center";
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        WhseRequest: Record "Warehouse Request";
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        CompanyInfo: Record "Company Information";
        Salesperson: Record "Salesperson/Purchaser";
        UserSetupMgt: Codeunit "User Setup Management";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        DimMgt: Codeunit DimensionManagement;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WhseSourceHeader: Codeunit "Whse. Validate Source Header";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        PostingSetupMgt: Codeunit PostingSetupManagement;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        CurrencyDate: Date;
        Confirmed: Boolean;
        Text035: Label 'You cannot Release Quote or Make Order unless you specify a customer on the quote.\\Do you want to create customer(s) now?';
        Text037: Label 'Contact %1 %2 is not related to customer %3.';
        Text038: Label 'Contact %1 %2 is related to a different company than customer %3.';
        ContactIsNotRelatedToAnyCostomerErr: Label 'Contact %1 %2 is not related to a customer.';
        Text040: Label 'A won opportunity is linked to this order.\It has to be changed to status Lost before the Order can be deleted.\Do you want to change the status for this opportunity now?';
        Text044: Label 'The status of the opportunity has not been changed. The program has aborted deleting the order.';
        SkipSellToContact: Boolean;
        SkipBillToContact: Boolean;
        Text045: Label 'You can not change the %1 field because %2 %3 has %4 = %5 and the %6 has already been assigned %7 %8.';
        Text048: Label 'Sales quote %1 has already been assigned to opportunity %2. Would you like to reassign this quote?';
        Text049: Label 'The %1 field cannot be blank because this quote is linked to an opportunity.';
        InsertMode: Boolean;
        HideCreditCheckDialogue: Boolean;
        Text051: Label 'The sales %1 %2 already exists.';
        Text053: Label 'You must cancel the approval process if you wish to change the %1.';
        Text056: Label 'Deleting this document will cause a gap in the number series for prepayment invoices. An empty prepayment invoice %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text057: Label 'Deleting this document will cause a gap in the number series for prepayment credit memos. An empty prepayment credit memo %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text061: Label '%1 is set up to process from %2 %3 only.';
        Text062: Label 'You cannot change %1 because the corresponding %2 %3 has been assigned to this %4.';
        Text063: Label 'Reservations exist for this order. These reservations will be canceled if a date conflict is caused by this change.\\Do you want to continue?';
        Text064: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        UpdateDocumentDate: Boolean;
        Text066: Label 'You cannot change %1 to %2 because an open inventory pick on the %3.';
        Text070: Label 'You cannot change %1  to %2 because an open warehouse shipment exists for the %3.';
        BilltoCustomerNoChanged: Boolean;
        SelectNoSeriesAllowed: Boolean;
        PrepaymentInvoicesNotPaidErr: Label 'You cannot post the document of type %1 with the number %2 before all related prepayment invoices are posted.', Comment = 'You cannot post the document of type Order with the number 1001 before all related prepayment invoices are posted.';
        Text072: Label 'There are unpaid prepayment invoices related to the document of type %1 with the number %2.';
        DeferralLineQst: Label 'Do you want to update the deferral schedules for the lines?';
        SynchronizingMsg: Label 'Synchronizing ...\ from: Sales Header with %1\ to: Assembly Header with %2.';
        EstimateTxt: Label 'Estimate';
        ShippingAdviceErr: Label 'This document cannot be shipped completely. Change the value in the Shipping Advice field to Partial.';
        PostedDocsToPrintCreatedMsg: Label 'One or more related posted documents have been generated during deletion to fill gaps in the posting number series. You can view or print the documents from the respective document archive.';
        DocumentNotPostedClosePageQst: Label 'The document has been saved but is not yet posted.\\Are you sure you want to exit?';
        SelectCustomerTemplateQst: Label 'Do you want to select the customer template?';
        ModifyCustomerAddressNotificationLbl: Label 'Update the address';
        DontShowAgainActionLbl: Label 'Don''t show again';
        ModifyCustomerAddressNotificationMsg: Label 'The address you entered for %1 is different from the customer''s existing address.', Comment = '%1=customer name';
        ValidVATNoMsg: Label 'The specified VAT registration number is valid.';
        InvalidVatRegNoMsg: Label 'The VAT registration number is not valid. Try entering the number again.';
        SellToCustomerTxt: Label 'Sell-to Customer';
        BillToCustomerTxt: Label 'Bill-to Customer';
        ModifySellToCustomerAddressNotificationNameTxt: Label 'Update Sell-to Customer Address';
        ModifySellToCustomerAddressNotificationDescriptionTxt: Label 'Warn if the sell-to address on sales documents is different from the customer''s existing address.';
        ModifyBillToCustomerAddressNotificationNameTxt: Label 'Update Bill-to Customer Address';
        ModifyBillToCustomerAddressNotificationDescriptionTxt: Label 'Warn if the bill-to address on sales documents is different from the customer''s existing address.';
        DuplicatedCaptionsNotAllowedErr: Label 'Field captions must not be duplicated when using this method. Use UpdateSalesLinesByFieldNo instead.';
        PhoneNoCannotContainLettersErr: Label 'You cannot enter letters in this field.';
        SplitMessageTxt: Label '%1\%2', Comment = 'Some message text 1.\Some message text 2.';
        ConfirmEmptyEmailQst: Label 'Contact %1 has no email address specified. The value in the Email field on the sales order, %2, will be deleted. Do you want to continue?', Comment = '%1 - Contact No., %2 - Email';
        FullSalesTypesTxt: Label 'Sales Quote,Sales Order,Sales Invoice,Sales Credit Memo,Sales Blanket Order,Sales Return Order';
        RecreateSalesLinesCancelErr: Label 'You must delete the existing sales lines before you can change %1.', Comment = '%1 - Field Name, Sample: You must delete the existing sales lines before you can change Currency Code.';
        CalledFromWhseDoc: Boolean;

    protected var
        HideValidationDialog: Boolean;
        StatusCheckSuspended: Boolean;

    procedure InitInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitInsert(Rec, xRec, IsHandled);
        if not IsHandled then
            if "No." = '' then begin
                TestNoSeries;
                NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", "Posting Date", "No.", "No. Series");
            end;

        OnInitInsertOnBeforeInitRecord(Rec, xRec);
        InitRecord;
    end;

    procedure InitRecord()
    var
        ArchiveManagement: Codeunit ArchiveManagement;
        IsHandled: Boolean;
    begin
        GetSalesSetup;
        IsHandled := false;
        OnBeforeInitRecord(Rec, IsHandled, xRec);
        if not IsHandled then
            case "Document Type" of
                "Document Type"::Quote, "Document Type"::Order:
                    begin
                        NoSeriesMgt.SetDefaultSeries("Posting No. Series", SalesSetup."Posted Invoice Nos.");
                        NoSeriesMgt.SetDefaultSeries("Shipping No. Series", SalesSetup."Posted Shipment Nos.");
                        if "Document Type" = "Document Type"::Order then begin
                            NoSeriesMgt.SetDefaultSeries("Prepayment No. Series", SalesSetup."Posted Prepmt. Inv. Nos.");
                            NoSeriesMgt.SetDefaultSeries("Prepmt. Cr. Memo No. Series", SalesSetup."Posted Prepmt. Cr. Memo Nos.");
                        end;
                    end;
                "Document Type"::Invoice:
                    begin
                        if ("No. Series" <> '') and
                           (SalesSetup."Invoice Nos." = SalesSetup."Posted Invoice Nos.")
                        then
                            "Posting No. Series" := "No. Series"
                        else
                            NoSeriesMgt.SetDefaultSeries("Posting No. Series", SalesSetup."Posted Invoice Nos.");
                        if SalesSetup."Shipment on Invoice" then
                            NoSeriesMgt.SetDefaultSeries("Shipping No. Series", SalesSetup."Posted Shipment Nos.");
                    end;
                "Document Type"::"Return Order":
                    begin
                        NoSeriesMgt.SetDefaultSeries("Posting No. Series", SalesSetup."Posted Credit Memo Nos.");
                        NoSeriesMgt.SetDefaultSeries("Return Receipt No. Series", SalesSetup."Posted Return Receipt Nos.");
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        if ("No. Series" <> '') and
                           (SalesSetup."Credit Memo Nos." = SalesSetup."Posted Credit Memo Nos.")
                        then
                            "Posting No. Series" := "No. Series"
                        else
                            NoSeriesMgt.SetDefaultSeries("Posting No. Series", SalesSetup."Posted Credit Memo Nos.");
                        if SalesSetup."Return Receipt on Credit Memo" then
                            NoSeriesMgt.SetDefaultSeries("Return Receipt No. Series", SalesSetup."Posted Return Receipt Nos.");
                    end;
            end;

        InitShipmentDate();

        InitPostingDate();

        if SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" then
            "Posting Date" := 0D;

        "Order Date" := WorkDate;
        "Document Date" := WorkDate;
        if "Document Type" = "Document Type"::Quote then
            CalcQuoteValidUntilDate;

        IF "Sell-to Customer No." <> '' THEN
            GetCust("Sell-to Customer No.");
        UpdateLocationCode(Cust."Location Code");

        if IsCreditDocType then begin
            GLSetup.Get();
            Correction := GLSetup."Mark Cr. Memos as Corrections";
        end;

        InitPostingDescription();

        UpdateOutboundWhseHandlingTime;

        "Responsibility Center" := UserSetupMgt.GetRespCenter(0, "Responsibility Center");
        "Doc. No. Occurrence" := ArchiveManagement.GetNextOccurrenceNo(DATABASE::"Sales Header", "Document Type".AsInteger(), "No.");

        OnAfterInitRecord(Rec);
    end;

    local procedure InitShipmentDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInitRecordOnBeforeAssignShipmentDate(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice, "Document Type"::Quote] then
            "Shipment Date" := WorkDate();
    end;

    local procedure InitPostingDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInitRecordOnBeforeAssignWorkDateToPostingDate(Rec, IsHandled);
        if IsHandled then
            exit;

        if not ("Document Type" in ["Document Type"::"Blanket Order", "Document Type"::Quote]) and
           ("Posting Date" = 0D)
        then
            "Posting Date" := WorkDate();
    end;

    local procedure InitNoSeries()
    begin
        if xRec."Shipping No." <> '' then begin
            "Shipping No. Series" := xRec."Shipping No. Series";
            "Shipping No." := xRec."Shipping No.";
        end;
        if xRec."Posting No." <> '' then begin
            "Posting No. Series" := xRec."Posting No. Series";
            "Posting No." := xRec."Posting No.";
        end;
        if xRec."Return Receipt No." <> '' then begin
            "Return Receipt No. Series" := xRec."Return Receipt No. Series";
            "Return Receipt No." := xRec."Return Receipt No.";
        end;
        if xRec."Prepayment No." <> '' then begin
            "Prepayment No. Series" := xRec."Prepayment No. Series";
            "Prepayment No." := xRec."Prepayment No.";
        end;
        if xRec."Prepmt. Cr. Memo No." <> '' then begin
            "Prepmt. Cr. Memo No. Series" := xRec."Prepmt. Cr. Memo No. Series";
            "Prepmt. Cr. Memo No." := xRec."Prepmt. Cr. Memo No.";
        end;

        OnAfterInitNoSeries(Rec, xRec);
    end;

    local procedure InitPostingDescription()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitPostingDescription(Rec, IsHandled);
        if IsHandled then
            exit;

        "Posting Description" := Format("Document Type") + ' ' + "No.";
    end;

    procedure AssistEdit(OldSalesHeader: Record "Sales Header") Result: Boolean
    var
        SalesHeader2: Record "Sales Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldSalesHeader, IsHandled, Result);
        if IsHandled then
            exit;

        with SalesHeader do begin
            Copy(Rec);
            GetSalesSetup;
            TestNoSeries;
            if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldSalesHeader."No. Series", "No. Series") then begin
                if ("Sell-to Customer No." = '') and ("Sell-to Contact No." = '') then begin
                    HideCreditCheckDialogue := false;
                    CheckCreditMaxBeforeInsert;
                    HideCreditCheckDialogue := true;
                end;
                NoSeriesMgt.SetSeries("No.");
                if SalesHeader2.Get("Document Type", "No.") then
                    Error(Text051, LowerCase(Format("Document Type")), "No.");
                Rec := SalesHeader;
                exit(true);
            end;
        end;
    end;

    procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        GetSalesSetup;
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, IsHandled);
        if not IsHandled then
            case "Document Type" of
                "Document Type"::Quote:
                    SalesSetup.TestField("Quote Nos.");
                "Document Type"::Order:
                    SalesSetup.TestField("Order Nos.");
                "Document Type"::Invoice:
                    begin
                        SalesSetup.TestField("Invoice Nos.");
                        SalesSetup.TestField("Posted Invoice Nos.");
                    end;
                "Document Type"::"Return Order":
                    SalesSetup.TestField("Return Order Nos.");
                "Document Type"::"Credit Memo":
                    begin
                        SalesSetup.TestField("Credit Memo Nos.");
                        SalesSetup.TestField("Posted Credit Memo Nos.");
                    end;
                "Document Type"::"Blanket Order":
                    SalesSetup.TestField("Blanket Order Nos.");
            end;

        OnAfterTestNoSeries(Rec);
    end;

    procedure GetNoSeriesCode(): Code[20]
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        GetSalesSetup;
        IsHandled := false;
        OnBeforeGetNoSeriesCode(Rec, SalesSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        case "Document Type" of
            "Document Type"::Quote:
                NoSeriesCode := SalesSetup."Quote Nos.";
            "Document Type"::Order:
                NoSeriesCode := SalesSetup."Order Nos.";
            "Document Type"::Invoice:
                NoSeriesCode := SalesSetup."Invoice Nos.";
            "Document Type"::"Return Order":
                NoSeriesCode := SalesSetup."Return Order Nos.";
            "Document Type"::"Credit Memo":
                NoSeriesCode := SalesSetup."Credit Memo Nos.";
            "Document Type"::"Blanket Order":
                NoSeriesCode := SalesSetup."Blanket Order Nos.";
        end;
        OnAfterGetNoSeriesCode(Rec, SalesSetup, NoSeriesCode);
        exit(NoSeriesMgt.GetNoSeriesWithCheck(NoSeriesCode, SelectNoSeriesAllowed, "No. Series"));
    end;

    local procedure GetPostingNoSeriesCode() PostingNos: Code[20]
    var
        IsHandled: Boolean;
    begin
        GetSalesSetup;
        IsHandled := false;
        OnBeforeGetPostingNoSeriesCode(Rec, SalesSetup, PostingNos, IsHandled);
        if IsHandled then
            exit;

        if IsCreditDocType then
            PostingNos := SalesSetup."Posted Credit Memo Nos."
        else
            PostingNos := SalesSetup."Posted Invoice Nos.";

        OnAfterGetPostingNoSeriesCode(Rec, PostingNos);
    end;

    local procedure GetPostingPrepaymentNoSeriesCode() PostingNos: Code[20]
    begin
        if IsCreditDocType then
            PostingNos := SalesSetup."Posted Prepmt. Cr. Memo Nos."
        else
            PostingNos := SalesSetup."Posted Prepmt. Inv. Nos.";

        OnAfterGetPrepaymentPostingNoSeriesCode(Rec, PostingNos);
    end;

    local procedure TestNoSeriesDate(No: Code[20]; NoSeriesCode: Code[20]; NoCapt: Text[1024]; NoSeriesCapt: Text[1024])
    var
        NoSeries: Record "No. Series";
    begin
        if (No <> '') and (NoSeriesCode <> '') then begin
            NoSeries.Get(NoSeriesCode);
            if NoSeries."Date Order" then
                Error(
                  Text045,
                  FieldCaption("Posting Date"), NoSeriesCapt, NoSeriesCode,
                  NoSeries.FieldCaption("Date Order"), NoSeries."Date Order", "Document Type",
                  NoCapt, No);
        end;
    end;

    procedure ConfirmDeletion(): Boolean
    var
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        PostSalesDelete: Codeunit "PostSales-Delete";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        OnBeforeConfirmDeletion(Rec);
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Deleted Document");
        SourceCode.Get(SourceCodeSetup."Deleted Document");

        PostSalesDelete.InitDeleteHeader(
          Rec, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader,
          SalesInvHeaderPrepmt, SalesCrMemoHeaderPrepmt, SourceCode.Code);

        if SalesShptHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text009, SalesShptHeader."No."), true) then
                exit;
        if SalesInvHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text012, SalesInvHeader."No."), true) then
                exit;
        if SalesCrMemoHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text014, SalesCrMemoHeader."No."), true) then
                exit;
        if ReturnRcptHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text030, ReturnRcptHeader."No."), true) then
                exit;
        if "Prepayment No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text056, SalesInvHeaderPrepmt."No."), true) then
                exit;
        if "Prepmt. Cr. Memo No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text057, SalesCrMemoHeaderPrepmt."No."), true) then
                exit;
        exit(true);
    end;

    procedure GetCust(CustNo: Code[20])
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        if not (("Document Type" = "Document Type"::Quote) and (CustNo = '')) then begin
            if CustNo <> Cust."No." then
                Cust.Get(CustNo);
        end else
            Clear(Cust);
        if EnvInfoProxy.IsInvoicing and O365SalesInitialSetup.Get then
            Cust."Payment Terms Code" := O365SalesInitialSetup."Default Payment Terms Code";
    end;

    local procedure GetSalesSetup()
    begin
        SalesSetup.Get();
        OnAfterGetSalesSetup(Rec, SalesSetup, CurrFieldNo);
    end;

    procedure SalesLinesExist(): Boolean
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        exit(not SalesLine.IsEmpty);
    end;

    procedure RecreateSalesLines(ChangedFieldName: Text[100])
    var
        TempSalesLine: Record "Sales Line" temporary;
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        TempInteger: Record "Integer" temporary;
        TempATOLink: Record "Assemble-to-Order Link" temporary;
        SalesCommentLine: Record "Sales Comment Line";
        TempSalesCommentLine: Record "Sales Comment Line" temporary;
        ATOLink: Record "Assemble-to-Order Link";
        ExtendedTextAdded: Boolean;
        ConfirmText: Text;
        IsHandled: Boolean;
    begin
        if not SalesLinesExist() then
            exit;

        IsHandled := false;
        OnBeforeRecreateSalesLinesHandler(Rec, xRec, ChangedFieldName, IsHandled);
        if IsHandled then
            exit;

        IsHandled := false;
        OnRecreateSalesLinesOnBeforeConfirm(Rec, xRec, ChangedFieldName, HideValidationDialog, Confirmed, IsHandled);
        if not IsHandled then
            if GetHideValidationDialog() or not GuiAllowed() then
                Confirmed := true
            else begin
                if HasItemChargeAssignment() then
                    ConfirmText := ResetItemChargeAssignMsg
                else
                    ConfirmText := RecreateSalesLinesMsg;
                Confirmed := Confirm(ConfirmText, false, ChangedFieldName);
            end;

        if Confirmed then begin
            SalesLine.LockTable();
            ItemChargeAssgntSales.LockTable();
            ReservEntry.LockTable();
            Modify();
            OnBeforeRecreateSalesLines(Rec);
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "No.");
            OnRecreateSalesLinesOnAfterSetSalesLineFilters(SalesLine);
            if SalesLine.FindSet() then begin
                TempReservEntry.DeleteAll();
                RecreateReservEntryReqLine(TempSalesLine, TempATOLink, ATOLink);
                StoreSalesCommentLineToTemp(TempSalesCommentLine);
                SalesCommentLine.DeleteComments("Document Type".AsInteger(), "No.");
                TransferItemChargeAssgntSalesToTemp(ItemChargeAssgntSales, TempItemChargeAssgntSales);
                IsHandled := false;
                OnRecreateSalesLinesOnBeforeSalesLineDeleteAll(Rec, SalesLine, CurrFieldNo, IsHandled);
                if not IsHandled then
                    SalesLine.DeleteAll(true);

                SalesLine.Init();
                SalesLine."Line No." := 0;
                OnRecreateSalesLinesOnBeforeTempSalesLineFindSet(TempSalesLine);
                TempSalesLine.FindSet();
                ExtendedTextAdded := false;
                SalesLine.BlockDynamicTracking(true);
                repeat
                    RecreateSalesLinesHandleSupplementTypes(TempSalesLine, ExtendedTextAdded, TempItemChargeAssgntSales, TempInteger);
                    RestoreSalesCommentLine(TempSalesCommentLine, TempSalesLine."Line No.", SalesLine."Line No.");
                    SalesLineReserve.CopyReservEntryFromTemp(TempReservEntry, TempSalesLine, SalesLine."Line No.");
                    RecreateReqLine(TempSalesLine, SalesLine."Line No.", false);
                    SynchronizeForReservations(SalesLine, TempSalesLine);

                    if TempATOLink.AsmExistsForSalesLine(TempSalesLine) then begin
                        ATOLink := TempATOLink;
                        ATOLink."Document Line No." := SalesLine."Line No.";
                        ATOLink.Insert();
                        ATOLink.UpdateAsmFromSalesLineATOExist(SalesLine);
                        TempATOLink.Delete();
                    end;
                until TempSalesLine.Next() = 0;

                RestoreSalesCommentLine(TempSalesCommentLine, 0, 0);

                CreateItemChargeAssgntSales(TempItemChargeAssgntSales, TempSalesLine, TempInteger);

                TempSalesLine.SetRange(Type);
                TempSalesLine.DeleteAll();
                OnAfterDeleteAllTempSalesLines(Rec);
                ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
                TempItemChargeAssgntSales.DeleteAll();
            end;
        end else
            Error(RecreateSalesLinesCancelErr, ChangedFieldName);

        SalesLine.BlockDynamicTracking(false);

        OnAfterRecreateSalesLines(Rec, ChangedFieldName);
    end;

    local procedure RecreateSalesLinesHandleSupplementTypes(var TempSalesLine: Record "Sales Line" temporary; var ExtendedTextAdded: Boolean; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; var TempInteger: Record "Integer" temporary)
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecreateSalesLinesHandleSupplementTypes(TempSalesLine, IsHandled);
        if IsHandled then
            exit;

        if TempSalesLine."Attached to Line No." = 0 then begin
            CreateSalesLine(TempSalesLine);
            ExtendedTextAdded := false;
            OnAfterRecreateSalesLine(SalesLine, TempSalesLine);

            if SalesLine.Type = SalesLine.Type::Item then
                RecreateSalesLinesFillItemChargeAssignment(SalesLine, TempSalesLine, TempItemChargeAssgntSales);

            if SalesLine.Type = SalesLine.Type::"Charge (Item)" then begin
                TempInteger.Init();
                TempInteger.Number := SalesLine."Line No.";
                TempInteger.Insert();
            end;
        end else
            if not ExtendedTextAdded then begin
                TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true);
                TransferExtendedText.InsertSalesExtText(SalesLine);
                OnAfterTransferExtendedTextForSalesLineRecreation(SalesLine, TempSalesLine);

                SalesLine.FindLast();
                ExtendedTextAdded := true;
            end;

        OnAfterRecreateSalesLinesHandleSupplementTypes(Rec);
    end;

    local procedure StoreSalesCommentLineToTemp(var TempSalesCommentLine: Record "Sales Comment Line" temporary)
    var
        SalesCommentLine: Record "Sales Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStoreSalesCommentLineToTemp(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        SalesCommentLine.SetRange("Document Type", "Document Type");
        SalesCommentLine.SetRange("No.", "No.");
        if SalesCommentLine.FindSet() then
            repeat
                TempSalesCommentLine := SalesCommentLine;
                TempSalesCommentLine.Insert();
            until SalesCommentLine.Next() = 0;
    end;

    local procedure RestoreSalesCommentLine(var TempSalesCommentLine: Record "Sales Comment Line" temporary; OldDocumnetLineNo: Integer; NewDocumentLineNo: Integer)
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        TempSalesCommentLine.SetRange("Document Type", "Document Type");
        TempSalesCommentLine.SetRange("No.", "No.");
        TempSalesCommentLine.SetRange("Document Line No.", OldDocumnetLineNo);
        if TempSalesCommentLine.FindSet() then
            repeat
                SalesCommentLine := TempSalesCommentLine;
                SalesCommentLine."Document Line No." := NewDocumentLineNo;
                SalesCommentLine.Insert();
            until TempSalesCommentLine.Next() = 0;
    end;

    local procedure RecreateSalesLinesFillItemChargeAssignment(SalesLine: Record "Sales Line"; TempSalesLine: Record "Sales Line" temporary; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
        ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Type", TempSalesLine."Document Type");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. No.", TempSalesLine."Document No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", TempSalesLine."Line No.");
        if TempItemChargeAssgntSales.FindSet then
            repeat
                if not TempItemChargeAssgntSales.Mark then begin
                    TempItemChargeAssgntSales."Applies-to Doc. Line No." := SalesLine."Line No.";
                    TempItemChargeAssgntSales.Description := SalesLine.Description;
                    TempItemChargeAssgntSales.Modify();
                    TempItemChargeAssgntSales.Mark(true);
                end;
            until TempItemChargeAssgntSales.Next() = 0;
    end;

    procedure MessageIfSalesLinesExist(ChangedFieldName: Text[100])
    var
        MessageText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMessageIfSalesLinesExist(Rec, ChangedFieldName, IsHandled);
        if IsHandled then
            exit;

        if SalesLinesExist and not GetHideValidationDialog then begin
            MessageText := StrSubstNo(LinesNotUpdatedMsg, ChangedFieldName);
            MessageText := StrSubstNo(SplitMessageTxt, MessageText, Text019);
            Message(MessageText);
        end;
    end;

    procedure PriceMessageIfSalesLinesExist(ChangedFieldName: Text[100])
    var
        MessageText: Text;
        IsHandled: Boolean;
    begin
        OnBeforePriceMessageIfSalesLinesExist(Rec, ChangedFieldName, IsHandled);
        if IsHandled then
            exit;

        if SalesLinesExist and not GetHideValidationDialog then begin
            MessageText := StrSubstNo(LinesNotUpdatedDateMsg, ChangedFieldName);
            if "Currency Code" <> '' then
                MessageText := StrSubstNo(SplitMessageTxt, MessageText, AffectExchangeRateMsg);
            Message(MessageText);
        end;
    end;

    procedure UpdateCurrencyFactor()
    var
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        Updated: Boolean;
    begin
        OnBeforeUpdateCurrencyFactor(Rec, Updated, CurrExchRate);
        if Updated then
            exit;

        if "Currency Code" <> '' then begin
            if "Posting Date" <> 0D then
                CurrencyDate := "Posting Date"
            else
                CurrencyDate := WorkDate;

            if UpdateCurrencyExchangeRates.ExchangeRatesForCurrencyExist(CurrencyDate, "Currency Code") then begin
                "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
                if "Currency Code" <> xRec."Currency Code" then
                    RecreateSalesLines(FieldCaption("Currency Code"));
            end else
                UpdateCurrencyExchangeRates.ShowMissingExchangeRatesNotification("Currency Code");
        end else begin
            "Currency Factor" := 0;
            if "Currency Code" <> xRec."Currency Code" then
                RecreateSalesLines(FieldCaption("Currency Code"));
        end;

        OnAfterUpdateCurrencyFactor(Rec, GetHideValidationDialog);
    end;

    procedure ConfirmCurrencyFactorUpdate()
    begin
        OnBeforeConfirmUpdateCurrencyFactor(Rec, HideValidationDialog);

        if GetHideValidationDialog or not GuiAllowed then
            Confirmed := true
        else
            Confirmed := Confirm(Text021, false);
        if Confirmed then
            Validate("Currency Factor")
        else
            "Currency Factor" := xRec."Currency Factor";
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure GetHideValidationDialog(): Boolean
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        exit(HideValidationDialog or EnvInfoProxy.IsInvoicing);
    end;

    procedure UpdateLocationCode(LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLocationCode(Rec, LocationCode, IsHandled);
        if not IsHandled then
            Validate("Location Code", UserSetupMgt.GetLocation(0, LocationCode, "Responsibility Center"));
    end;

    procedure UpdateSalesLines(ChangedFieldName: Text[100]; AskQuestion: Boolean)
    var
        "Field": Record "Field";
    begin
        OnBeforeUpdateSalesLines(Rec, ChangedFieldName, AskQuestion);

        Field.SetRange(TableNo, DATABASE::"Sales Header");
        Field.SetRange("Field Caption", ChangedFieldName);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.Find('-');
        if Field.Next <> 0 then
            Error(DuplicatedCaptionsNotAllowedErr);
        UpdateSalesLinesByFieldNo(Field."No.", AskQuestion);

        OnAfterUpdateSalesLines(Rec);
    end;

    local procedure UpdateSalesLineAmounts()
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesLineAmounts(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetFilter(Quantity, '<>0');
        SalesLine.LockTable();
        LockTable();
        if SalesLine.FindSet then begin
            Modify;
            OnUpdateSalesLineAmountsOnAfterSalesHeaderModify(Rec, SalesLine);
            repeat
                if (SalesLine."Quantity Invoiced" <> SalesLine.Quantity) or
                   ("Shipping Advice" = "Shipping Advice"::Complete) or
                   (SalesLine.Type <> SalesLine.Type::"Charge (Item)") or
                   (CurrFieldNo <> 0)
                then begin
                    SalesLine.UpdateAmounts;
                    SalesLine.Modify();
                end;
            until SalesLine.Next() = 0;
        end;
    end;

    procedure UpdateSalesLinesByFieldNo(ChangedFieldNo: Integer; AskQuestion: Boolean)
    var
        "Field": Record "Field";
        JobTransferLine: Codeunit "Job Transfer Line";
        Question: Text[250];
        IsHandled: Boolean;
        ShouldConfirmReservationDateConflict: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesLinesByFieldNo(Rec, ChangedFieldNo, AskQuestion, IsHandled, xRec);
        if IsHandled then
            exit;

        if not SalesLinesExist then
            exit;

        if not Field.Get(DATABASE::"Sales Header", ChangedFieldNo) then
            Field.Get(DATABASE::"Sales Line", ChangedFieldNo);

        if AskQuestion then begin
            Question := StrSubstNo(Text031, Field."Field Caption");
            if GuiAllowed and not GetHideValidationDialog then
                if DIALOG.Confirm(Question, true) then begin
                    ShouldConfirmReservationDateConflict := ChangedFieldNo in [
                        FieldNo("Shipment Date"),
                        FieldNo("Shipping Agent Code"),
                        FieldNo("Shipping Agent Service Code"),
                        FieldNo("Shipping Time"),
                        FieldNo("Requested Delivery Date"),
                        FieldNo("Promised Delivery Date"),
                        FieldNo("Outbound Whse. Handling Time")
                    ];
                    OnUpdateSalesLinesByFieldNoOnAfterCalcShouldConfirmReservationDateConflict(Rec, ChangedFieldNo, ShouldConfirmReservationDateConflict);
                    if ShouldConfirmReservationDateConflict then
                        ConfirmReservationDateConflict();
                end else
                    exit
        end;

        SalesLine.LockTable();
        Modify;

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        if SalesLine.FindSet then
            repeat
                IsHandled := false;
                OnBeforeSalesLineByChangedFieldNo(Rec, SalesLine, ChangedFieldNo, IsHandled);
                if not IsHandled then
                    case ChangedFieldNo of
                        FieldNo("Shipment Date"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Shipment Date", "Shipment Date");
                        FieldNo("Currency Factor"):
                            if SalesLine.Type <> SalesLine.Type::" " then begin
                                SalesLine.Validate("Unit Price");
                                SalesLine.Validate("Unit Cost (LCY)");
                                if SalesLine."Job No." <> '' then
                                    JobTransferLine.FromSalesHeaderToPlanningLine(SalesLine, "Currency Factor");
                            end;
                        FieldNo("Transaction Type"):
                            SalesLine.Validate("Transaction Type", "Transaction Type");
                        FieldNo("Transport Method"):
                            SalesLine.Validate("Transport Method", "Transport Method");
                        FieldNo("Exit Point"):
                            SalesLine.Validate("Exit Point", "Exit Point");
                        FieldNo(Area):
                            SalesLine.Validate(Area, Area);
                        FieldNo("Transaction Specification"):
                            SalesLine.Validate("Transaction Specification", "Transaction Specification");
                        FieldNo("Shipping Agent Code"):
                            SalesLine.Validate("Shipping Agent Code", "Shipping Agent Code");
                        FieldNo("Shipping Agent Service Code"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Shipping Agent Service Code", "Shipping Agent Service Code");
                        FieldNo("Shipping Time"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Shipping Time", "Shipping Time");
                        FieldNo("Prepayment %"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Prepayment %", "Prepayment %");
                        FieldNo("Requested Delivery Date"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Requested Delivery Date", "Requested Delivery Date");
                        FieldNo("Promised Delivery Date"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Promised Delivery Date", "Promised Delivery Date");
                        FieldNo("Outbound Whse. Handling Time"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Outbound Whse. Handling Time", "Outbound Whse. Handling Time");
                        SalesLine.FieldNo("Deferral Code"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Deferral Code");
                        else
                            OnUpdateSalesLineByChangedFieldName(Rec, SalesLine, Field.FieldName, ChangedFieldNo);
                    end;
                SalesLineReserve.AssignForPlanning(SalesLine);
                OnUpdateSalesLinesByFieldNoOnBeforeSalesLineModify(SalesLine, ChangedFieldNo, CurrFieldNo);
                SalesLine.Modify(true);
            until SalesLine.Next() = 0;

        OnAfterUpdateSalesLinesByFieldNo(Rec, xRec, ChangedFieldNo);
    end;

    procedure ConfirmReservationDateConflict()
    var
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
    begin
        if ReservationEngineMgt.ResvExistsForSalesHeader(Rec) then
            if not Confirm(Text063, false) then
                Error('');
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20]; Type5: Integer; No5: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        TableID[4] := Type4;
        No[4] := No4;
        TableID[5] := Type5;
        No[5] := No5;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Sales, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnCreateDimOnBeforeUpdateLines(Rec, xRec, CurrFieldNo, OldDimSetID);

        if (OldDimSetID <> "Dimension Set ID") and SalesLinesExist then begin
            Modify;
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify;

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if SalesLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShippedSalesLinesExist(): Boolean
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetFilter("Quantity Shipped", '<>0');
        exit(SalesLine.FindFirst);
    end;

    procedure ReturnReceiptExist(): Boolean
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetFilter("Return Qty. Received", '<>0');
        exit(SalesLine.FindFirst);
    end;

    procedure DeleteAllSalesLines()
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");

        DeleteSalesLines();
        SalesLine.SetRange(Type);
        DeleteSalesLines();

        SalesCommentLine.SetRange("Document Type", "Document Type");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.DeleteAll();
    end;

    local procedure DeleteSalesLines()
    var
        ReservMgt: Codeunit "Reservation Management";
        IsHandled: Boolean;
    begin
        OnBeforeDeleteSalesLines(SalesLine, IsHandled, Rec);
        if IsHandled then
            exit;

        if SalesLine.FindSet then begin
            ReservMgt.DeleteDocumentReservation(DATABASE::"Sales Line", "Document Type".AsInteger(), "No.", GetHideValidationDialog);
            repeat
                SalesLine.SuspendStatusCheck(true);
                SalesLine.Delete(true);
            until SalesLine.Next() = 0;
        end;
    end;

    local procedure DeleteRecordInApprovalRequest()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteRecordInApprovalRequest(Rec, IsHandled);
        if IsHandled then
            exit;

        ApprovalsMgmt.OnDeleteRecordInApprovalRequest(RecordId);
    end;

    local procedure ClearItemAssgntSalesFilter(var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
        TempItemChargeAssgntSales.SetRange("Document Line No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Type");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.");
    end;

    procedure CheckCustomerCreated(Prompt: Boolean): Boolean
    var
        Cont: Record Contact;
        ConfirmManagement: Codeunit "Confirm Management";
#if not CLEAN18
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
#endif
    begin
        if ("Bill-to Customer No." <> '') and ("Sell-to Customer No." <> '') then
            exit(true);

        if Prompt then
            if not ConfirmManagement.GetResponseOrDefault(Text035, true) then
                exit(false);

        if "Sell-to Customer No." = '' then begin
            TestField("Sell-to Contact No.");
#if not CLEAN18
            if not CustomerTemplMgt.IsEnabled() then
                TestField("Sell-to Customer Template Code")
            else
#endif
                TestField("Sell-to Customer Templ. Code");
            GetContact(Cont, "Sell-to Contact No.");
            CreateCustomerFromSellToCustomerTemplate(Cont);
            Commit();
            Get("Document Type"::Quote, "No.");
        end;

        if "Bill-to Customer No." = '' then begin
            TestField("Bill-to Contact No.");
#if not CLEAN18
            if not CustomerTemplMgt.IsEnabled() then
                TestField("Bill-to Customer Template Code")
            else
#endif
                TestField("Bill-to Customer Templ. Code");
            GetContact(Cont, "Bill-to Contact No.");
            CreateCustomerFromBillToCustomerTemplate(Cont);
            Commit();
            Get("Document Type"::Quote, "No.");
        end;

        exit(("Bill-to Customer No." <> '') and ("Sell-to Customer No." <> ''));
    end;

    local procedure CreateCustomerFromSellToCustomerTemplate(Cont: Record Contact)
    var
#if not CLEAN18
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateCustomerFromSellToCustomerTemplate(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

#if not CLEAN18
        if not CustomerTemplMgt.IsEnabled() then
            Cont.CreateCustomer("Sell-to Customer Template Code")
        else
#endif
        Cont.CreateCustomerFromTemplate("Sell-to Customer Templ. Code");
    end;

    local procedure CreateCustomerFromBillToCustomerTemplate(Cont: Record Contact)
    var
#if not CLEAN18
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateCustomerFromBillToCustomerTemplate(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

#if not CLEAN18
        if not CustomerTemplMgt.IsEnabled() then
            Cont.CreateCustomer("Bill-to Customer Template Code")
        else
#endif
            Cont.CreateCustomerFromTemplate("Bill-to Customer Templ. Code");
    end;

    local procedure CheckShipmentInfo(var SalesLine: Record "Sales Line"; BillTo: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShipmentInfo(Rec, xRec, SalesLine, BillTo, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::Order then
            SalesLine.SetFilter("Quantity Shipped", '<>0')
        else
            if "Document Type" = "Document Type"::Invoice then begin
                if not BillTo then
                    SalesLine.SetRange("Sell-to Customer No.", xRec."Sell-to Customer No.");
                SalesLine.SetFilter("Shipment No.", '<>%1', '');
            end;

        if SalesLine.FindFirst then
            if "Document Type" = "Document Type"::Order then
                TestQuantityShippedField(SalesLine)
            else
                SalesLine.TestField("Shipment No.", '');
        SalesLine.SetRange("Shipment No.");
        SalesLine.SetRange("Quantity Shipped");
    end;

    local procedure CheckPrepmtInfo(var SalesLine: Record "Sales Line")
    begin
        if "Document Type" = "Document Type"::Order then begin
            SalesLine.SetFilter("Prepmt. Amt. Inv.", '<>0');
            if SalesLine.Find('-') then
                SalesLine.TestField("Prepmt. Amt. Inv.", 0);
            SalesLine.SetRange("Prepmt. Amt. Inv.");
        end;
    end;

    local procedure CheckReturnInfo(var SalesLine: Record "Sales Line"; BillTo: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReturnInfo(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::"Return Order" then
            SalesLine.SetFilter("Return Qty. Received", '<>0')
        else
            if "Document Type" = "Document Type"::"Credit Memo" then begin
                if not BillTo then
                    SalesLine.SetRange("Sell-to Customer No.", xRec."Sell-to Customer No.");
                SalesLine.SetFilter("Return Receipt No.", '<>%1', '');
            end;

        if SalesLine.FindFirst then
            if "Document Type" = "Document Type"::"Return Order" then
                SalesLine.TestField("Return Qty. Received", 0)
            else
                SalesLine.TestField("Return Receipt No.", '');
    end;

#if not CLEAN18
    local procedure CopyFromSellToCustTemplate(SellToCustTemplate: Record "Customer Template")
    begin
        if not ApplicationAreaMgmt.IsSalesTaxEnabled() then
            SellToCustTemplate.TestField("Gen. Bus. Posting Group");
        "Gen. Bus. Posting Group" := SellToCustTemplate."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := SellToCustTemplate."VAT Bus. Posting Group";
        if "Bill-to Customer No." = '' then
            Validate("Bill-to Customer Template Code", "Sell-to Customer Template Code");

        OnAfterCopyFromSellToCustTemplate(Rec, SellToCustTemplate);
    end;
#endif

    local procedure CopyFromNewSellToCustTemplate(SellToCustTemplate: Record "Customer Templ.")
    begin
        if not ApplicationAreaMgmt.IsSalesTaxEnabled() then
            SellToCustTemplate.TestField("Gen. Bus. Posting Group");
        "Gen. Bus. Posting Group" := SellToCustTemplate."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := SellToCustTemplate."VAT Bus. Posting Group";
        if "Bill-to Customer No." = '' then
            Validate("Bill-to Customer Templ. Code", "Sell-to Customer Templ. Code");

        OnAfterCopyFromNewSellToCustTemplate(Rec, SellToCustTemplate);
    end;

    local procedure RecreateReqLine(OldSalesLine: Record "Sales Line"; NewSourceRefNo: Integer; ToTemp: Boolean)
    var
        ReqLine: Record "Requisition Line";
        TempReqLine: Record "Requisition Line" temporary;
    begin
        if ("Document Type" = "Document Type"::Order) then
            if ToTemp then begin
                ReqLine.SetCurrentKey("Order Promising ID", "Order Promising Line ID", "Order Promising Line No.");
                ReqLine.SetRange("Order Promising ID", OldSalesLine."Document No.");
                ReqLine.SetRange("Order Promising Line ID", OldSalesLine."Line No.");
                if ReqLine.FindSet() then begin
                    repeat
                        TempReqLine := ReqLine;
                        TempReqLine.Insert();
                    until ReqLine.Next() = 0;
                    ReqLine.DeleteAll();
                end;
            end else begin
                Clear(TempReqLine);
                TempReqLine.SetCurrentKey("Order Promising ID", "Order Promising Line ID", "Order Promising Line No.");
                TempReqLine.SetRange("Order Promising ID", OldSalesLine."Document No.");
                TempReqLine.SetRange("Order Promising Line ID", OldSalesLine."Line No.");
                if TempReqLine.FindSet() then begin
                    repeat
                        ReqLine := TempReqLine;
                        ReqLine."Order Promising Line ID" := NewSourceRefNo;
                        ReqLine.Insert();
                    until TempReqLine.Next() = 0;
                    TempReqLine.DeleteAll();
                end;
            end;
    end;

    local procedure UpdateSellToCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Cust: Record Customer;
        OfficeContact: Record Contact;
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.GetContact(OfficeContact, CustomerNo) then begin
            HideValidationDialog := true;
            UpdateSellToCust(OfficeContact."No.");
            HideValidationDialog := false;
        end else
            if Cust.Get(CustomerNo) then begin
                if Cust."Primary Contact No." <> '' then
                    "Sell-to Contact No." := Cust."Primary Contact No."
                else begin
                    ContBusRel.Reset();
                    ContBusRel.SetCurrentKey("Link to Table", "No.");
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                    ContBusRel.SetRange("No.", "Sell-to Customer No.");
                    if ContBusRel.FindFirst then
                        "Sell-to Contact No." := ContBusRel."Contact No."
                    else
                        "Sell-to Contact No." := '';
                end;
                "Sell-to Contact" := Cust.Contact;
            end;
        if "Sell-to Contact No." <> '' then
            if OfficeContact.Get("Sell-to Contact No.") then
                OfficeContact.CheckIfPrivacyBlockedGeneric;

        OnAfterUpdateSellToCont(Rec, Cust, OfficeContact, HideValidationDialog);
    end;

    procedure UpdateBillToCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Cust: Record Customer;
        Contact: Record Contact;
    begin
        if Cust.Get(CustomerNo) then begin
            if Cust."Primary Contact No." <> '' then
                "Bill-to Contact No." := Cust."Primary Contact No."
            else begin
                ContBusRel.Reset();
                ContBusRel.SetCurrentKey("Link to Table", "No.");
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                ContBusRel.SetRange("No.", "Bill-to Customer No.");
                if ContBusRel.FindFirst then
                    "Bill-to Contact No." := ContBusRel."Contact No."
                else
                    "Bill-to Contact No." := '';
            end;
            "Bill-to Contact" := Cust.Contact;
        end;
        if "Bill-to Contact No." <> '' then
            if Contact.Get("Bill-to Contact No.") then
                Contact.CheckIfPrivacyBlockedGeneric;

        OnAfterUpdateBillToCont(Rec, Cust, Contact);
    end;

    local procedure UpdateSellToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        Cont: Record Contact;
#if not CLEAN18
        CustTemplate: Record "Customer Template";
#endif
        CustomerTempl: Record "Customer Templ.";
        SearchContact: Record Contact;
#if not CLEAN18
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
#endif
        ContactBusinessRelationFound: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateSellToCust(Rec, Cont, Customer, ContactNo);

        if not Cont.Get(ContactNo) then begin
            "Sell-to Contact" := '';
            exit;
        end;
        "Sell-to Contact No." := Cont."No.";
        OnUpdateSellToCustOnAfterSetSellToContactNo(Rec, Customer, Cont);

        if Cont.Type = Cont.Type::Person then
            ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."No.");
        if not ContactBusinessRelationFound then begin
            IsHandled := false;
            OnUpdateSellToCustOnBeforeFindContactBusinessRelation(Cont, ContBusinessRelation, ContactBusinessRelationFound, IsHandled);
            IF not IsHandled THEN
                ContactBusinessRelationFound :=
                    ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.");
        end;

        if ContactBusinessRelationFound then begin
            CheckCustomerContactRelation(Cont, "Sell-to Customer No.", ContBusinessRelation."No.");

            if "Sell-to Customer No." = '' then begin
                SkipSellToContact := true;
                Validate("Sell-to Customer No.", ContBusinessRelation."No.");
                SkipSellToContact := false;
            end;

            if (Cont."E-Mail" = '') and ("Sell-to E-Mail" <> '') and GuiAllowed then begin
                if Confirm(ConfirmEmptyEmailQst, false, Cont."No.", "Sell-to E-Mail") then
                    Validate("Sell-to E-Mail", Cont."E-Mail");
            end else
                Validate("Sell-to E-Mail", Cont."E-Mail");
            Validate("Sell-to Phone No.", Cont."Phone No.");
        end else begin
            if "Document Type" = "Document Type"::Quote then begin
                if not GetContactAsCompany(Cont, SearchContact) then
                    SearchContact := Cont;
                "Sell-to Customer Name" := SearchContact."Company Name";
                "Sell-to Customer Name 2" := SearchContact."Name 2";
                "Sell-to Phone No." := SearchContact."Phone No.";
                "Sell-to E-Mail" := SearchContact."E-Mail";
                SetShipToAddress(
                  SearchContact."Company Name", SearchContact."Name 2", SearchContact.Address, SearchContact."Address 2",
                  SearchContact.City, SearchContact."Post Code", SearchContact.County, SearchContact."Country/Region Code");
                OnUpdateSellToCustOnAfterSetShipToAddress(Rec, SearchContact);
#if not CLEAN18
                if not CustomerTemplMgt.IsEnabled() then begin
                    if ("Sell-to Customer Template Code" = '') and (not CustTemplate.IsEmpty) then
                        Validate("Sell-to Customer Template Code", Cont.FindCustomerTemplate());
                end else
#endif
                    if ("Sell-to Customer Templ. Code" = '') and (not CustomerTempl.IsEmpty) then
                        Validate("Sell-to Customer Templ. Code", Cont.FindNewCustomerTemplate());
                OnUpdateSellToCustOnAfterSetFromSearchContact(Rec, SearchContact);
            end else begin
                IsHandled := false;
                OnUpdateSellToCustOnBeforeContactIsNotRelatedToAnyCostomerErr(Rec, Cont, ContBusinessRelation, IsHandled);
                if not IsHandled then
                    Error(ContactIsNotRelatedToAnyCostomerErr, Cont."No.", Cont.Name);
            end;

            "Sell-to Contact" := Cont.Name;
        end;

        UpdateSellToCustContact(Customer, Cont);

        if "Document Type" = "Document Type"::Quote then begin
            if Customer.Get("Sell-to Customer No.") or Customer.Get(ContBusinessRelation."No.") then begin
                if Customer."Copy Sell-to Addr. to Qte From" = Customer."Copy Sell-to Addr. to Qte From"::Company then
                    GetContactAsCompany(Cont, Cont);
            end else
                GetContactAsCompany(Cont, Cont);
            "Sell-to Address" := Cont.Address;
            "Sell-to Address 2" := Cont."Address 2";
            "Sell-to City" := Cont.City;
            "Sell-to Post Code" := Cont."Post Code";
            "Sell-to County" := Cont.County;
            "Sell-to Country/Region Code" := Cont."Country/Region Code";
        end;
        if ("Sell-to Customer No." = "Bill-to Customer No.") or
           ("Bill-to Customer No." = '')
        then
            Validate("Bill-to Contact No.", "Sell-to Contact No.");

        OnAfterUpdateSellToCust(Rec, Cont);
    end;

    local procedure UpdateSellToCustContact(Customer: Record Customer; Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSellToCustContact(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        if (Cont.Type = Cont.Type::Company) and Customer.Get("Sell-to Customer No.") then
            "Sell-to Contact" := Customer.Contact
        else
            if Cont.Type = Cont.Type::Company then
                "Sell-to Contact" := ''
            else
                "Sell-to Contact" := Cont.Name;
    end;

    local procedure CheckCustomerContactRelation(Cont: Record Contact; CustomerNo: Code[20]; ContBusinessRelationNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCustomerContactRelation(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        if (CustomerNo <> '') and (CustomerNo <> ContBusinessRelationNo) then
            Error(Text037, Cont."No.", Cont.Name, CustomerNo);
    end;

    local procedure UpdateBillToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Cont: Record Contact;
#if not CLEAN18
        CustTemplate: Record "Customer Template";
#endif
        SearchContact: Record Contact;
        CustomerTempl: Record "Customer Templ.";
#if not CLEAN18
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
#endif
        ContactBusinessRelationFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBillToCust(Rec, ContactNo, IsHandled);
        if IsHandled then
            exit;

        if not Cont.Get(ContactNo) then begin
            "Bill-to Contact" := '';
            exit;
        end;
        "Bill-to Contact No." := Cont."No.";

        UpdateBillToCustContact(Cont);

        if Cont.Type = Cont.Type::Person then
            ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."No.");
        if not ContactBusinessRelationFound then begin
            IsHandled := false;
            OnUpdateBillToCustOnBeforeFindContactBusinessRelation(Cont, ContBusinessRelation, ContactBusinessRelationFound, IsHandled);
            IF not IsHandled THEN
                ContactBusinessRelationFound :=
                    ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.");
        end;
        if ContactBusinessRelationFound then begin
            if "Bill-to Customer No." = '' then begin
                SkipBillToContact := true;
                Validate("Bill-to Customer No.", ContBusinessRelation."No.");
                SkipBillToContact := false;
#if not CLEAN18
                "Bill-to Customer Template Code" := '';
#endif
                "Bill-to Customer Templ. Code" := '';
            end else
                CheckCustomerContactRelation(Cont, "Bill-to Customer No.", ContBusinessRelation."No.");
        end else begin
            if "Document Type" = "Document Type"::Quote then begin
                if not GetContactAsCompany(Cont, SearchContact) then
                    SearchContact := Cont;
                "Bill-to Name" := SearchContact."Company Name";
                "Bill-to Name 2" := SearchContact."Name 2";
                "Bill-to Address" := SearchContact.Address;
                "Bill-to Address 2" := SearchContact."Address 2";
                "Bill-to City" := SearchContact.City;
                "Bill-to Post Code" := SearchContact."Post Code";
                "Bill-to County" := SearchContact.County;
                "Bill-to Country/Region Code" := SearchContact."Country/Region Code";
                "VAT Registration No." := SearchContact."VAT Registration No.";
                Validate("Currency Code", SearchContact."Currency Code");
                "Language Code" := SearchContact."Language Code";

                OnUpdateBillToCustOnAfterSalesQuote(Rec, SearchContact);

#if not CLEAN18
                if not CustomerTemplMgt.IsEnabled() then begin
                    if ("Bill-to Customer Template Code" = '') and (not CustTemplate.IsEmpty) then
                        Validate("Bill-to Customer Template Code", Cont.FindCustomerTemplate());
                end else
#endif
                    if ("Bill-to Customer Templ. Code" = '') and (not CustomerTempl.IsEmpty) then
                        Validate("Bill-to Customer Templ. Code", Cont.FindNewCustomerTemplate());
            end else begin
                IsHandled := false;
                OnUpdateBillToCustOnBeforeContactIsNotRelatedToAnyCostomerErr(Rec, Cont, ContBusinessRelation, IsHandled);
                if not IsHandled then
                    Error(ContactIsNotRelatedToAnyCostomerErr, Cont."No.", Cont.Name);
            end;
        end;

        OnAfterUpdateBillToCust(SalesHeader, Cont);
    end;

    local procedure UpdateBillToCustContact(Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBillToCustContact(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        if Cust.Get("Bill-to Customer No.") and (Cont.Type = Cont.Type::Company) then
            "Bill-to Contact" := Cust.Contact
        else
            if Cont.Type = Cont.Type::Company then
                "Bill-to Contact" := ''
            else
                "Bill-to Contact" := Cont.Name;
    end;

    local procedure UpdateSellToCustTemplateCode()
#if not CLEAN18
    var
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
#endif
    begin
#if not CLEAN18
        if not CustomerTemplMgt.IsEnabled() then begin
            if ("Document Type" = "Document Type"::Quote) and ("Sell-to Customer No." = '') and ("Sell-to Customer Template Code" = '') and
               (GetFilterContNo = '')
            then
                Validate("Sell-to Customer Template Code", SelectSalesHeaderCustomerTemplate());
        end else
#endif
            if ("Document Type" = "Document Type"::Quote) and ("Sell-to Customer No." = '') and ("Sell-to Customer Templ. Code" = '') and
               (GetFilterContNo = '')
            then
                Validate("Sell-to Customer Templ. Code", SelectSalesHeaderNewCustomerTemplate());
    end;

    local procedure GetShipmentMethodCode()
    var
        ShipToAddress: Record "Ship-to Address";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetShipmentMethodCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Ship-to Code" <> '' then begin
            ShipToAddress.Get("Sell-to Customer No.", "Ship-to Code");
            if ShipToAddress."Shipment Method Code" <> '' then
                Validate("Shipment Method Code", ShipToAddress."Shipment Method Code");
        end else
            if "Sell-to Customer No." <> '' then begin
                GetCust("Sell-to Customer No.");
                if Cust."Shipment Method Code" <> '' then
                    Validate("Shipment Method Code", Cust."Shipment Method Code");
            end;
    end;

    procedure GetShippingTime(CalledByFieldNo: Integer)
    var
        ShippingAgentServices: Record "Shipping Agent Services";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetShippingTime(Rec, xRec, CalledByFieldNo, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;
        if (CalledByFieldNo <> CurrFieldNo) and (CurrFieldNo <> 0) then
            exit;

        if ShippingAgentServices.Get("Shipping Agent Code", "Shipping Agent Service Code") then
            "Shipping Time" := ShippingAgentServices."Shipping Time"
        else begin
            GetCust("Sell-to Customer No.");
            "Shipping Time" := Cust."Shipping Time"
        end;
        if not (CalledByFieldNo in [FieldNo("Shipping Agent Code"), FieldNo("Shipping Agent Service Code")]) then
            Validate("Shipping Time");
    end;

    local procedure GetContact(var Contact: Record Contact; ContactNo: Code[20])
    begin
        Contact.Get(ContactNo);
        if (Contact.Type = Contact.Type::Person) and (Contact."Company No." <> '') then
            Contact.Get(Contact."Company No.");
    end;

    procedure GetSellToCustomerFaxNo(): Text
    var
        Customer: Record Customer;
    begin
        if Customer.Get("Sell-to Customer No.") then
            exit(Customer."Fax No.");
    end;

    procedure CheckCreditMaxBeforeInsert()
    var
        SalesHeader: Record "Sales Header";
        ContBusinessRelation: Record "Contact Business Relation";
        Cont: Record Contact;
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCreditMaxBeforeInsert(Rec, IsHandled, HideCreditCheckDialogue, GetFilterCustNo(), GetFilterContNo());
        if IsHandled then
            exit;

        if HideCreditCheckDialogue then
            exit;

        if (GetFilterCustNo <> '') or ("Sell-to Customer No." <> '') then begin
            if "Sell-to Customer No." <> '' then
                Cust.Get("Sell-to Customer No.")
            else
                Cust.Get(GetFilterCustNo);
            if Cust."Bill-to Customer No." <> '' then
                SalesHeader."Bill-to Customer No." := Cust."Bill-to Customer No."
            else
                SalesHeader."Bill-to Customer No." := Cust."No.";
            OnCheckCreditMaxBeforeInsertOnCaseIfOnBeforeSalesHeaderCheckCase(SalesHeader);
            CustCheckCreditLimit.SalesHeaderCheck(SalesHeader);
        end else
            if GetFilterContNo <> '' then begin
                Cont.Get(GetFilterContNo);
                if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.") then begin
                    Cust.Get(ContBusinessRelation."No.");
                    if Cust."Bill-to Customer No." <> '' then
                        SalesHeader."Bill-to Customer No." := Cust."Bill-to Customer No."
                    else
                        SalesHeader."Bill-to Customer No." := Cust."No.";
                    CustCheckCreditLimit.SalesHeaderCheck(SalesHeader);
                end;
            end;

        OnAfterCheckCreditMaxBeforeInsert(Rec);
    end;

    procedure CreateInvtPutAwayPick()
    var
        WhseRequest: Record "Warehouse Request";
    begin
        OnBeforeCreateInvtPutAwayPick(Rec);

        if "Document Type" = "Document Type"::Order then
            if not IsApprovedForPosting then
                exit;
        TestField(Status, Status::Released);

        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        case "Document Type" of
            "Document Type"::Order:
                begin
                    if "Shipping Advice" = "Shipping Advice"::Complete then
                        CheckShippingAdvice;
                    WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Sales Order");
                end;
            "Document Type"::"Return Order":
                WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Sales Return Order");
        end;
        WhseRequest.SetRange("Source No.", "No.");
        REPORT.RunModal(REPORT::"Create Invt Put-away/Pick/Mvmt", true, false, WhseRequest);
    end;

    procedure CreateTask()
    var
        TempTask: Record "To-do" temporary;
    begin
        TestField("Sell-to Contact No.");
        TempTask.CreateTaskFromSalesHeader(Rec);
    end;

    procedure UpdateShipToAddress()
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateShipToAddress(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if IsCreditDocType then
            if "Location Code" <> '' then begin
                Location.Get("Location Code");
                SetShipToAddress(
                  Location.Name, Location."Name 2", Location.Address, Location."Address 2", Location.City,
                  Location."Post Code", Location.County, Location."Country/Region Code");
                "Ship-to Contact" := Location.Contact;
            end else begin
                CompanyInfo.Get();
                "Ship-to Code" := '';
                SetShipToAddress(
                  CompanyInfo."Ship-to Name", CompanyInfo."Ship-to Name 2", CompanyInfo."Ship-to Address", CompanyInfo."Ship-to Address 2",
                  CompanyInfo."Ship-to City", CompanyInfo."Ship-to Post Code", CompanyInfo."Ship-to County",
                  CompanyInfo."Ship-to Country/Region Code");
                "Ship-to Contact" := CompanyInfo."Ship-to Contact";
            end;

        OnAfterUpdateShipToAddress(Rec, xRec, CurrFieldNo);
    end;

    local procedure UpdateShipToCodeFromCust()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShipToCodeFromCust(Rec, Cust, IsHandled);
        if IsHandled then
            exit;

        Validate("Ship-to Code", Cust."Ship-to Code");
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDocDim(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        OnShowDocDimOnBeforeUpdateSalesLines(Rec, xRec);
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if SalesLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure ConfirmUpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer) Confirmed: Boolean;
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmUpdateAllLineDim(Rec, xRec, NewParentDimSetID, OldParentDimSetID, Confirmed, IsHandled);
        if not IsHandled then
            Confirmed := Confirm(Text064);
    end;

    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        ATOLink: Record "Assemble-to-Order Link";
        NewDimSetID: Integer;
        ShippedReceivedItemLineDimChangeConfirmed: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAllLineDim(Rec, NewParentDimSetID, OldParentDimSetID, IsHandled, xRec);
        if IsHandled then
            exit;

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not GetHideValidationDialog and GuiAllowed then
            if not ConfirmUpdateAllLineDim(NewParentDimSetID, OldParentDimSetID) then
                exit;

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.LockTable();
        if SalesLine.Find('-') then
            repeat
                OnUpdateAllLineDimOnBeforeGetSalesLineNewDimsetID(SalesLine, NewParentDimSetID, OldParentDimSetID);
                NewDimSetID := DimMgt.GetDeltaDimSetID(SalesLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                OnUpdateAllLineDimOnAfterGetSalesLineNewDimsetID(Rec, xRec, SalesLine, NewDimSetID, NewParentDimSetID, OldParentDimSetID);
                if SalesLine."Dimension Set ID" <> NewDimSetID then begin
                    SalesLine."Dimension Set ID" := NewDimSetID;

                    if not GetHideValidationDialog and GuiAllowed then
                        VerifyShippedReceivedItemLineDimChange(ShippedReceivedItemLineDimChangeConfirmed);

                    DimMgt.UpdateGlobalDimFromDimSetID(
                      SalesLine."Dimension Set ID", SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");

                    OnUpdateAllLineDimOnBeforeSalesLineModify(SalesLine);
                    SalesLine.Modify();
                    ATOLink.UpdateAsmDimFromSalesLine(SalesLine);
                end;
            until SalesLine.Next() = 0;
    end;

    local procedure VerifyShippedReceivedItemLineDimChange(var ShippedReceivedItemLineDimChangeConfirmed: Boolean)
    begin
        if SalesLine.IsShippedReceivedItemDimChanged then
            if not ShippedReceivedItemLineDimChangeConfirmed then
                ShippedReceivedItemLineDimChangeConfirmed := SalesLine.ConfirmShippedReceivedItemDimChange;
    end;

    procedure LookupAdjmtValueEntries(QtyType: Option General,Invoicing)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        TempValueEntry: Record "Value Entry" temporary;
    begin
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        TempValueEntry.Reset();
        TempValueEntry.DeleteAll();

        case "Document Type" of
            "Document Type"::Order, "Document Type"::Invoice:
                begin
                    if SalesLine.FindSet then
                        repeat
                            if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine.Quantity <> 0) then
                                with SalesShptLine do begin
                                    if SalesLine."Shipment No." <> '' then begin
                                        SetRange("Document No.", SalesLine."Shipment No.");
                                        SetRange("Line No.", SalesLine."Shipment Line No.");
                                    end else begin
                                        SetCurrentKey("Order No.", "Order Line No.");
                                        SetRange("Order No.", SalesLine."Document No.");
                                        SetRange("Order Line No.", SalesLine."Line No.");
                                    end;
                                    SetRange(Correction, false);
                                    if QtyType = QtyType::Invoicing then
                                        SetFilter("Qty. Shipped Not Invoiced", '<>0');

                                    if FindSet then
                                        repeat
                                            FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                                            if ItemLedgEntry.FindSet then
                                                repeat
                                                    CreateTempAdjmtValueEntries(TempValueEntry, ItemLedgEntry."Entry No.");
                                                until ItemLedgEntry.Next() = 0;
                                        until Next() = 0;
                                end;
                        until SalesLine.Next() = 0;
                end;
            "Document Type"::"Return Order", "Document Type"::"Credit Memo":
                begin
                    if SalesLine.FindSet then
                        repeat
                            if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine.Quantity <> 0) then
                                with ReturnRcptLine do begin
                                    if SalesLine."Return Receipt No." <> '' then begin
                                        SetRange("Document No.", SalesLine."Return Receipt No.");
                                        SetRange("Line No.", SalesLine."Return Receipt Line No.");
                                    end else begin
                                        SetCurrentKey("Return Order No.", "Return Order Line No.");
                                        SetRange("Return Order No.", SalesLine."Document No.");
                                        SetRange("Return Order Line No.", SalesLine."Line No.");
                                    end;
                                    SetRange(Correction, false);
                                    if QtyType = QtyType::Invoicing then
                                        SetFilter("Return Qty. Rcd. Not Invd.", '<>0');

                                    if FindSet then
                                        repeat
                                            FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                                            if ItemLedgEntry.FindSet then
                                                repeat
                                                    CreateTempAdjmtValueEntries(TempValueEntry, ItemLedgEntry."Entry No.");
                                                until ItemLedgEntry.Next() = 0;
                                        until Next() = 0;
                                end;
                        until SalesLine.Next() = 0;
                end;
        end;
        PAGE.RunModal(0, TempValueEntry);
    end;

    procedure GetCustomerVATRegistrationNumber() ReturnValue: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustomerVATRegistrationNumber(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        exit("VAT Registration No.");
    end;

    procedure GetCustomerVATRegistrationNumberLbl() ReturnValue: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustomerVATRegistrationNumberLbl(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

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

    procedure GetStatusStyleText() StatusStyleText: Text
    begin
        if Status = Status::Open then
            StatusStyleText := 'Favorable'
        else
            StatusStyleText := 'Strong';

        OnAfterGetStatusStyleText(Rec, StatusStyleText);
    end;

    local procedure CreateTempAdjmtValueEntries(var TempValueEntry: Record "Value Entry" temporary; ItemLedgEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        with ValueEntry do begin
            SetCurrentKey("Item Ledger Entry No.");
            SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
            if FindSet then
                repeat
                    if Adjustment then begin
                        TempValueEntry := ValueEntry;
                        if TempValueEntry.Insert() then;
                    end;
                until Next() = 0;
        end;
    end;

    procedure GetPstdDocLinesToReverse()
    var
        SalesPostedDocLines: Page "Posted Sales Document Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPstdDocLinesToReverse(Rec, IsHandled);
        if IsHandled then
            exit;

        GetCust("Sell-to Customer No.");
        SalesPostedDocLines.SetToSalesHeader(Rec);
        SalesPostedDocLines.SetRecord(Cust);
        SalesPostedDocLines.LookupMode := true;
        if SalesPostedDocLines.RunModal = ACTION::LookupOK then
            SalesPostedDocLines.CopyLineToDoc;

        Clear(SalesPostedDocLines);
    end;

    procedure CalcInvDiscForHeader()
    var
        SalesInvDisc: Codeunit "Sales-Calc. Discount";
    begin
        OnBeforeCalcInvDiscForHeader(Rec);

        GetSalesSetup;
        if SalesSetup."Calc. Inv. Discount" then
            SalesInvDisc.CalculateIncDiscForHeader(Rec);
    end;

    procedure SetSecurityFilterOnRespCenter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if (not IsHandled) and (UserSetupMgt.GetSalesFilter <> '') then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetSalesFilter);
            FilterGroup(0);
        end;

        SetRange("Date Filter", 0D, WorkDate());
    end;

    local procedure SynchronizeForReservations(var NewSalesLine: Record "Sales Line"; OldSalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSynchronizeForReservations(Rec, NewSalesLine, OldSalesLine, IsHandled);
        if IsHandled then
            exit;

        NewSalesLine.CalcFields("Reserved Quantity");
        if NewSalesLine."Reserved Quantity" = 0 then
            exit;
        if NewSalesLine."Location Code" <> OldSalesLine."Location Code" then
            NewSalesLine.Validate("Location Code", OldSalesLine."Location Code");
        if NewSalesLine."Bin Code" <> OldSalesLine."Bin Code" then
            NewSalesLine.Validate("Bin Code", OldSalesLine."Bin Code");
        if NewSalesLine.Modify then;
    end;

    procedure InventoryPickConflict(DocType: Enum "Sales Document Type"; DocNo: Code[20]; ShippingAdvice: Enum "Sales Header Shipping Advice"): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesLine: Record "Sales Line";
    begin
        if ShippingAdvice <> ShippingAdvice::Complete then
            exit(false);
        WarehouseActivityLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseActivityLine.SetRange("Source Subtype", DocType);
        WarehouseActivityLine.SetRange("Source No.", DocNo);
        if WarehouseActivityLine.IsEmpty() then
            exit(false);
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.IsEmpty() then
            exit(false);
        exit(true);
    end;

#if not CLEAN17
    [Obsolete('Replaced by WhseShipmentConflict().', '17.0')]
    procedure WhseShpmntConflict(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]; ShippingAdvice: Option Partial,Complete): Boolean
    begin
        exit(WhseShipmentConflict("Sales Document Type".FromInteger(DocType), DocNo, "Sales Header Shipping Advice".FromInteger(ShippingAdvice)));
    end;
#endif

    procedure WhseShipmentConflict(DocType: Enum "Sales Document Type"; DocNo: Code[20]; ShippingAdvice: Enum "Sales Header Shipping Advice"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if ShippingAdvice <> ShippingAdvice::Complete then
            exit(false);
        WarehouseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", DocType);
        WarehouseShipmentLine.SetRange("Source No.", DocNo);
        if WarehouseShipmentLine.IsEmpty() then
            exit(false);
        exit(true);
    end;

    local procedure CheckCreditLimit()
    var
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        SalesHeader := Rec;

        if GuiAllowed and
           (CurrFieldNo <> 0) and CheckCreditLimitCondition and SalesHeader.Find
        then begin
            "Amount Including VAT" := 0;
            if "Document Type" = "Document Type"::Order then
                if BilltoCustomerNoChanged then begin
                    SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.CalcSums("Outstanding Amount", "Shipped Not Invoiced");
                    "Amount Including VAT" := SalesLine."Outstanding Amount" + SalesLine."Shipped Not Invoiced";
                end;

            IsHandled := false;
            OnBeforeCheckCreditLimit(Rec, IsHandled);
            if not IsHandled then
                CustCheckCreditLimit.SalesHeaderCheck(Rec);

            CalcFields("Amount Including VAT");
        end;
    end;

    local procedure CheckCreditLimitCondition(): Boolean
    var
        RunCheck: Boolean;
    begin
        RunCheck := ("Document Type".AsInteger() <= "Document Type"::Invoice.AsInteger()) or ("Document Type" = "Document Type"::"Blanket Order");
        OnAfterCheckCreditLimitCondition(Rec, RunCheck);
        exit(RunCheck);
    end;

    procedure CheckItemAvailabilityInLines()
    var
        SalesLine: Record "Sales Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        OnCheckItemAvailabilityInLinesOnAfterSetFilters(SalesLine);
        if SalesLine.FindSet() then
            repeat
                if ItemCheckAvail.SalesLineCheck(SalesLine) then
                    ItemCheckAvail.RaiseUpdateInterruptedError();
            until SalesLine.Next() = 0;
    end;

    procedure QtyToShipIsZero() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeQtyToShipIsZero(Rec, SalesLine, Result, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetFilter("Qty. to Ship", '<>0');
        Result := SalesLine.IsEmpty();
    end;

    procedure IsApprovedForPosting() Approved: Boolean
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then begin
            if PrepaymentMgt.TestSalesPrepayment(Rec) then
                Error(PrepaymentInvoicesNotPaidErr, "Document Type", "No.");
            if "Document Type" = "Document Type"::Order then
                if PrepaymentMgt.TestSalesPayment(Rec) then
                    Error(Text072, "Document Type", "No.");
            Approved := true;
            OnAfterIsApprovedForPosting(Rec, Approved);
        end;
    end;

    procedure IsApprovedForPostingBatch() Approved: Boolean
    begin
        Approved := ApprovedForPostingBatch;
        OnAfterIsApprovedForPostingBatch(Rec, Approved);
    end;

    [TryFunction]
    local procedure ApprovedForPostingBatch()
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then begin
            if PrepaymentMgt.TestSalesPrepayment(Rec) then
                Error(PrepaymentInvoicesNotPaidErr, "Document Type", "No.");
            if PrepaymentMgt.TestSalesPayment(Rec) then
                Error(Text072, "Document Type", "No.");
        end;
    end;

    procedure GetLegalStatement(): Text
    begin
        GetSalesSetup;
        exit(SalesSetup.GetLegalStatement);
    end;

    procedure SendToPosting(PostingCodeunitID: Integer) IsSuccess: Boolean
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        if not IsApprovedForPosting then
            exit;

        Commit();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, '');
        IsSuccess := CODEUNIT.Run(PostingCodeunitID, Rec);
        if not IsSuccess then
            ErrorMessageHandler.ShowErrors;
    end;

    procedure CancelBackgroundPosting()
    var
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
    begin
        SalesPostViaJobQueue.CancelQueueEntry(Rec);
    end;

    [Scope('Cloud')]
    procedure EmailRecords(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
    begin
        case "Document Type" of
            "Document Type"::Quote:
                begin
                    DocumentSendingProfile.TrySendToEMail(
                      DummyReportSelections.Usage::"S.Quote".AsInteger(), Rec, FieldNo("No."),
                      GetDocTypeTxt, FieldNo("Bill-to Customer No."), ShowDialog);
                    Find;
                    "Quote Sent to Customer" := CurrentDateTime;
                    Modify;
                end;
            "Document Type"::Invoice:
                DocumentSendingProfile.TrySendToEMail(
                  DummyReportSelections.Usage::"S.Invoice Draft".AsInteger(), Rec, FieldNo("No."),
                  GetDocTypeTxt, FieldNo("Bill-to Customer No."), ShowDialog);
        end;

        OnAfterSendSalesHeader(Rec, ShowDialog);
    end;

    procedure GetDocTypeTxt() TypeText: Text[50]
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        TypeText := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        if "Document Type" = "Document Type"::Quote then
            if EnvInfoProxy.IsInvoicing then
                TypeText := EstimateTxt;

        OnAfterGetDocTypeText(Rec, TypeText);
    end;

    procedure GetFullDocTypeTxt() FullDocTypeTxt: Text
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetFullDocTypeTxt(Rec, FullDocTypeTxt, IsHandled);

        if IsHandled then
            exit;

        FullDocTypeTxt := SelectStr("Document Type".AsInteger() + 1, FullSalesTypesTxt);
    end;

    procedure LinkSalesDocWithOpportunity(OldOpportunityNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        Opportunity: Record Opportunity;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if "Opportunity No." <> OldOpportunityNo then begin
            if "Opportunity No." <> '' then
                if Opportunity.Get("Opportunity No.") then begin
                    Opportunity.TestField(Status, Opportunity.Status::"In Progress");
                    if Opportunity."Sales Document No." <> '' then begin
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text048, Opportunity."Sales Document No.", Opportunity."No."), true)
                        then begin
                            if SalesHeader.Get("Document Type"::Quote, Opportunity."Sales Document No.") then begin
                                SalesHeader."Opportunity No." := '';
                                OnLinkSalesDocWithOpportunityOnBeforeSalesHeaderModify(Rec, OldOpportunityNo, Opportunity);
                                SalesHeader.Modify();
                            end;
                            UpdateOpportunityLink(Opportunity, Opportunity."Sales Document Type"::Quote, "No.");
                        end else
                            "Opportunity No." := OldOpportunityNo;
                    end else
                        UpdateOpportunityLink(Opportunity, Opportunity."Sales Document Type"::Quote, "No.");
                end;
            if (OldOpportunityNo <> '') and Opportunity.Get(OldOpportunityNo) then
                UpdateOpportunityLink(Opportunity, Opportunity."Sales Document Type"::" ", '');
        end;
    end;

    local procedure UpdateOpportunityLink(Opportunity: Record Opportunity; SalesDocumentType: Option; SalesHeaderNo: Code[20])
    begin
        Opportunity."Sales Document Type" := SalesDocumentType;
        Opportunity."Sales Document No." := SalesHeaderNo;
        OnUpdateOpportunityLinkOnBeforeModify(Opportunity, Rec, SalesDocumentType, SalesHeaderNo);
        Opportunity.Modify();
    end;

    procedure SynchronizeAsmHeader()
    var
        AsmHeader: Record "Assembly Header";
        ATOLink: Record "Assemble-to-Order Link";
        Window: Dialog;
    begin
        ATOLink.SetCurrentKey(Type, "Document Type", "Document No.");
        ATOLink.SetRange(Type, ATOLink.Type::Sale);
        ATOLink.SetRange("Document Type", "Document Type");
        ATOLink.SetRange("Document No.", "No.");
        if ATOLink.FindSet then
            repeat
                if AsmHeader.Get(ATOLink."Assembly Document Type", ATOLink."Assembly Document No.") then
                    if "Posting Date" <> AsmHeader."Posting Date" then begin
                        Window.Open(StrSubstNo(SynchronizingMsg, "No.", AsmHeader."No."));
                        AsmHeader.Validate("Posting Date", "Posting Date");
                        AsmHeader.Modify();
                        Window.Close;
                    end;
            until ATOLink.Next() = 0;
    end;

    procedure CheckShippingAdvice()
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        QtyToShipBaseTotal: Decimal;
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShippingAdvice(Rec, IsHandled);
        if IsHandled then
            exit;

        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetRange("Drop Shipment", false);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        Result := true;
        if SalesLine.FindSet then
            repeat
                Item.Get(SalesLine."No.");
                if SalesLine.IsShipment and (Item.Type = Item.Type::Inventory) then begin
                    QtyToShipBaseTotal += SalesLine."Qty. to Ship (Base)";
                    if SalesLine."Quantity (Base)" <>
                       SalesLine."Qty. to Ship (Base)" + SalesLine."Qty. Shipped (Base)"
                    then
                        Result := false;
                end;
            until SalesLine.Next() = 0;
        if QtyToShipBaseTotal = 0 then
            Result := true;

        OnAfterCheckShippingAdvice(Rec, Result);
        if not Result then
            Error(ShippingAdviceErr);
    end;

    local procedure GetContactAsCompany(Contact: Record Contact; var SearchContact: Record Contact): Boolean;
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetContactAsCompany(Contact, SearchContact, IsHandled);
        if not IsHandled then
            if Contact."Company No." <> '' then
                exit(SearchContact.Get(Contact."Company No."));
    end;

    local procedure GetFilterCustNo(): Code[20]
    var
        MinValue: Code[20];
        MaxValue: Code[20];
    begin
        if GetFilter("Sell-to Customer No.") <> '' then begin
            if TryGetFilterCustNoRange(MinValue, MaxValue) then
                if MinValue = MaxValue then
                    exit(MaxValue);
        end;
    end;

    [TryFunction]
    local procedure TryGetFilterCustNoRange(var MinValue: Code[20]; var MaxValue: Code[20])
    begin
        MinValue := GetRangeMin("Sell-to Customer No.");
        MaxValue := GetRangeMax("Sell-to Customer No.");
    end;

    local procedure GetFilterCustNoByApplyingFilter(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        MinValue: Code[20];
        MaxValue: Code[20];
    begin
        if GetFilter("Sell-to Customer No.") <> '' then begin
            SalesHeader.CopyFilters(Rec);
            SalesHeader.SetCurrentKey("Sell-to Customer No.");
            if SalesHeader.FindFirst then
                MinValue := SalesHeader."Sell-to Customer No.";
            if SalesHeader.FindLast then
                MaxValue := SalesHeader."Sell-to Customer No.";
            if MinValue = MaxValue then
                exit(MaxValue);
        end;
    end;

    local procedure GetFilterContNo(): Code[20]
    begin
        if GetFilter("Sell-to Contact No.") <> '' then
            if GetRangeMin("Sell-to Contact No.") = GetRangeMax("Sell-to Contact No.") then
                exit(GetRangeMax("Sell-to Contact No."));
    end;

    local procedure CheckCreditLimitIfLineNotInsertedYet()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCreditLimitIfLineNotInsertedYet(Rec, IsHandled);
        if IsHandled then
            exit;

        if "No." = '' then begin
            HideCreditCheckDialogue := false;
            CheckCreditMaxBeforeInsert;
            HideCreditCheckDialogue := true;
        end;
    end;

    procedure InvoicedLineExists(): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetFilter("Quantity Invoiced", '<>%1', 0);
        exit(not SalesLine.IsEmpty);
    end;

    procedure CreateDimSetForPrepmtAccDefaultDim()
    var
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetFilter("Prepmt. Amt. Inv.", '<>%1', 0);
        if SalesLine.FindSet then
            repeat
                CollectParamsInBufferForCreateDimSet(TempSalesLine, SalesLine);
            until SalesLine.Next() = 0;
        TempSalesLine.Reset();
        TempSalesLine.MarkedOnly(false);
        if TempSalesLine.FindSet then
            repeat
                SalesLine.CreateDim(DATABASE::"G/L Account", TempSalesLine."No.",
                  DATABASE::Job, TempSalesLine."Job No.",
                  DATABASE::"Responsibility Center", TempSalesLine."Responsibility Center");
            until TempSalesLine.Next() = 0;
    end;

    local procedure CollectParamsInBufferForCreateDimSet(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        DefaultDimension: Record "Default Dimension";
    begin
        TempSalesLine.SetRange("Gen. Bus. Posting Group", SalesLine."Gen. Bus. Posting Group");
        TempSalesLine.SetRange("Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group");
        if not TempSalesLine.FindFirst then begin
            GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
            DefaultDimension.SetRange("Table ID", DATABASE::"G/L Account");
            DefaultDimension.SetRange("No.", GenPostingSetup.GetSalesPrepmtAccount);
            OnCollectParamsInBufferForCreateDimSetOnBeforeInsertTempSalesLineInBuffer(GenPostingSetup, DefaultDimension);
            InsertTempSalesLineInBuffer(TempSalesLine, SalesLine, GenPostingSetup."Sales Prepayments Account", DefaultDimension.IsEmpty);
        end else
            if not TempSalesLine.Mark then begin
                TempSalesLine.SetRange("Job No.", SalesLine."Job No.");
                TempSalesLine.SetRange("Responsibility Center", SalesLine."Responsibility Center");
                OnCollectParamsInBufferForCreateDimSetOnAfterSetTempSalesLineFilters(TempSalesLine, SalesLine);
                if TempSalesLine.IsEmpty() then
                    InsertTempSalesLineInBuffer(TempSalesLine, SalesLine, TempSalesLine."No.", false);
            end;
    end;

    local procedure InsertTempSalesLineInBuffer(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line"; AccountNo: Code[20]; DefaultDimensionsNotExist: Boolean)
    begin
        TempSalesLine.Init();
        TempSalesLine."Line No." := SalesLine."Line No.";
        TempSalesLine."No." := AccountNo;
        TempSalesLine."Job No." := SalesLine."Job No.";
        TempSalesLine."Responsibility Center" := SalesLine."Responsibility Center";
        TempSalesLine."Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        TempSalesLine."Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        TempSalesLine.Mark := DefaultDimensionsNotExist;
        OnInsertTempSalesLineInBufferOnBeforeTempSalesLineInsert(TempSalesLine, SalesLine);
        TempSalesLine.Insert();
    end;

    procedure OpenSalesOrderStatistics()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenSalesOrderStatistics(Rec, IsHandled);
        if IsHandled then
            exit;

        CalcInvDiscForHeader;
        CreateDimSetForPrepmtAccDefaultDim;
        Commit();
        PAGE.RunModal(PAGE::"Sales Order Statistics", Rec);
    end;

    procedure GetCardpageID(): Integer
    begin
        case "Document Type" of
            "Document Type"::Quote:
                exit(PAGE::"Sales Quote");
            "Document Type"::Order:
                exit(PAGE::"Sales Order");
            "Document Type"::Invoice:
                exit(PAGE::"Sales Invoice");
            "Document Type"::"Credit Memo":
                exit(PAGE::"Sales Credit Memo");
            "Document Type"::"Blanket Order":
                exit(PAGE::"Blanket Sales Order");
            "Document Type"::"Return Order":
                exit(PAGE::"Sales Return Order");
        end;
    end;

    procedure CheckAvailableCreditLimit() ReturnValue: Decimal
    var
        Customer: Record Customer;
        AvailableCreditLimit: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAvailableCreditLimit(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if ("Bill-to Customer No." = '') and ("Sell-to Customer No." = '') then
            exit(0);

        if not Customer.Get("Bill-to Customer No.") then
            Customer.Get("Sell-to Customer No.");

        AvailableCreditLimit := Customer.CalcAvailableCredit;

        if AvailableCreditLimit < 0 then
            CustomerCreditLimitExceeded()
        else
            CustomerCreditLimitNotExceeded();

        exit(AvailableCreditLimit);
    end;

    procedure SetStatus(NewStatus: Option)
    begin
        Status := "Sales Document Status".FromInteger(NewStatus);
        Modify();
    end;

    local procedure TestSalesLineFieldsBeforeRecreate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesLineFieldsBeforeRecreate(Rec, IsHandled, SalesLine);
        if IsHandled then
            exit;

        SalesLine.TestField("Job No.", '');
        SalesLine.TestField("Job Contract Entry No.", 0);
        SalesLine.TestField("Quantity Invoiced", 0);
        SalesLine.TestField("Return Qty. Received", 0);
        SalesLine.TestField("Shipment No.", '');
        SalesLine.TestField("Return Receipt No.", '');
        SalesLine.TestField("Blanket Order No.", '');
        SalesLine.TestField("Prepmt. Amt. Inv.", 0);
        TestQuantityShippedField(SalesLine);
    end;

    local procedure RecreateReservEntryReqLine(var TempSalesLine: Record "Sales Line" temporary; var TempATOLink: Record "Assemble-to-Order Link" temporary; var ATOLink: Record "Assemble-to-Order Link")
    begin
        repeat
            TestSalesLineFieldsBeforeRecreate;
            if (SalesLine."Location Code" <> "Location Code") and (not SalesLine.IsNonInventoriableItem) then
                SalesLine.Validate("Location Code", "Location Code");
            TempSalesLine := SalesLine;
            if SalesLine.Nonstock then begin
                SalesLine.Nonstock := false;
                SalesLine.Modify();
            end;

            if ATOLink.AsmExistsForSalesLine(TempSalesLine) then begin
                TempATOLink := ATOLink;
                TempATOLink.Insert();
                ATOLink.Delete();
            end;

            TempSalesLine.Insert();
            OnAfterInsertTempSalesLine(SalesLine, TempSalesLine);
            SalesLineReserve.CopyReservEntryToTemp(TempReservEntry, SalesLine);
            RecreateReqLine(SalesLine, 0, true);
            OnRecreateReservEntryReqLineOnAfterLoop(Rec, SalesLine);
        until SalesLine.Next() = 0;
    end;

    local procedure TransferItemChargeAssgntSalesToTemp(var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferItemChargeAssgntSalesToTemp(Rec, ItemChargeAssgntSales, TempItemChargeAssgntSales, IsHandled);
        if IsHandled then
            exit;

        ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", "No.");
        if ItemChargeAssgntSales.FindSet then begin
            repeat
                TempItemChargeAssgntSales.Init();
                TempItemChargeAssgntSales := ItemChargeAssgntSales;
                TempItemChargeAssgntSales.Insert();
            until ItemChargeAssgntSales.Next() = 0;
            ItemChargeAssgntSales.DeleteAll();
        end;
    end;

    local procedure CreateSalesLine(var TempSalesLine: Record "Sales Line" temporary)
    var
        IsHandled: Boolean;
    begin
        OnBeforeCreateSalesLine(TempSalesLine, IsHandled, Rec);
        if IsHandled then
            exit;

        SalesLine.Init();
        SalesLine."Line No." := SalesLine."Line No." + 10000;
        SalesLine."Price Calculation Method" := "Price Calculation Method";
        SalesLine.Validate(Type, TempSalesLine.Type);
        OnCreateSalesLineOnAfterAssignType(SalesLine, TempSalesLine);
        if TempSalesLine."No." = '' then begin
            SalesLine.Validate(Description, TempSalesLine.Description);
            SalesLine.Validate("Description 2", TempSalesLine."Description 2");
        end else begin
            SalesLine.Validate("No.", TempSalesLine."No.");
            if SalesLine.Type <> SalesLine.Type::" " then begin
                SalesLine.Validate("Unit of Measure Code", TempSalesLine."Unit of Measure Code");
                SalesLine.Validate("Variant Code", TempSalesLine."Variant Code");
                OnCreateSalesLineOnBeforeValidateQuantity(SalesLine, TempSalesLine);
                if TempSalesLine.Quantity <> 0 then begin
                    SalesLine.Validate(Quantity, TempSalesLine.Quantity);
                    SalesLine.Validate("Qty. to Assemble to Order", TempSalesLine."Qty. to Assemble to Order");
                end;
                SalesLine."Purchase Order No." := TempSalesLine."Purchase Order No.";
                SalesLine."Purch. Order Line No." := TempSalesLine."Purch. Order Line No.";
                SalesLine."Drop Shipment" := TempSalesLine."Drop Shipment";
            end;
            SalesLine.Validate("Shipment Date", TempSalesLine."Shipment Date");
        end;
        OnBeforeSalesLineInsert(SalesLine, TempSalesLine, Rec);
        SalesLine.Insert();
        OnAfterCreateSalesLine(SalesLine, TempSalesLine);
    end;

    local procedure CreateItemChargeAssgntSales(var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; var TempSalesLine: Record "Sales Line" temporary; var TempInteger: Record "Integer" temporary)
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
        TempSalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        if TempSalesLine.FindSet then
            repeat
                TempItemChargeAssgntSales.SetRange("Document Line No.", TempSalesLine."Line No.");
                if TempItemChargeAssgntSales.FindSet then begin
                    repeat
                        TempInteger.FindFirst;
                        ItemChargeAssgntSales.Init();
                        ItemChargeAssgntSales := TempItemChargeAssgntSales;
                        ItemChargeAssgntSales."Document Line No." := TempInteger.Number;
                        ItemChargeAssgntSales.Validate("Unit Cost", 0);
                        ItemChargeAssgntSales.Insert();
                    until TempItemChargeAssgntSales.Next() = 0;
                    TempInteger.Delete();
                end;
            until TempSalesLine.Next() = 0;

        ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
        TempItemChargeAssgntSales.DeleteAll();
    end;

    local procedure UpdateOutboundWhseHandlingTime()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOutboundWhseHandlingTime(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Location Code" <> '' then begin
            if Location.Get("Location Code") then
                "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
        end else
            if InvtSetup.Get then
                "Outbound Whse. Handling Time" := InvtSetup."Outbound Whse. Handling Time";
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnCheckSalesPostRestrictions()
    begin
    end;

    procedure CheckSalesPostRestrictions()
    begin
        OnCheckSalesPostRestrictions();
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnCustomerCreditLimitExceeded(NotificationId: Guid)
    begin
    end;

    procedure CustomerCreditLimitExceeded()
    var
        NotificationId: Guid;
    begin
        OnCustomerCreditLimitExceeded(NotificationId);
    end;

    procedure CustomerCreditLimitExceeded(NotificationId: Guid)
    begin
        OnCustomerCreditLimitExceeded(NotificationId);
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnCustomerCreditLimitNotExceeded()
    begin
    end;

    procedure CustomerCreditLimitNotExceeded()
    begin
        OnCustomerCreditLimitNotExceeded();
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnCheckSalesReleaseRestrictions()
    begin
    end;

    procedure CheckSalesReleaseRestrictions()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OnCheckSalesReleaseRestrictions;
        ApprovalsMgmt.PrePostApprovalCheckSales(Rec);
    end;

    procedure DeferralHeadersExist(): Boolean
    var
        DeferralHeader: Record "Deferral Header";
    begin
        DeferralHeader.SetRange("Deferral Doc. Type", "Deferral Document Type"::Sales);
        DeferralHeader.SetRange("Gen. Jnl. Template Name", '');
        DeferralHeader.SetRange("Gen. Jnl. Batch Name", '');
        DeferralHeader.SetRange("Document Type", "Document Type");
        DeferralHeader.SetRange("Document No.", "No.");
        exit(not DeferralHeader.IsEmpty);
    end;

    procedure SetSellToCustomerFromFilter()
    var
        SellToCustomerNo: Code[20];
    begin
        SellToCustomerNo := GetFilterCustNo;
        if SellToCustomerNo = '' then begin
            FilterGroup(2);
            SellToCustomerNo := GetFilterCustNo;
            if SellToCustomerNo = '' then
                SellToCustomerNo := GetFilterCustNoByApplyingFilter;
            FilterGroup(0);
        end;
        if SellToCustomerNo <> '' then
            Validate("Sell-to Customer No.", SellToCustomerNo);

        OnAfterSetSellToCustomerFromFilter(Rec);
    end;

    procedure CopySellToCustomerFilter()
    var
        SellToCustomerFilter: Text;
    begin
        SellToCustomerFilter := GetFilter("Sell-to Customer No.");
        if SellToCustomerFilter <> '' then begin
            FilterGroup(2);
            SetFilter("Sell-to Customer No.", SellToCustomerFilter);
            FilterGroup(0)
        end;
    end;

    local procedure ConfirmUpdateDeferralDate()
    begin
        if GetHideValidationDialog or not GuiAllowed then
            Confirmed := true
        else
            Confirmed := Confirm(DeferralLineQst, false);
        if Confirmed then
            UpdateSalesLinesByFieldNo(SalesLine.FieldNo("Deferral Code"), false);
    end;

    procedure BatchConfirmUpdateDeferralDate(var BatchConfirm: Option " ",Skip,Update; ReplacePostingDate: Boolean; PostingDateReq: Date)
    begin
        if (not ReplacePostingDate) or (PostingDateReq = "Posting Date") or (BatchConfirm = BatchConfirm::Skip) then
            exit;

        if not DeferralHeadersExist then
            exit;

        "Posting Date" := PostingDateReq;
        case BatchConfirm of
            BatchConfirm::" ":
                begin
                    ConfirmUpdateDeferralDate;
                    if Confirmed then
                        BatchConfirm := BatchConfirm::Update
                    else
                        BatchConfirm := BatchConfirm::Skip;
                end;
            BatchConfirm::Update:
                UpdateSalesLinesByFieldNo(SalesLine.FieldNo("Deferral Code"), false);
        end;
        Commit();
    end;

    procedure GetSelectedPaymentServicesText(): Text
    var
        PaymentServiceSetup: Record "Payment Service Setup";
    begin
        exit(PaymentServiceSetup.GetSelectedPaymentsText("Payment Service Set ID"));
    end;

    procedure SetDefaultPaymentServices()
    var
        PaymentServiceSetup: Record "Payment Service Setup";
        SetID: Integer;
    begin
        if not PaymentServiceSetup.CanChangePaymentService(Rec) then
            exit;

        if PaymentServiceSetup.GetDefaultPaymentServices(SetID) then
            Validate("Payment Service Set ID", SetID);
    end;

    procedure ChangePaymentServiceSetting()
    var
        PaymentServiceSetup: Record "Payment Service Setup";
        SetID: Integer;
    begin
        SetID := "Payment Service Set ID";
        if PaymentServiceSetup.SelectPaymentService(SetID) then begin
            Validate("Payment Service Set ID", SetID);
            Modify(true);
        end;
    end;

    procedure IsCreditDocType() CreditDocType: Boolean
    begin
        CreditDocType := "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"];
        OnBeforeIsCreditDocType(Rec, CreditDocType);
    end;

    procedure HasSellToAddress(): Boolean
    begin
        case true of
            "Sell-to Address" <> '':
                exit(true);
            "Sell-to Address 2" <> '':
                exit(true);
            "Sell-to City" <> '':
                exit(true);
            "Sell-to Country/Region Code" <> '':
                exit(true);
            "Sell-to County" <> '':
                exit(true);
            "Sell-to Post Code" <> '':
                exit(true);
            "Sell-to Contact" <> '':
                exit(true);
        end;

        exit(false);
    end;

    procedure HasShipToAddress(): Boolean
    begin
        case true of
            "Ship-to Address" <> '':
                exit(true);
            "Ship-to Address 2" <> '':
                exit(true);
            "Ship-to City" <> '':
                exit(true);
            "Ship-to Country/Region Code" <> '':
                exit(true);
            "Ship-to County" <> '':
                exit(true);
            "Ship-to Post Code" <> '':
                exit(true);
            "Ship-to Contact" <> '':
                exit(true);
        end;

        exit(false);
    end;

    procedure HasBillToAddress(): Boolean
    begin
        case true of
            "Bill-to Address" <> '':
                exit(true);
            "Bill-to Address 2" <> '':
                exit(true);
            "Bill-to City" <> '':
                exit(true);
            "Bill-to Country/Region Code" <> '':
                exit(true);
            "Bill-to County" <> '':
                exit(true);
            "Bill-to Post Code" <> '':
                exit(true);
            "Bill-to Contact" <> '':
                exit(true);
        end;

        exit(false);
    end;

    local procedure HasItemChargeAssignment(): Boolean
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", "No.");
        ItemChargeAssgntSales.SetFilter("Amount to Assign", '<>%1', 0);
        exit(not ItemChargeAssgntSales.IsEmpty);
    end;

    local procedure CopySellToCustomerAddressFieldsFromCustomer(var SellToCustomer: Record Customer)
    begin
#if not CLEAN18
        "Sell-to Customer Template Code" := '';
#endif
        "Sell-to Customer Templ. Code" := '';
        "Sell-to Customer Name" := Cust.Name;
        "Sell-to Customer Name 2" := Cust."Name 2";
        "Sell-to Phone No." := Cust."Phone No.";
        "Sell-to E-Mail" := Cust."E-Mail";
        if SellToCustomerIsReplaced or ShouldCopyAddressFromSellToCustomer(SellToCustomer) then begin
            "Sell-to Address" := SellToCustomer.Address;
            "Sell-to Address 2" := SellToCustomer."Address 2";
            "Sell-to City" := SellToCustomer.City;
            "Sell-to Post Code" := SellToCustomer."Post Code";
            "Sell-to County" := SellToCustomer.County;
            "Sell-to Country/Region Code" := SellToCustomer."Country/Region Code";
        end;
        if not SkipSellToContact then
            "Sell-to Contact" := SellToCustomer.Contact;
        "Gen. Bus. Posting Group" := SellToCustomer."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := SellToCustomer."VAT Bus. Posting Group";
        "Tax Area Code" := SellToCustomer."Tax Area Code";
        "Tax Liable" := SellToCustomer."Tax Liable";
        "VAT Registration No." := SellToCustomer."VAT Registration No.";
        "VAT Country/Region Code" := SellToCustomer."Country/Region Code";
        "Shipping Advice" := SellToCustomer."Shipping Advice";
        "Responsibility Center" := UserSetupMgt.GetRespCenter(0, SellToCustomer."Responsibility Center");
        OnCopySelltoCustomerAddressFieldsFromCustomerOnAfterAssignRespCenter(Rec, SellToCustomer, CurrFieldNo);
        UpdateLocationCode(SellToCustomer."Location Code");

        OnAfterCopySellToCustomerAddressFieldsFromCustomer(Rec, SellToCustomer, CurrFieldNo, SkipBillToContact);
    end;

    procedure CopyShipToCustomerAddressFieldsFromCust(var SellToCustomer: Record Customer)
    var
        CustomerTempl: Record "Customer Templ.";
#if not CLEAN18
        SellToCustTemplate: Record "Customer Template";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyShipToCustomerAddressFieldsFromCustomer(Rec, SellToCustomer, IsHandled);
        if IsHandled then
            exit;

        "Ship-to Name" := Cust.Name;
        "Ship-to Name 2" := Cust."Name 2";
        if SellToCustomerIsReplaced or ShipToAddressEqualsOldSellToAddress then begin
            "Ship-to Address" := SellToCustomer.Address;
            "Ship-to Address 2" := SellToCustomer."Address 2";
            "Ship-to City" := SellToCustomer.City;
            "Ship-to Post Code" := SellToCustomer."Post Code";
            "Ship-to County" := SellToCustomer.County;
            Validate("Ship-to Country/Region Code", SellToCustomer."Country/Region Code");
        end;
        "Ship-to Contact" := Cust.Contact;
#if not CLEAN18
        if not CustomerTemplMgt.IsEnabled() then begin
            if not SellToCustTemplate.Get("Sell-to Customer Template Code") then begin
                "Tax Area Code" := Cust."Tax Area Code";
                "Tax Liable" := Cust."Tax Liable";
            end;
        end else
#endif
            if not CustomerTempl.Get("Sell-to Customer Templ. Code") then begin
                "Tax Area Code" := Cust."Tax Area Code";
                "Tax Liable" := Cust."Tax Liable";
            end;
        SetCustomerLocationCode();
        "Shipping Agent Code" := Cust."Shipping Agent Code";
        "Shipping Agent Service Code" := Cust."Shipping Agent Service Code";

        OnAfterCopyShipToCustomerAddressFieldsFromCustomer(Rec, SellToCustomer);
    end;

    local procedure SetCustomerLocationCode()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCustomerLocationCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if Cust."Location Code" <> '' then
            Validate("Location Code", Cust."Location Code");
    end;

    procedure SetShipToCustomerAddressFieldsFromShipToAddr(ShipToAddr: Record "Ship-to Address")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyShipToCustomerAddressFieldsFromShipToAddr(Rec, ShipToAddr, IsHandled);
        if IsHandled then
            exit;

        "Ship-to Name" := ShipToAddr.Name;
        "Ship-to Name 2" := ShipToAddr."Name 2";
        "Ship-to Address" := ShipToAddr.Address;
        "Ship-to Address 2" := ShipToAddr."Address 2";
        "Ship-to City" := ShipToAddr.City;
        "Ship-to Post Code" := ShipToAddr."Post Code";
        "Ship-to County" := ShipToAddr.County;
        Validate("Ship-to Country/Region Code", ShipToAddr."Country/Region Code");
        "Ship-to Contact" := ShipToAddr.Contact;
        if ShipToAddr."Location Code" <> '' then
            Validate("Location Code", ShipToAddr."Location Code");
        "Shipping Agent Code" := ShipToAddr."Shipping Agent Code";
        "Shipping Agent Service Code" := ShipToAddr."Shipping Agent Service Code";
        if ShipToAddr."Tax Area Code" <> '' then
            "Tax Area Code" := ShipToAddr."Tax Area Code";
        "Tax Liable" := ShipToAddr."Tax Liable";

        OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr(Rec, ShipToAddr);
    end;

    procedure SetBillToCustomerAddressFieldsFromCustomer(var BillToCustomer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetBillToCustomerAddressFieldsFromCustomer(Rec, BillToCustomer, SkipBillToContact, IsHandled, xRec, GLSetup);
        if IsHandled then
            exit;

#if not CLEAN18
        "Bill-to Customer Template Code" := '';
#endif
        "Bill-to Customer Templ. Code" := '';
        "Bill-to Name" := BillToCustomer.Name;
        "Bill-to Name 2" := BillToCustomer."Name 2";
        if BillToCustomerIsReplaced or ShouldCopyAddressFromBillToCustomer(BillToCustomer) then begin
            "Bill-to Address" := BillToCustomer.Address;
            "Bill-to Address 2" := BillToCustomer."Address 2";
            "Bill-to City" := BillToCustomer.City;
            "Bill-to Post Code" := BillToCustomer."Post Code";
            "Bill-to County" := BillToCustomer.County;
            "Bill-to Country/Region Code" := BillToCustomer."Country/Region Code";
        end;
        if not SkipBillToContact then
            "Bill-to Contact" := BillToCustomer.Contact;
        "Payment Terms Code" := BillToCustomer."Payment Terms Code";
        "Prepmt. Payment Terms Code" := BillToCustomer."Payment Terms Code";

        if "Document Type" in ["Document Type"::"Credit Memo", "Document Type"::"Return Order"] then begin
            "Payment Method Code" := '';
            if PaymentTerms.Get("Payment Terms Code") then
                if PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then
                    "Payment Method Code" := BillToCustomer."Payment Method Code"
        end else
            "Payment Method Code" := BillToCustomer."Payment Method Code";

        GLSetup.Get();
        if GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." then begin
            "VAT Bus. Posting Group" := BillToCustomer."VAT Bus. Posting Group";
            "VAT Country/Region Code" := BillToCustomer."Country/Region Code";
            "VAT Registration No." := BillToCustomer."VAT Registration No.";
            "Gen. Bus. Posting Group" := BillToCustomer."Gen. Bus. Posting Group";
        end;
        "Customer Posting Group" := BillToCustomer."Customer Posting Group";
        "Currency Code" := BillToCustomer."Currency Code";
        "Customer Price Group" := BillToCustomer."Customer Price Group";
        "Prices Including VAT" := BillToCustomer."Prices Including VAT";
        "Price Calculation Method" := Cust.GetPriceCalculationMethod();
        "Allow Line Disc." := BillToCustomer."Allow Line Disc.";
        "Invoice Disc. Code" := BillToCustomer."Invoice Disc. Code";
        "Customer Disc. Group" := BillToCustomer."Customer Disc. Group";
        "Language Code" := BillToCustomer."Language Code";
        SetSalespersonCode(BillToCustomer."Salesperson Code", "Salesperson Code");
        "Combine Shipments" := BillToCustomer."Combine Shipments";
        Reserve := BillToCustomer.Reserve;
        if "Document Type" = "Document Type"::Order then
            "Prepayment %" := BillToCustomer."Prepayment %";
        "Tax Area Code" := BillToCustomer."Tax Area Code";
        if ("Ship-to Code" = '') or ("Sell-to Customer No." <> BillToCustomer."No.") then
            "Tax Liable" := BillToCustomer."Tax Liable";

        OnAfterSetFieldsBilltoCustomer(Rec, BillToCustomer, xRec);
    end;

    procedure SetShipToAddress(ShipToName: Text[100]; ShipToName2: Text[50]; ShipToAddress: Text[100]; ShipToAddress2: Text[50]; ShipToCity: Text[30]; ShipToPostCode: Code[20]; ShipToCounty: Text[30]; ShipToCountryRegionCode: Code[10])
    begin
        "Ship-to Name" := ShipToName;
        "Ship-to Name 2" := ShipToName2;
        "Ship-to Address" := ShipToAddress;
        "Ship-to Address 2" := ShipToAddress2;
        "Ship-to City" := ShipToCity;
        "Ship-to Post Code" := ShipToPostCode;
        "Ship-to County" := ShipToCounty;
        "Ship-to Country/Region Code" := ShipToCountryRegionCode;
    end;

    local procedure ShouldCopyAddressFromSellToCustomer(SellToCustomer: Record Customer): Boolean
    begin
        exit((not HasSellToAddress) and SellToCustomer.HasAddress);
    end;

    local procedure ShouldCopyAddressFromBillToCustomer(BillToCustomer: Record Customer): Boolean
    begin
        exit((not HasBillToAddress) and BillToCustomer.HasAddress);
    end;

    local procedure SellToCustomerIsReplaced(): Boolean
    begin
        exit((xRec."Sell-to Customer No." <> '') and (xRec."Sell-to Customer No." <> "Sell-to Customer No."));
    end;

    local procedure BillToCustomerIsReplaced(): Boolean
    begin
        exit((xRec."Bill-to Customer No." <> '') and (xRec."Bill-to Customer No." <> "Bill-to Customer No."));
    end;

    local procedure UpdateShipToAddressFromSellToAddress(FieldNumber: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShipToAddressFromSellToAddress(Rec, FieldNumber, IsHandled);
        if IsHandled then
            exit;

        if ("Ship-to Code" = '') and ShipToAddressEqualsOldSellToAddress then
            case FieldNumber of
                FieldNo("Ship-to Address"):
                    "Ship-to Address" := "Sell-to Address";
                FieldNo("Ship-to Address 2"):
                    "Ship-to Address 2" := "Sell-to Address 2";
                FieldNo("Ship-to City"), FieldNo("Ship-to Post Code"):
                    begin
                        "Ship-to City" := "Sell-to City";
                        "Ship-to Post Code" := "Sell-to Post Code";
                        "Ship-to County" := "Sell-to County";
                        "Ship-to Country/Region Code" := "Sell-to Country/Region Code";
                    end;
                FieldNo("Ship-to County"):
                    "Ship-to County" := "Sell-to County";
                FieldNo("Ship-to Country/Region Code"):
                    "Ship-to Country/Region Code" := "Sell-to Country/Region Code";
            end;

        OnAfterUpdateShipToAddressFromSellToAddress(Rec, xRec, FieldNumber);
    end;

    local procedure ShipToAddressEqualsOldSellToAddress(): Boolean
    begin
        exit(IsShipToAddressEqualToSellToAddress(xRec, Rec));
    end;

    procedure ShipToAddressEqualsSellToAddress(): Boolean
    begin
        exit(IsShipToAddressEqualToSellToAddress(Rec, Rec));
    end;

    local procedure IsShipToAddressEqualToSellToAddress(SalesHeaderWithSellTo: Record "Sales Header"; SalesHeaderWithShipTo: Record "Sales Header"): Boolean
    var
        Result: Boolean;
    begin
        Result :=
          (SalesHeaderWithSellTo."Sell-to Address" = SalesHeaderWithShipTo."Ship-to Address") and
          (SalesHeaderWithSellTo."Sell-to Address 2" = SalesHeaderWithShipTo."Ship-to Address 2") and
          (SalesHeaderWithSellTo."Sell-to City" = SalesHeaderWithShipTo."Ship-to City") and
          (SalesHeaderWithSellTo."Sell-to County" = SalesHeaderWithShipTo."Ship-to County") and
          (SalesHeaderWithSellTo."Sell-to Post Code" = SalesHeaderWithShipTo."Ship-to Post Code") and
          (SalesHeaderWithSellTo."Sell-to Country/Region Code" = SalesHeaderWithShipTo."Ship-to Country/Region Code") and
          (SalesHeaderWithSellTo."Sell-to Contact" = SalesHeaderWithShipTo."Ship-to Contact");

        OnAfterIsShipToAddressEqualToSellToAddress(SalesHeaderWithSellTo, SalesHeaderWithShipTo, Result);
        exit(Result);
    end;

    procedure BillToAddressEqualsSellToAddress(): Boolean
    begin
        exit(IsBillToAddressEqualToSellToAddress(Rec, Rec));
    end;

    local procedure IsBillToAddressEqualToSellToAddress(SalesHeaderWithSellTo: Record "Sales Header"; SalesHeaderWithBillTo: Record "Sales Header"): Boolean
    begin
        if (SalesHeaderWithSellTo."Sell-to Address" = SalesHeaderWithBillTo."Bill-to Address") and
           (SalesHeaderWithSellTo."Sell-to Address 2" = SalesHeaderWithBillTo."Bill-to Address 2") and
           (SalesHeaderWithSellTo."Sell-to City" = SalesHeaderWithBillTo."Bill-to City") and
           (SalesHeaderWithSellTo."Sell-to County" = SalesHeaderWithBillTo."Bill-to County") and
           (SalesHeaderWithSellTo."Sell-to Post Code" = SalesHeaderWithBillTo."Bill-to Post Code") and
           (SalesHeaderWithSellTo."Sell-to Country/Region Code" = SalesHeaderWithBillTo."Bill-to Country/Region Code") and
           (SalesHeaderWithSellTo."Sell-to Contact No." = SalesHeaderWithBillTo."Bill-to Contact No.") and
           (SalesHeaderWithSellTo."Sell-to Contact" = SalesHeaderWithBillTo."Bill-to Contact")
        then
            exit(true);
    end;

    procedure CopySellToAddressToShipToAddress()
    begin
        "Ship-to Address" := "Sell-to Address";
        "Ship-to Address 2" := "Sell-to Address 2";
        "Ship-to City" := "Sell-to City";
        "Ship-to Contact" := "Sell-to Contact";
        "Ship-to Country/Region Code" := "Sell-to Country/Region Code";
        "Ship-to County" := "Sell-to County";
        "Ship-to Post Code" := "Sell-to Post Code";

        OnAfterCopySellToAddressToShipToAddress(Rec);
    end;

    procedure CopySellToAddressToBillToAddress()
    begin
        if "Bill-to Customer No." = "Sell-to Customer No." then begin
            "Bill-to Address" := "Sell-to Address";
            "Bill-to Address 2" := "Sell-to Address 2";
            "Bill-to Post Code" := "Sell-to Post Code";
            "Bill-to Country/Region Code" := "Sell-to Country/Region Code";
            "Bill-to City" := "Sell-to City";
            "Bill-to County" := "Sell-to County";
            OnAfterCopySellToAddressToBillToAddress(Rec);
        end;
    end;

    local procedure UpdateShipToContact()
    var
        IsHandled: Boolean;
    begin
        if not (CurrFieldNo in [FieldNo("Sell-to Contact"), FieldNo("Sell-to Contact No.")]) then
            exit;

        if IsCreditDocType then
            exit;

        IsHandled := FALSE;
        OnUpdateShipToContactOnBeforeValidateShipToContact(Rec, xRec, CurrFieldNo, IsHandled);
        if not IsHandled then
            Validate("Ship-to Contact", "Sell-to Contact");
    end;

    procedure ConfirmCloseUnposted(): Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if SalesLinesExist then
            if InstructionMgt.IsUnpostedEnabledForRecord(Rec) then
                exit(InstructionMgt.ShowConfirm(DocumentNotPostedClosePageQst, InstructionMgt.QueryPostOnCloseCode));
        exit(true)
    end;

    local procedure UpdateOpportunity()
    var
        Opp: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOpportunity(IsHandled);
        if IsHandled then
            exit;

        if not ("Opportunity No." <> '') or not ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) then
            exit;

        if not Opp.Get("Opportunity No.") then
            exit;

        if "Document Type" = "Document Type"::Order then begin
            if not ConfirmManagement.GetResponseOrDefault(Text040, true) then
                Error(Text044);

            OpportunityEntry.SetRange("Opportunity No.", "Opportunity No.");
            OpportunityEntry.ModifyAll(Active, false);

            OpportunityEntry.Init();
            OpportunityEntry.Validate("Opportunity No.", Opp."No.");

            OpportunityEntry.LockTable();
            OpportunityEntry."Entry No." := OpportunityEntry.GetLastEntryNo() + 1;
            OpportunityEntry."Sales Cycle Code" := Opp."Sales Cycle Code";
            OpportunityEntry."Contact No." := Opp."Contact No.";
            OpportunityEntry."Contact Company No." := Opp."Contact Company No.";
            OpportunityEntry."Salesperson Code" := Opp."Salesperson Code";
            OpportunityEntry."Campaign No." := Opp."Campaign No.";
            OpportunityEntry."Action Taken" := OpportunityEntry."Action Taken"::Lost;
            OpportunityEntry.Active := true;
            OpportunityEntry."Completed %" := 100;
            OpportunityEntry."Estimated Value (LCY)" := GetOpportunityEntryEstimatedValue;
            OpportunityEntry."Estimated Close Date" := Opp."Date Closed";
            OpportunityEntry.Insert(true);
        end;
        Opp.Find;
        Opp."Sales Document Type" := Opp."Sales Document Type"::" ";
        Opp."Sales Document No." := '';
        OnUpdateOpportunityOnBeforeModify(Opp, Rec);
        Opp.Modify();
        "Opportunity No." := '';
    end;

    local procedure GetOpportunityEntryEstimatedValue(): Decimal
    var
        OpportunityEntry: Record "Opportunity Entry";
    begin
        OpportunityEntry.SetRange("Opportunity No.", "Opportunity No.");
        if OpportunityEntry.FindLast then
            exit(OpportunityEntry."Estimated Value (LCY)");
    end;

    procedure InitFromSalesHeader(SourceSalesHeader: Record "Sales Header")
    begin
        OnBeforeInitFromSalesHeader(Rec, SourceSalesHeader);

        "Document Date" := SourceSalesHeader."Document Date";
        "Shipment Date" := SourceSalesHeader."Shipment Date";
        "Shortcut Dimension 1 Code" := SourceSalesHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := SourceSalesHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SourceSalesHeader."Dimension Set ID";
        "Location Code" := SourceSalesHeader."Location Code";
        SetShipToAddress(
          SourceSalesHeader."Ship-to Name", SourceSalesHeader."Ship-to Name 2", SourceSalesHeader."Ship-to Address",
          SourceSalesHeader."Ship-to Address 2", SourceSalesHeader."Ship-to City", SourceSalesHeader."Ship-to Post Code",
          SourceSalesHeader."Ship-to County", SourceSalesHeader."Ship-to Country/Region Code");
        "Ship-to Contact" := SourceSalesHeader."Ship-to Contact";

        OnAfterInitFromSalesHeader(Rec, SourceSalesHeader);
    end;

    local procedure InitFromContact(ContactNo: Code[20]; CustomerNo: Code[20]; ContactCaption: Text): Boolean
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        if (ContactNo = '') and (CustomerNo = '') then begin
            if not SalesLine.IsEmpty() then
                Error(Text005, ContactCaption);
            Init;
            GetSalesSetup;
            "No. Series" := xRec."No. Series";
            OnInitFromContactOnBeforeInitRecord(Rec, xRec);
            InitRecord;
            InitNoSeries;
            OnInitFromContactOnAfterInitNoSeries(Rec, xRec);
            exit(true);
        end;
    end;

    local procedure InitFromTemplate(TemplateCode: Code[20]; TemplateCaption: Text): Boolean
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        if TemplateCode = '' then begin
            if not SalesLine.IsEmpty() then
                Error(Text005, TemplateCaption);
            Init;
            GetSalesSetup;
            "No. Series" := xRec."No. Series";
            OnInitFromTemplateOnBeforeInitRecord(Rec, xRec);
            InitRecord;
            InitNoSeries;
            OnInitFromTemplateOnAfterInitNoSeries(Rec, xRec);
            exit(true);
        end;
    end;

    local procedure InitFromBillToCustTemplate(BillToCustTemplate: Record "Customer Templ.")
    begin
        BillToCustTemplate.TestField("Customer Posting Group");
        "Customer Posting Group" := BillToCustTemplate."Customer Posting Group";
        "Invoice Disc. Code" := BillToCustTemplate."Invoice Disc. Code";
        "Customer Price Group" := BillToCustTemplate."Customer Price Group";
        "Customer Disc. Group" := BillToCustTemplate."Customer Disc. Group";
        "Allow Line Disc." := BillToCustTemplate."Allow Line Disc.";
        Validate("Payment Terms Code", BillToCustTemplate."Payment Terms Code");
        Validate("Payment Method Code", BillToCustTemplate."Payment Method Code");
        "Prices Including VAT" := BillToCustTemplate."Prices Including VAT";
        "Shipment Method Code" := BillToCustTemplate."Shipment Method Code";

        OnAfterInitFromBillToCustTemplate(Rec, BillToCustTemplate);
    end;

    local procedure ValidateTaxAreaCode()
    var
        TaxArea: Record "Tax Area";
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        if "Tax Area Code" = '' then
            exit;
        if EnvInfoProxy.IsInvoicing then begin
            if not TaxArea.Get("Tax Area Code") then begin
                TaxArea.SetFilter(Code, "Tax Area Code" + '*');
                if not TaxArea.FindFirst then
                    TaxArea.CreateTaxArea("Tax Area Code", "Sell-to City", "Sell-to County");
                "Tax Area Code" := TaxArea.Code;
            end;

            if Cust.Get("Sell-to Customer No.") then
                if Cust."Tax Area Code" = '' then begin
                    Cust."Tax Area Code" := "Tax Area Code";
                    Cust.Modify();
                end;
        end else
            TaxArea.Get("Tax Area Code");
    end;

    procedure SetWorkDescription(NewWorkDescription: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Work Description");
        "Work Description".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewWorkDescription);
        Modify;
    end;

    procedure GetWorkDescription() WorkDescription: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Work Description");
        "Work Description".CreateInStream(InStream, TEXTENCODING::UTF8);
        if not TypeHelper.TryReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator(), WorkDescription) then
            Message(ReadingDataSkippedMsg, FieldCaption("Work Description"));
    end;

    local procedure LookupContact(CustomerNo: Code[20]; ContactNo: Code[20]; var Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        FilterByContactCompany: Boolean;
    begin
        if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, CustomerNo) then
            Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.")
        else
            if "Document Type" = "Document Type"::Quote then
                FilterByContactCompany := true
            else
                Contact.SetRange("Company No.", '');
        if ContactNo <> '' then
            if Contact.Get(ContactNo) then
                if FilterByContactCompany then
                    Contact.SetRange("Company No.", Contact."Company No.");
    end;

    procedure SetAllowSelectNoSeries()
    begin
        SelectNoSeriesAllowed := true;
    end;

    local procedure SetDefaultSalesperson()
    var
        UserSetupSalespersonCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultSalesperson(Rec, IsHandled);
        if IsHandled then
            exit;

        UserSetupSalespersonCode := GetUserSetupSalespersonCode;
        if UserSetupSalespersonCode <> '' then
            if Salesperson.Get(UserSetupSalespersonCode) then
                if not Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then
                    Validate("Salesperson Code", UserSetupSalespersonCode);
    end;

    local procedure GetUserSetupSalespersonCode(): Code[20]
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit;

        exit(UserSetup."Salespers./Purch. Code");
    end;

    procedure SelltoCustomerNoOnAfterValidate(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
        if SalesHeader.GetFilter("Sell-to Customer No.") = xSalesHeader."Sell-to Customer No." then
            if SalesHeader."Sell-to Customer No." <> xSalesHeader."Sell-to Customer No." then
                SalesHeader.SetRange("Sell-to Customer No.");

        OnAfterSelltoCustomerNoOnAfterValidate(Rec, xRec);
    end;

#if not CLEAN18
    [Obsolete('Will be removed with other functionality related to "old" templates. Replaced by SelectSalesHeaderNewCustomerTemplate()', '18.0')]
    procedure SelectSalesHeaderCustomerTemplate(): Code[10]
    var
        Contact: Record Contact;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Contact.Get("Sell-to Contact No.");
        if (Contact.Type = Contact.Type::Person) and (Contact."Company No." <> '') then
            Contact.Get(Contact."Company No.");
        if not Contact.ContactToCustBusinessRelationExist then
            if ConfirmManagement.GetResponse(SelectCustomerTemplateQst, false) then begin
                Commit();
                exit(CopyStr(Contact.LookupCustomerTemplate(), 1, 10));
            end;
    end;
#endif

    procedure SelectSalesHeaderNewCustomerTemplate(): Code[20]
    var
        Contact: Record Contact;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Contact.Get("Sell-to Contact No.");
        if (Contact.Type = Contact.Type::Person) and (Contact."Company No." <> '') then
            Contact.Get(Contact."Company No.");
        if not Contact.ContactToCustBusinessRelationExist then
            if ConfirmManagement.GetResponse(SelectCustomerTemplateQst, false) then begin
                Commit();
                exit(Contact.LookupNewCustomerTemplate());
            end;
    end;

    local procedure ModifyBillToCustomerAddress()
    var
        Customer: Record Customer;
    begin
        GetSalesSetup;
        if SalesSetup."Ignore Updated Addresses" then
            exit;
        if IsCreditDocType then
            exit;
        if ("Bill-to Customer No." <> "Sell-to Customer No.") and Customer.Get("Bill-to Customer No.") then
            if HasBillToAddress and HasDifferentBillToAddress(Customer) then
                ShowModifyAddressNotification(GetModifyBillToCustomerAddressNotificationId,
                  ModifyCustomerAddressNotificationLbl, ModifyCustomerAddressNotificationMsg,
                  'CopyBillToCustomerAddressFieldsFromSalesDocument', "Bill-to Customer No.",
                  "Bill-to Name", FieldName("Bill-to Customer No."));
    end;

    local procedure ModifyCustomerAddress()
    var
        Customer: Record Customer;
    begin
        GetSalesSetup;
        if SalesSetup."Ignore Updated Addresses" then
            exit;
        if IsCreditDocType then
            exit;
        if Customer.Get("Sell-to Customer No.") and HasSellToAddress and HasDifferentSellToAddress(Customer) then
            ShowModifyAddressNotification(GetModifyCustomerAddressNotificationId,
              ModifyCustomerAddressNotificationLbl, ModifyCustomerAddressNotificationMsg,
              'CopySellToCustomerAddressFieldsFromSalesDocument', "Sell-to Customer No.",
              "Sell-to Customer Name", FieldName("Sell-to Customer No."));
    end;

    local procedure ShowModifyAddressNotification(NotificationID: Guid; NotificationLbl: Text; NotificationMsg: Text; NotificationFunctionTok: Text; CustomerNumber: Code[20]; CustomerName: Text[100]; CustomerNumberFieldName: Text)
    var
        MyNotifications: Record "My Notifications";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PageMyNotifications: Page "My Notifications";
        ModifyCustomerAddressNotification: Notification;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowModifyAddressNotification(IsHandled, Rec, CustomerNumber);
        if IsHandled then
            exit;

        if not MyNotifications.Get(UserId, NotificationID) then
            PageMyNotifications.InitializeNotificationsWithDefaultState;

        if not MyNotifications.IsEnabled(NotificationID) then
            exit;

        ModifyCustomerAddressNotification.Id := NotificationID;
        ModifyCustomerAddressNotification.Message := StrSubstNo(NotificationMsg, CustomerName);
        ModifyCustomerAddressNotification.AddAction(NotificationLbl, CODEUNIT::"Document Notifications", NotificationFunctionTok);
        ModifyCustomerAddressNotification.AddAction(
          DontShowAgainActionLbl, CODEUNIT::"Document Notifications", 'HideNotificationForCurrentUser');
        ModifyCustomerAddressNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        ModifyCustomerAddressNotification.SetData(FieldName("Document Type"), Format("Document Type"));
        ModifyCustomerAddressNotification.SetData(FieldName("No."), "No.");
        ModifyCustomerAddressNotification.SetData(CustomerNumberFieldName, CustomerNumber);
        NotificationLifecycleMgt.SendNotification(ModifyCustomerAddressNotification, RecordId);
    end;

    procedure RecallModifyAddressNotification(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
        ModifyCustomerAddressNotification: Notification;
    begin
        if IsCreditDocType or (not MyNotifications.IsEnabled(NotificationID)) then
            exit;

        ModifyCustomerAddressNotification.Id := NotificationID;
        ModifyCustomerAddressNotification.Recall;
    end;

    procedure GetModifyCustomerAddressNotificationId(): Guid
    begin
        exit('509FD112-31EC-4CDC-AEBF-19B8FEBA526F');
    end;

    procedure GetModifyBillToCustomerAddressNotificationId(): Guid
    begin
        exit('2096CE78-6A74-48DB-BC9A-CD5C21504FC1');
    end;

    procedure GetLineInvoiceDiscountResetNotificationId(): Guid
    begin
        exit('35AB3090-2E03-4849-BBF9-9664DE464605');
    end;

    procedure SetModifyCustomerAddressNotificationDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetModifyCustomerAddressNotificationId,
          ModifySellToCustomerAddressNotificationNameTxt, ModifySellToCustomerAddressNotificationDescriptionTxt, true);
    end;

    procedure SetModifyBillToCustomerAddressNotificationDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetModifyBillToCustomerAddressNotificationId,
          ModifyBillToCustomerAddressNotificationNameTxt, ModifyBillToCustomerAddressNotificationDescriptionTxt, true);
    end;

    procedure DontNotifyCurrentUserAgain(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(NotificationID) then
            case NotificationID of
                GetModifyCustomerAddressNotificationId:
                    MyNotifications.InsertDefault(NotificationID, ModifySellToCustomerAddressNotificationNameTxt,
                      ModifySellToCustomerAddressNotificationDescriptionTxt, false);
                GetModifyBillToCustomerAddressNotificationId:
                    MyNotifications.InsertDefault(NotificationID, ModifyBillToCustomerAddressNotificationNameTxt,
                      ModifyBillToCustomerAddressNotificationDescriptionTxt, false);
            end;
    end;

    procedure HasDifferentSellToAddress(Customer: Record Customer): Boolean
    begin
        exit(("Sell-to Address" <> Customer.Address) or
          ("Sell-to Address 2" <> Customer."Address 2") or
          ("Sell-to City" <> Customer.City) or
          ("Sell-to Country/Region Code" <> Customer."Country/Region Code") or
          ("Sell-to County" <> Customer.County) or
          ("Sell-to Post Code" <> Customer."Post Code") or
          ("Sell-to Contact" <> Customer.Contact));
    end;

    procedure HasDifferentBillToAddress(Customer: Record Customer): Boolean
    begin
        exit(("Bill-to Address" <> Customer.Address) or
          ("Bill-to Address 2" <> Customer."Address 2") or
          ("Bill-to City" <> Customer.City) or
          ("Bill-to Country/Region Code" <> Customer."Country/Region Code") or
          ("Bill-to County" <> Customer.County) or
          ("Bill-to Post Code" <> Customer."Post Code") or
          ("Bill-to Contact" <> Customer.Contact));
    end;

    procedure HasDifferentShipToAddress(Customer: Record Customer): Boolean
    begin
        exit(("Ship-to Address" <> Customer.Address) or
          ("Ship-to Address 2" <> Customer."Address 2") or
          ("Ship-to City" <> Customer.City) or
          ("Ship-to Country/Region Code" <> Customer."Country/Region Code") or
          ("Ship-to County" <> Customer.County) or
          ("Ship-to Post Code" <> Customer."Post Code") or
          ("Ship-to Contact" <> Customer.Contact));
    end;

    procedure ShowInteractionLogEntries()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        if "Bill-to Contact No." <> '' then
            InteractionLogEntry.SetRange("Contact No.", "Bill-to Contact No.");
        case "Document Type" of
            "Document Type"::Order:
                InteractionLogEntry.SetRange("Document Type", InteractionLogEntry."Document Type"::"Sales Ord. Cnfrmn.");
            "Document Type"::Quote:
                InteractionLogEntry.SetRange("Document Type", InteractionLogEntry."Document Type"::"Sales Qte.");
        end;

        InteractionLogEntry.SetRange("Document No.", "No.");
        PAGE.Run(PAGE::"Interaction Log Entries", InteractionLogEntry);
    end;

    procedure GetBillToNo(): Code[20]
#if not CLEAN18
    var
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
#endif
    begin
#if not CLEAN18
        if not CustomerTemplMgt.IsEnabled() then begin
            if ("Document Type" = "Document Type"::Quote) and
               ("Bill-to Customer No." = '') and ("Bill-to Contact No." <> '') and
               ("Bill-to Customer Template Code" <> '')
            then
                exit("Bill-to Contact No.");
        end else
#endif
            if ("Document Type" = "Document Type"::Quote) and
               ("Bill-to Customer No." = '') and ("Bill-to Contact No." <> '') and
               ("Bill-to Customer Templ. Code" <> '')
            then
                exit("Bill-to Contact No.");

        exit("Bill-to Customer No.");
    end;

    procedure GetCurrencySymbol(): Text[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if GeneralLedgerSetup.Get then
            if ("Currency Code" = '') or ("Currency Code" = GeneralLedgerSetup."LCY Code") then
                exit(GeneralLedgerSetup.GetCurrencySymbol);

        if Currency.Get("Currency Code") then
            exit(Currency.GetCurrencySymbol);

        exit("Currency Code");
    end;

    local procedure SetSalespersonCode(SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSalespersonCode(Rec, SalesPersonCodeToCheck, SalesPersonCodeToAssign, IsHandled);
        if IsHandled then
            exit;

        if SalesPersonCodeToCheck = '' then
            SalesPersonCodeToCheck := GetUserSetupSalespersonCode();
        if Salesperson.Get(SalesPersonCodeToCheck) then begin
            if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then
                SalesPersonCodeToAssign := ''
            else
                SalesPersonCodeToAssign := SalesPersonCodeToCheck;
        end else
            SalesPersonCodeToAssign := '';
    end;

    procedure ValidateSalesPersonOnSalesHeader(SalesHeader2: Record "Sales Header"; IsTransaction: Boolean; IsPostAction: Boolean)
    begin
        if SalesHeader2."Salesperson Code" <> '' then
            if Salesperson.Get(SalesHeader2."Salesperson Code") then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then begin
                    if IsTransaction then
                        Error(Salesperson.GetPrivacyBlockedTransactionText(Salesperson, IsPostAction, true));
                    if not IsTransaction then
                        Error(Salesperson.GetPrivacyBlockedGenericText(Salesperson, true));
                end;
    end;

    procedure ShouldSearchForCustomerByName(CustomerNo: Code[20]) Result: Boolean
    var
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldSearchForCustomerByName(CustomerNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if CustomerNo = '' then
            exit(true);

        if not Customer.Get(CustomerNo) then
            exit(true);

        exit(not Customer."Disable Search by Name");
    end;

    local procedure CalcQuoteValidUntilDate()
    var
        BlankDateFormula: DateFormula;
    begin
        GetSalesSetup;
        if SalesSetup."Quote Validity Calculation" <> BlankDateFormula then
            "Quote Valid Until Date" := CalcDate(SalesSetup."Quote Validity Calculation", "Document Date");
    end;

    procedure TestQuantityShippedField(SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestQuantityShippedField(SalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.TestField("Quantity Shipped", 0);
        OnAfterTestQuantityShippedField(SalesLine);
    end;

    procedure TestStatusIsNotPendingApproval() NotPending: Boolean;
    begin
        NotPending := Status in [Status::Open, Status::"Pending Prepayment", Status::Released];

        OnTestStatusIsNotPendingApproval(Rec, NotPending);
    end;

    procedure TestStatusIsNotPendingPrepayment() NotPending: Boolean;
    begin
        NotPending := Status in [Status::Open, Status::"Pending Approval", Status::Released];

        OnTestStatusIsNotPendingPrepayment(Rec, NotPending);
    end;

    procedure TestStatusIsNotReleased() NotReleased: Boolean;
    begin
        NotReleased := Status in [Status::Open, Status::"Pending Approval", Status::"Pending Prepayment"];

        OnTestStatusIsNotReleased(Rec, NotReleased);
    end;

    procedure TestStatusOpen()
    begin
        OnBeforeTestStatusOpen(Rec, xRec, CurrFieldNo);

        if StatusCheckSuspended then
            exit;

        TestField(Status, Status::Open);

        OnAfterTestStatusOpen(Rec);
    end;

    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    procedure CheckForBlockedLines()
    var
        CurrentSalesLine: Record "Sales Line";
        Item: Record Item;
        Resource: Record Resource;
    begin
        CurrentSalesLine.SetCurrentKey("Document Type", "Document No.", Type);
        CurrentSalesLine.SetRange("Document Type", "Document Type");
        CurrentSalesLine.SetRange("Document No.", "No.");
        CurrentSalesLine.SetFilter(Type, '%1|%2', CurrentSalesLine.Type::Item, CurrentSalesLine.Type::Resource);
        CurrentSalesLine.SetFilter("No.", '<>''''');

        if CurrentSalesLine.FindSet then
            repeat
                case CurrentSalesLine.Type of
                    CurrentSalesLine.Type::Item:
                        begin
                            Item.Get(CurrentSalesLine."No.");
                            Item.TestField(Blocked, false);
                        end;
                    CurrentSalesLine.Type::Resource:
                        begin
                            Resource.Get(CurrentSalesLine."No.");
                            Resource.CheckResourcePrivacyBlocked(false);
                            Resource.TestField(Blocked, false);
                        end;
                end;
            until CurrentSalesLine.Next() = 0;
    end;

    procedure CopyDocument()
    var
        CopySalesDocument: Report "Copy Sales Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDocument(Rec, IsHandled);
        if IsHandled then
            exit;

        CopySalesDocument.SetSalesHeader(Rec);
        CopySalesDocument.RunModal;
    end;

    local procedure CheckContactRelatedToCustomerCompany(ContactNo: Code[20]; CustomerNo: Code[20]; CurrFieldNo: Integer);
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckContactRelatedToCustomerCompany(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        Contact.Get(ContactNo);
        if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, CustomerNo) then
            if (ContBusRel."Contact No." <> Contact."Company No.") and (ContBusRel."Contact No." <> Contact."No.") then
                Error(Text038, Contact."No.", Contact.Name, CustomerNo);
    end;

    local procedure ConfirmRecalculatePrice(var SalesLine: Record "Sales Line") Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmRecalculatePrice(Rec, xRec, CurrFieldNo, Result, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        if GetHideValidationDialog or not GuiAllowed then
            Result := true
        else
            Result :=
              ConfirmManagement.GetResponseOrDefault(
                StrSubstNo(Text024, FieldCaption("Prices Including VAT"), SalesLine.FieldCaption("Unit Price")), true);
    end;

#if not CLEAN19
    [Obsolete('Replaced with LookupSellToCustomerName(var CustomerName: Text[100]): Boolean', '19.0')]
    procedure LookupSellToCustomerName(): Boolean
    var
        Customer: Record Customer;
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
    begin
        Customer.SetFilter("Date Filter", GetFilter("Date Filter"));
        if "Sell-to Customer No." <> '' then
            Customer.Get("Sell-to Customer No.");

        if Customer.LookupCustomer(Customer) then begin
            "Sell-to Customer Name" := Customer.Name;
            Validate("Sell-to Customer No.", Customer."No.");
            GetShippingTime(FieldNo("Sell-to Customer Name"));
            if "No." <> '' then
                StandardCodesMgt.CheckCreateSalesRecurringLines(Rec);
            OnLookupSellToCustomerNameOnAfterSuccessfulLookup(Rec);
            exit(true);
        end;
    end;
#endif
    procedure LookupSellToCustomerName(var CustomerName: Text): Boolean
    var
        Customer: Record Customer;
        LookupStateManager: Codeunit "Lookup State Manager";
        RecVariant: Variant;
    begin
        Customer.SetFilter("Date Filter", GetFilter("Date Filter"));
        if "Sell-to Customer No." <> '' then
            Customer.Get("Sell-to Customer No.");

        if Customer.LookupCustomer(Customer) then begin
            if Rec."Sell-to Customer Name" = Customer.Name then
                CustomerName := ''
            else
                CustomerName := Customer.Name;
            RecVariant := Customer;
            LookupStateManager.SaveRecord(RecVariant);
            exit(true);
        end;
    end;

    local procedure CheckPromisedDeliveryDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPromisedDeliveryDate(IsHandled);
        if IsHandled then
            exit;

        if "Promised Delivery Date" <> 0D then
            Error(Text028, FieldCaption("Requested Delivery Date"), FieldCaption("Promised Delivery Date"));
    end;

    local procedure SetBillToCustomerNo(var Cust: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetBillToCustomerNo(Rec, Cust, IsHandled);
        if IsHandled then
            exit;

        if Cust."Bill-to Customer No." <> '' then
            Validate("Bill-to Customer No.", Cust."Bill-to Customer No.")
        else begin
            if "Bill-to Customer No." = "Sell-to Customer No." then
                SkipBillToContact := true;
            Validate("Bill-to Customer No.", "Sell-to Customer No.");
            SkipBillToContact := false;
        end;
    end;

    procedure GetStatusCheckSuspended(): Boolean
    begin
        exit(StatusCheckSuspended);
    end;

    procedure SetCalledFromWhseDoc(NewCalledFromWhseDoc: Boolean)
    begin
        CalledFromWhseDoc := NewCalledFromWhseDoc;
    end;

    local procedure UpdatePrepmtAmounts(var SalesLine: Record "Sales Line")
    var
        Currency: Record Currency;
    begin
        Currency.Initialize("Currency Code");
        if "Document Type" = "Document Type"::Order then begin
            SalesLine."Prepmt. Line Amount" := Round(
                SalesLine."Line Amount" * SalesLine."Prepayment %" / 100, Currency."Amount Rounding Precision");
            if Abs(SalesLine."Inv. Discount Amount" + SalesLine."Prepmt. Line Amount") > Abs(SalesLine."Line Amount") then
                SalesLine."Prepmt. Line Amount" := SalesLine."Line Amount" - SalesLine."Inv. Discount Amount";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNoSeries(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCreditLimitCondition(var SalesHeader: Record "Sales Header"; var RunCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCreditMaxBeforeInsert(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBillToCust(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSellToCust(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; Customer: Record Customer; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckShippingAdvice(var SalesHeader: Record "Sales Header"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmSalesPrice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecreateSalesLine(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteAllTempSalesLines(SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSalesHeader(var SalesHeader: Record "Sales Header"; SourceSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromBillToCustTemplate(var SalesHeader: Record "Sales Header"; BillToCustTemplate: Record "Customer Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTempSalesLine(SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsApprovedForPosting(SalesHeader: Record "Sales Header"; var Approved: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsApprovedForPostingBatch(SalesHeader: Record "Sales Header"; var Approved: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var SalesHeader: Record "Sales Header"; SalesReceivablesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPostingNoSeriesCode(SalesHeader: Record "Sales Header"; var PostingNos: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPrepaymentPostingNoSeriesCode(SalesHeader: Record "Sales Header"; var PostingNos: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesSetup(SalesHeader: Record "Sales Header"; var SalesReceivablesSetup: Record "Sales & Receivables Setup"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocTypeText(var SalesHeader: Record "Sales Header"; var TypeText: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetStatusStyleText(SalesHeader: Record "Sales Header"; var StatusStyleText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestNoSeries(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateShipToAddress(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCurrencyFactor(var SalesHeader: Record "Sales Header"; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAppliesToDocNoOnLookup(var SalesHeader: Record "Sales Header"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineByChangedFieldName(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ChangedFieldName: Text[100]; ChangedFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineAmountsOnAfterSalesHeaderModify(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateShipToContactOnBeforeValidateShipToContact(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOpportunityOnBeforeModify(var Opportunity: Record Opportunity; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOpportunityLinkOnBeforeModify(var Opportunity: Record Opportunity; var SalesHeader: Record "Sales Header"; SalesDocumentType: Option; SalesHeaderNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var SalesHeader: Record "Sales Header"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesLine(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsShipToAddressEqualToSellToAddress(SellToSalesHeader: Record "Sales Header"; ShipToSalesHeader: Record "Sales Header"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesQuoteAccepted(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterChangePricesIncludingVAT(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelltoCustomerNoOnAfterValidate(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendSalesHeader(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFieldsBilltoCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferExtendedTextForSalesLineRecreation(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

#if not CLEAN18
    [Obsolete('Will be removed with other functionality related to "old" templates. Replaced by OnAfterCopyFromNewSellToCustTemplate().', '18.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSellToCustTemplate(var SalesHeader: Record "Sales Header"; SellToCustTemplate: Record "Customer Template")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromNewSellToCustTemplate(var SalesHeader: Record "Sales Header"; SellToCustTemplate: Record "Customer Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySellToAddressToShipToAddress(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySellToAddressToBillToAddress(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySellToCustomerAddressFieldsFromCustomer(var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer; CurrentFieldNo: Integer; var SkipBillToContact: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyShipToCustomerAddressFieldsFromCustomer(var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr(var SalesHeader: Record "Sales Header"; ShipToAddress: Record "Ship-to Address")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLinesByFieldNo(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; ChangedFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var SalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAvailableCreditLimit(var SalesHeader: Record "Sales Header"; var ReturnValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCreditLimit(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCreditMaxBeforeInsert(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; HideCreditCheckDialogue: Boolean; FilterCustNo: Code[20]; FilterContNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCreditLimitIfLineNotInsertedYet(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerContactRelation(var SalesHeader: Record "Sales Header"; Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReturnInfo(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShipmentInfo(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; BillTo: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShippingAdvice(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmUpdateAllLineDim(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; NewParentDimSetID: Integer; OldParentDimSetID: Integer; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmBillToContactNoChange(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmSellToContactNoChange(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmUpdateCurrencyFactor(var SalesHeader: Record "Sales Header"; var HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetContactAsCompany(Contact: Record Contact; var SearchContact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmDeletion(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyShipToCustomerAddressFieldsFromCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyShipToCustomerAddressFieldsFromShipToAddr(var SalesHeader: Record "Sales Header"; ShipToAddress: Record "Ship-to Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCustomerFromSellToCustomerTemplate(var SalesHeader: Record "Sales Header"; var Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCustomerFromBillToCustomerTemplate(var SalesHeader: Record "Sales Header"; var Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesLine(var TempSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean; var SalesHeader: record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateInvtPutAwayPick(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeleteSalesLines(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeleteRecordInApprovalRequest(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustomerVATRegistrationNumber(var SalesHeader: Record "Sales Header"; var ReturnValue: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustomerVATRegistrationNumberLbl(var SalesHeader: Record "Sales Header"; var ReturnValue: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var SalesHeader: Record "Sales Header"; SalesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPstdDocLinesToReverse(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostingNoSeriesCode(var SalesHeader: Record "Sales Header"; SalesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetShippingTime(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var CalledByFieldNo: Integer; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetShipmentMethodCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFromSalesHeader(var SalesHeader: Record "Sales Header"; SourceSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitInsert(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPostingDescription(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRecord(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsCreditDocType(SalesHeader: Record "Sales Header"; var CreditDocType: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupAppliesToDocNo(var SalesHeader: Record "Sales Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupBillToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupSellToContactNo(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupSellToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupShipToCity(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShipToCity(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupShipToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShipToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShippingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupReturnReceiptNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenSalesOrderStatistics(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeQtyToShipIsZero(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDocDim(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldSearchForCustomerByName(CustomerNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferItemChargeAssgntSalesToTemp(var SalesHeader: Record "Sales Header"; var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCurrencyFactor(var SalesHeader: Record "Sales Header"; var Updated: Boolean; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDocumentDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReturnReceiptNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSellToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVATRegistrationNo(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMessageIfSalesLinesExist(SalesHeader: Record "Sales Header"; ChangedFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePriceMessageIfSalesLinesExist(SalesHeader: Record "Sales Header"; ChangedFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreateSalesLines(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreateSalesLinesHandler(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; ChangedFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreateSalesLinesHandleSupplementTypes(var TempSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineByChangedFieldNo(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ChangedFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineInsert(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCustomerLocationCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultSalesperson(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStoreSalesCommentLineToTemp(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeShowPostedDocsToPrintCreatedMsg(var ShowPostedDocsToPrint: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSynchronizeForReservations(var SalesHeader: Record "Sales Header"; var NewSalesLine: Record "Sales Line"; OldSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBillToCustContact(var SalesHeader: Record "Sales Header"; Conact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSellToCust(var SalesHeader: Record "Sales Header"; var Contact: Record Contact; var Customer: Record Customer; ContactNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAllLineDim(var SalesHeader: Record "Sales Header"; NewParentDimSetID: Integer; OldParentDimSetID: Integer; var IsHandled: Boolean; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLocationCode(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOutboundWhseHandlingTime(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLineAmounts(SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLinesByFieldNo(var SalesHeader: Record "Sales Header"; ChangedFieldNo: Integer; var AskQuestion: Boolean; var IsHandled: Boolean; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLines(var SalesHeader: Record "Sales Header"; ChangedFieldName: Text[100]; var AskQuestion: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSellToCustContact(var SalesHeader: Record "Sales Header"; Conact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToAddress(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToCodeFromCust(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostingDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemAvailabilityInLinesOnAfterSetFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectParamsInBufferForCreateDimSetOnAfterSetTempSalesLineFilters(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySelltoCustomerAddressFieldsFromCustomerOnAfterAssignRespCenter(var SalesHeader: Record "Sales Header"; Customer: Record Customer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnBeforeUpdateLines(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; OldDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnAfterAssignType(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnBeforeValidateQuantity(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromContactOnAfterInitNoSeries(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromContactOnBeforeInitRecord(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromTemplateOnAfterInitNoSeries(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromTemplateOnBeforeInitRecord(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitInsertOnBeforeInitRecord(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitRecordOnBeforeAssignShipmentDate(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempSalesLineInBufferOnBeforeTempSalesLineInsert(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnAfterSalesQuote(var SalesHeader: Record "Sales Header"; Contact: Record Contact)
    begin
    end;

#if not CLEAN18
    [Obsolete('Will be removed with other functionality related to "old" templates. Replaced by OnValidateBilltoCustomerTemplCodeOnBeforeRecreateSalesLines()', '18.0')]
    [IntegrationEvent(false, false)]
    local procedure OnValidateBilltoCustomerTemplateCodeBeforeRecreateSalesLines(var SalesHeader: Record "Sales Header"; CallingFieldNo: Integer)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnValidateBilltoCustomerTemplCodeOnBeforeRecreateSalesLines(var SalesHeader: Record "Sales Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoAfterInit(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestQuantityShippedField(SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesLineFieldsBeforeRecreate(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestQuantityShippedField(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeTestStatusOpen(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterTestStatusOpen(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBillToCont(var SalesHeader: Record "Sales Header"; Customer: Record Customer; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBillToCust(var SalesHeader: Record "Sales Header"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSellToCont(var SalesHeader: Record "Sales Header"; Customer: Record Customer; Contact: Record Contact; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSellToCust(var SalesHeader: Record "Sales Header"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLines(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAppliesToDocNo(var SalesHeader: Record "Sales Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToCustomerName(var SalesHeader: Record "Sales Header"; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSellToCustomerName(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkSalesDocWithOpportunityOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header"; OldOpportunityNo: Code[20]; Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupSellToCustomerNameOnAfterSuccessfulLookup(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesOnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesOnBeforeConfirm(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; ChangedFieldName: Text[100]; HideValidationDialog: Boolean; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesOnBeforeSalesLineDeleteAll(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateReservEntryReqLineOnAfterLoop(var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestStatusIsNotPendingApproval(SalesHeader: Record "Sales Header"; var NotPending: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestStatusIsNotPendingPrepayment(SalesHeader: Record "Sales Header"; var NotPending: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestStatusIsNotReleased(SalesHeader: Record "Sales Header"; var NotReleased: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeSalesLineModify(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLinesByFieldNoOnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; ChangedFieldNo: Integer; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLinesByFieldNoOnAfterCalcShouldConfirmReservationDateConflict(var SalesHeader: Record "Sales Header"; ChangedFieldNo: Integer; var ShouldConfirmReservationDateConflict: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnBeforeContactIsNotRelatedToAnyCostomerErr(var SalesHeader: Record "Sales Header"; Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnBeforeFindContactBusinessRelation(Contact: Record Contact; var ContBusinessRelation: Record "Contact Business Relation"; var ContactBusinessRelationFound: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnAfterSetFromSearchContact(var SalesHeader: Record "Sales Header"; var SearchContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnAfterSetShipToAddress(var SalesHeader: Record "Sales Header"; var SearchContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnAfterSetSellToContactNo(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var Cont: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnBeforeContactIsNotRelatedToAnyCostomerErr(var SalesHeader: Record "Sales Header"; Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnBeforeFindContactBusinessRelation(Cont: Record Contact; var ContBusinessRelation: Record "Contact Business Relation"; var ContactBusinessRelationFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnAfterConfirmed(var SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalcDueDate(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalcPmtDiscDate(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeValidateDueDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeValidateDueDateWhenBlank(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingDateOnBeforeAssignDocumentDate(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingDateOnBeforeCheckNeedUpdateCurrencyFactor(var SalesHeader: Record "Sales Header"; var IsConfirmed: Boolean; var NeedUpdateCurrencyFactor: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalculatePrepaymentDueDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePricesIncludingVATOnBeforeSalesLineModify(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Currency: Record Currency; RecalculatePrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShippingAgentCodeOnBeforeUpdateLines(var SalesHeader: Record "Sales Header"; CallingFieldNo: Integer; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFullDocTypeTxt(var SalesHeader: Record "Sales Header"; var FullDocTypeTxt: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectParamsInBufferForCreateDimSetOnBeforeInsertTempSalesLineInBuffer(var GenPostingSetup: Record "General Posting Setup"; var DefaultDimension: Record "Default Dimension")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDocument(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBillToCust(var SalesHeader: Record "Sales Header"; ContactNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesOnBeforeTempSalesLineFindSet(var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckContactRelatedToCustomerCompany(SalesHeader: Record "Sales Header"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowModifyAddressNotification(var IsHandled: Boolean; SalesHeader: Record "Sales Header"; CustomerNumber: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDocDimOnBeforeUpdateSalesLines(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmRecalculatePrice(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrFieldNo: Integer; var Result: Boolean; var HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeGetSalesLineNewDimSetID(var SalesLine: Record "Sales Line"; NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnAfterGetSalesLineNewDimsetID(SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var NewDimSetID: Integer; NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShippingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRename(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeLookupBillToContactNo(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateOpportunity(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckPromisedDeliveryDate(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToAddressFromSellToAddress(var SalesHeader: Record "Sales Header"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalespersonCode(var SalesHeader: Record "Sales Header"; SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateShipToAddressFromSellToAddress(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; FieldNumber: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToCode(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; Cust: Record Customer; ShipToAddr: Record "Ship-to Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoOnBeforeCheckBlockedCustOnDocs(var SalesHeader: Record "Sales Header"; var Cust: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnBeforeCheckBlockedCustOnDocs(var SalesHeader: Record "Sales Header"; var Cust: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetBillToCustomerAddressFieldsFromCustomer(var SalesHeader: Record "Sales Header"; var BillToCustomer: Record Customer; var SkipBillToContact: Boolean; var IsHandled: Boolean; xSalesHeader: Record "Sales Header"; var GLSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnBeforeRecallModifyAddressNotification(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToName(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipToCodeOnBeforeValidateTaxLiable(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipToCodeOnBeforeCopyShipToAddress(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; var CopyShipToAddress: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipmentMethodCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShippingAgentCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitRecordOnBeforeAssignWorkDateToPostingDate(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetBillToCustomerNo(var SalesHeader: Record "Sales Header"; var Cust: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShippingAgentServiceCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePrepmtPaymentTermsCode(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CalledByFieldNo: Integer; CallingFieldNo: Integer; UpdateDocumentDate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecreateSalesLines(var SalesHeader: Record "Sales Header"; ChangedFieldName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSellToCustomerFromFilter(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscForHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoOnBeforeRecallModifyAddressNotification(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCreditMaxBeforeInsertOnCaseIfOnBeforeSalesHeaderCheckCase(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepmtPaymentTermsCodeOnCaseElseOnBeforeValidatePrepaymentDueDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePrepmtPaymentTermsCodeOnCaseIfOnBeforeValidatePrepaymentDueDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecreateSalesLinesHandleSupplementTypes(var SalesHeader: Record "Sales Header")
    begin
    end;
}

