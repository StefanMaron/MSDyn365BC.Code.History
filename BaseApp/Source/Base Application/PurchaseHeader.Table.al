table 38 "Purchase Header"
{
    Caption = 'Purchase Header';
    DataCaptionFields = "No.", "Buy-from Vendor Name";
    LookupPageID = "Purchase List";

    fields
    {
        field(1; "Document Type"; Enum "Purchase Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            TableRelation = Vendor;

            trigger OnValidate()
            var
                StandardCodesMgt: Codeunit "Standard Codes Mgt.";
            begin
                if "No." = '' then
                    InitRecord();
                TestStatusOpen();
                if ("Buy-from Vendor No." <> xRec."Buy-from Vendor No.") and
                   (xRec."Buy-from Vendor No." <> '')
                then begin
                    CheckDropShipmentLineExists();
                    if GetHideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, BuyFromVendorTxt);
                    if Confirmed then begin
                        if InitFromVendor("Buy-from Vendor No.", FieldCaption("Buy-from Vendor No.")) then
                            exit;

                        CheckReceiptInfo(PurchLine, false);
                        CheckPrepmtInfo(PurchLine);
                        CheckReturnInfo(PurchLine, false);

                        PurchLine.Reset();
                    end else begin
                        Rec := xRec;
                        exit;
                    end;
                end;

                GetVend("Buy-from Vendor No.");
                CheckBlockedVendOnDocs(Vend);
                if not ApplicationAreaMgmt.IsSalesTaxEnabled then
                    Vend.TestField("Gen. Bus. Posting Group");
                OnAfterCheckBuyFromVendor(Rec, xRec, Vend);

                "Buy-from Vendor Name" := Vend.Name;
                "Buy-from Vendor Name 2" := Vend."Name 2";
                CopyBuyFromVendorAddressFieldsFromVendor(Vend, false);
                if not SkipBuyFromContact then
                    "Buy-from Contact" := Vend.Contact;
                "Gen. Bus. Posting Group" := Vend."Gen. Bus. Posting Group";
                "VAT Bus. Posting Group" := Vend."VAT Bus. Posting Group";
                "Tax Area Code" := Vend."Tax Area Code";
                "Tax Liable" := Vend."Tax Liable";
                "VAT Country/Region Code" := Vend."Country/Region Code";
                "VAT Registration No." := Vend."VAT Registration No.";
                Validate("Lead Time Calculation", Vend."Lead Time Calculation");
                "Shipment Method Code" := Vend."Shipment Method Code";
                "Responsibility Center" := UserSetupMgt.GetRespCenter(1, Vend."Responsibility Center");
                ValidateEmptySellToCustomerAndLocation();
                OnAfterCopyBuyFromVendorFieldsFromVendor(Rec, Vend, xRec);

                if "Buy-from Vendor No." = xRec."Pay-to Vendor No." then
                    if ReceivedPurchLinesExist or ReturnShipmentExist then begin
                        TestField("VAT Bus. Posting Group", xRec."VAT Bus. Posting Group");
                        TestField("Gen. Bus. Posting Group", xRec."Gen. Bus. Posting Group");
                    end;

                "Buy-from IC Partner Code" := Vend."IC Partner Code";
                "Send IC Document" := ("Buy-from IC Partner Code" <> '') and ("IC Direction" = "IC Direction"::Outgoing);

                OnValidateBuyFromVendorNoOnValidateBuyFromVendorNoOnBeforeValidatePayToVendor(Rec);
                if Vend."Pay-to Vendor No." <> '' then
                    Validate("Pay-to Vendor No.", Vend."Pay-to Vendor No.")
                else begin
                    if "Buy-from Vendor No." = "Pay-to Vendor No." then
                        SkipPayToContact := true;
                    Validate("Pay-to Vendor No.", "Buy-from Vendor No.");
                    SkipPayToContact := false;
                end;
                "Order Address Code" := '';

                CopyPayToVendorAddressFieldsFromVendor(Vend, false);
                if IsCreditDocType() then begin
                    "Ship-to Name" := Vend.Name;
                    "Ship-to Name 2" := Vend."Name 2";
                    CopyShipToVendorAddressFieldsFromVendor(Vend, true);
                    "Ship-to Contact" := Vend.Contact;
                    "Shipment Method Code" := Vend."Shipment Method Code";
                    if Vend."Location Code" <> '' then
                        Validate("Location Code", Vend."Location Code");
                end;

                OnValidateBuyFromVendorNoBeforeRecreateLines(Rec, CurrFieldNo);

                if (xRec."Buy-from Vendor No." <> "Buy-from Vendor No.") or
                   (xRec."Currency Code" <> "Currency Code") or
                   (xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group") or
                   (xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group")
                then
                    RecreatePurchLines(BuyFromVendorTxt);

                OnValidateBuyFromVendorNoOnAfterRecreateLines(Rec, xRec, CurrFieldNo);

                if not SkipBuyFromContact then
                    UpdateBuyFromCont("Buy-from Vendor No.");

                OnValidateBuyFromVendorNoOnAfterUpdateBuyFromCont(Rec, xRec);

                if (xRec."Buy-from Vendor No." <> '') and (xRec."Buy-from Vendor No." <> "Buy-from Vendor No.") then
                    RecallModifyAddressNotification(GetModifyVendorAddressNotificationId);
            end;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    GetPurchSetup();
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                end;
            end;
        }
        field(4; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePayToVendorNo(Rec, xRec, Confirmed, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if (xRec."Pay-to Vendor No." <> "Pay-to Vendor No.") and
                   (xRec."Pay-to Vendor No." <> '')
                then begin
                    if GetHideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, PayToVendorTxt);
                    if Confirmed then begin
                        PurchLine.SetRange("Document Type", "Document Type");
                        PurchLine.SetRange("Document No.", "No.");

                        CheckReceiptInfo(PurchLine, true);
                        CheckPrepmtInfo(PurchLine);
                        CheckReturnInfo(PurchLine, true);

                        PurchLine.Reset();
                    end else
                        "Pay-to Vendor No." := xRec."Pay-to Vendor No.";
                end;

                OnValidatePayToVendorNoOnBeforeGetPayToVend(Rec);
                GetVend("Pay-to Vendor No.");
                CheckBlockedVendOnDocs(Vend);
                Vend.TestField("Vendor Posting Group");
                PostingSetupMgt.CheckVendPostingGroupPayablesAccount("Vendor Posting Group");
                OnAfterCheckPayToVendor(Rec, xRec, Vend);

                "Pay-to Name" := Vend.Name;
                "Pay-to Name 2" := Vend."Name 2";
                CopyPayToVendorAddressFieldsFromVendor(Vend, false);
                if not SkipPayToContact then
                    "Pay-to Contact" := Vend.Contact;
                "Payment Terms Code" := Vend."Payment Terms Code";
                "Prepmt. Payment Terms Code" := Vend."Payment Terms Code";
                "Payment Method Code" := Vend."Payment Method Code";
                "Price Calculation Method" := Vend.GetPriceCalculationMethod();

                if "Buy-from Vendor No." = Vend."No." then
                    "Shipment Method Code" := Vend."Shipment Method Code";
                "Vendor Posting Group" := Vend."Vendor Posting Group";
                GLSetup.Get();
                if GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." then begin
                    "VAT Bus. Posting Group" := Vend."VAT Bus. Posting Group";
                    "VAT Country/Region Code" := Vend."Country/Region Code";
                    "VAT Registration No." := Vend."VAT Registration No.";
                    "Gen. Bus. Posting Group" := Vend."Gen. Bus. Posting Group";
                end;
                "Prices Including VAT" := Vend."Prices Including VAT";
                "Currency Code" := Vend."Currency Code";
                "Invoice Disc. Code" := Vend."Invoice Disc. Code";
                "Language Code" := Vend."Language Code";
                SetPurchaserCode(Vend."Purchaser Code", "Purchaser Code");
                Validate("Payment Terms Code");
                Validate("Prepmt. Payment Terms Code");
                Validate("Payment Method Code");
                Validate("Currency Code");
                Validate("Creditor No.", Vend."Creditor No.");
                OnValidatePurchaseHeaderPayToVendorNo(Vend, Rec);
                OnValidatePurchaseHeaderPayToVendorNoOnBeforeCheckDocType(Vend, Rec, xRec);

                if "Document Type" = "Document Type"::Order then
                    Validate("Prepayment %", Vend."Prepayment %");

                if "Pay-to Vendor No." = xRec."Pay-to Vendor No." then begin
                    if ReceivedPurchLinesExist then
                        TestField("Currency Code", xRec."Currency Code");
                end;

                CreateDim(
                  DATABASE::Vendor, "Pay-to Vendor No.",
                  DATABASE::"Salesperson/Purchaser", "Purchaser Code",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center");

                OnValidatePaytoVendorNoBeforeRecreateLines(Rec, CurrFieldNo);

                if (xRec."Buy-from Vendor No." = "Buy-from Vendor No.") and
                   (xRec."Pay-to Vendor No." <> "Pay-to Vendor No.")
                then
                    RecreatePurchLines(PayToVendorTxt);

                if not SkipPayToContact then
                    UpdatePayToCont("Pay-to Vendor No.");

                "Pay-to IC Partner Code" := Vend."IC Partner Code";

                OnValidatePayToVendorNoOnBeforeRecallModifyAddressNotification(Rec, xRec, Vend);
                if (xRec."Pay-to Vendor No." <> '') and (xRec."Pay-to Vendor No." <> "Pay-to Vendor No.") then
                    RecallModifyAddressNotification(GetModifyPayToVendorAddressNotificationId);
            end;
        }
        field(5; "Pay-to Name"; Text[100])
        {
            Caption = 'Pay-to Name';
            TableRelation = Vendor.Name;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                Vendor: Record Vendor;
            begin
                if "Pay-to Vendor No." <> '' then
                    Vendor.Get("Pay-to Vendor No.");

                if Vendor.LookupVendor(Vendor) then begin
                    xRec := Rec;
                    "Pay-to Name" := Vendor.Name;
                    Validate("Pay-to Vendor No.", Vendor."No.");
                end;
            end;

            trigger OnValidate()
            var
                Vendor: Record Vendor;
            begin
                if ShouldSearchForVendorByName("Pay-to Vendor No.") then
                    Validate("Pay-to Vendor No.", Vendor.GetVendorNo("Pay-to Name"));
            end;
        }
        field(6; "Pay-to Name 2"; Text[50])
        {
            Caption = 'Pay-to Name 2';
        }
        field(7; "Pay-to Address"; Text[100])
        {
            Caption = 'Pay-to Address';

            trigger OnValidate()
            begin
                ModifyPayToVendorAddress();
            end;
        }
        field(8; "Pay-to Address 2"; Text[50])
        {
            Caption = 'Pay-to Address 2';

            trigger OnValidate()
            begin
                ModifyPayToVendorAddress();
            end;
        }
        field(9; "Pay-to City"; Text[30])
        {
            Caption = 'Pay-to City';
            TableRelation = IF ("Pay-to Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Pay-to Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Pay-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                LookupPostCode("Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code", CurrFieldNo);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                ModifyPayToVendorAddress();
            end;
        }
        field(10; "Pay-to Contact"; Text[100])
        {
            Caption = 'Pay-to Contact';

            trigger OnLookup()
            var
                Contact: Record Contact;
            begin
                Contact.FilterGroup(2);
                LookupContact("Pay-to Vendor No.", "Pay-to Contact No.", Contact);
                if PAGE.RunModal(0, Contact) = ACTION::LookupOK then
                    Validate("Pay-to Contact No.", Contact."No.");
                Contact.FilterGroup(0);
            end;

            trigger OnValidate()
            begin
                ModifyPayToVendorAddress();
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
            begin
                CheckShipToCodeChange(Rec);

                if "Ship-to Code" <> '' then begin
                    ShipToAddr.Get("Sell-to Customer No.", "Ship-to Code");
                    SetShipToAddress(
                      ShipToAddr.Name, ShipToAddr."Name 2", ShipToAddr.Address, ShipToAddr."Address 2",
                      ShipToAddr.City, ShipToAddr."Post Code", ShipToAddr.County, ShipToAddr."Country/Region Code");
                    "Ship-to Contact" := ShipToAddr.Contact;
                    "Shipment Method Code" := ShipToAddr."Shipment Method Code";
                    if ShipToAddr."Location Code" <> '' then
                        Validate("Location Code", ShipToAddr."Location Code");
                end else begin
                    TestField("Sell-to Customer No.");
                    Cust.Get("Sell-to Customer No.");
                    SetShipToAddress(
                      Cust.Name, Cust."Name 2", Cust.Address, Cust."Address 2",
                      Cust.City, Cust."Post Code", Cust.County, Cust."Country/Region Code");
                    "Ship-to Contact" := Cust.Contact;
                    "Shipment Method Code" := Cust."Shipment Method Code";
                    if Cust."Location Code" <> '' then
                        Validate("Location Code", Cust."Location Code");
                end;

                OnAfterValidateShipToCode(Rec, Cust, ShipToAddr);
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
                LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code", CurrFieldNo);
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
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Order Date';

            trigger OnValidate()
            begin
                if ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) and
                   not ("Order Date" = xRec."Order Date")
                then
                    PriceMessageIfPurchLinesExist(FieldCaption("Order Date"));
            end;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            var
                SkipJobCurrFactorUpdate: Boolean;
            begin
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

                if "Incoming Document Entry No." = 0 then
                    ValidateDocumentDateWithPostingDate();

                if ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) and
                   not ("Posting Date" = xRec."Posting Date")
                then
                    PriceMessageIfPurchLinesExist(FieldCaption("Posting Date"));

                if "Currency Code" <> '' then begin
                    UpdateCurrencyFactor();
                    if ("Currency Factor" <> xRec."Currency Factor") and not CalledFromWhseDoc then
                        SkipJobCurrFactorUpdate := not ConfirmCurrencyFactorUpdate();
                end;

                if "Posting Date" <> xRec."Posting Date" then
                    if DeferralHeadersExist then
                        ConfirmUpdateDeferralDate();

                if PurchLinesExist then
                    JobUpdatePurchLines(SkipJobCurrFactorUpdate);
            end;
        }
        field(21; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';

            trigger OnValidate()
            begin
                if "Expected Receipt Date" <> 0D then
                    UpdatePurchLinesByFieldNo(FieldNo("Expected Receipt Date"), CurrFieldNo <> 0);
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
                    if IsCreditDocType() and not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
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
                if xRec."Payment Terms Code" = "Prepmt. Payment Terms Code" then
                    Validate("Prepmt. Payment Terms Code", "Payment Terms Code");
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
                    TestStatusOpen();
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
            begin
                TestStatusOpen();
            end;
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                OnBeforeValidateLocationCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if ("Location Code" <> xRec."Location Code") and
                   (xRec."Buy-from Vendor No." = "Buy-from Vendor No.")
                then
                    MessageIfPurchLinesExist(FieldCaption("Location Code"));

                UpdateShipToAddress();
                UpdateInboundWhseHandlingTime;
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
        field(31; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            Editable = false;
            TableRelation = "Vendor Posting Group";
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
                    TestStatusOpen();
                if (CurrFieldNo <> FieldNo("Currency Code")) and ("Currency Code" = xRec."Currency Code") then
                    UpdateCurrencyFactor
                else
                    if "Currency Code" <> xRec."Currency Code" then
                        UpdateCurrencyFactor
                    else
                        if "Currency Code" <> '' then begin
                            UpdateCurrencyFactor();
                            if "Currency Factor" <> xRec."Currency Factor" then
                                ConfirmCurrencyFactorUpdate();
                        end;

                if ("No." <> '') and ("Currency Code" <> xRec."Currency Code") then
                    StandardCodesMgt.CheckShowPurchRecurringLinesNotification(Rec);
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
                    UpdatePurchLinesByFieldNo(FieldNo("Currency Factor"), CurrFieldNo <> 0);
            end;
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';

            trigger OnValidate()
            var
                PurchLine: Record "Purchase Line";
                Currency: Record Currency;
                ConfirmManagement: Codeunit "Confirm Management";
                RecalculatePrice: Boolean;
                VatFactor: Decimal;
                LineInvDiscAmt: Decimal;
                InvDiscRounding: Decimal;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePricesIncludingVAT(Rec, PurchLine, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();

                if "Prices Including VAT" <> xRec."Prices Including VAT" then begin
                    PurchLine.SetRange("Document Type", "Document Type");
                    PurchLine.SetRange("Document No.", "No.");
                    PurchLine.SetFilter("Direct Unit Cost", '<>%1', 0);
                    PurchLine.SetFilter("VAT %", '<>%1', 0);
                    if PurchLine.Find('-') then begin
                        if GetHideValidationDialog or not GuiAllowed then
                            RecalculatePrice := true
                        else
                            RecalculatePrice :=
                              ConfirmManagement.GetResponseOrDefault(
                                StrSubstNo(
                                  Text025 +
                                  Text027,
                                  FieldCaption("Prices Including VAT"), PurchLine.FieldCaption("Direct Unit Cost")),
                                true);
                        OnAfterConfirmPurchPrice(Rec, PurchLine, RecalculatePrice);
                        PurchLine.SetPurchHeader(Rec);

                        Currency.Initialize("Currency Code");

                        PurchLine.FindSet();
                        repeat
                            PurchLine.TestField("Quantity Invoiced", 0);
                            PurchLine.TestField("Prepmt. Amt. Inv.", 0);
                            if not RecalculatePrice then begin
                                PurchLine."VAT Difference" := 0;
                                PurchLine.UpdateAmounts;
                            end else begin
                                VatFactor := 1 + PurchLine."VAT %" / 100;
                                if VatFactor = 0 then
                                    VatFactor := 1;
                                if not "Prices Including VAT" then
                                    VatFactor := 1 / VatFactor;
                                if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Full VAT" then
                                    VatFactor := 1;
                                PurchLine."Direct Unit Cost" :=
                                  Round(PurchLine."Direct Unit Cost" * VatFactor, Currency."Unit-Amount Rounding Precision");
                                PurchLine."Line Discount Amount" :=
                                  Round(
                                    PurchLine.Quantity * PurchLine."Direct Unit Cost" * PurchLine."Line Discount %" / 100,
                                    Currency."Amount Rounding Precision");
                                LineInvDiscAmt := InvDiscRounding + PurchLine."Inv. Discount Amount" * VatFactor;
                                PurchLine."Inv. Discount Amount" := Round(LineInvDiscAmt, Currency."Amount Rounding Precision");
                                InvDiscRounding := LineInvDiscAmt - PurchLine."Inv. Discount Amount";
                                if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Full VAT" then
                                    PurchLine."Line Amount" := PurchLine."Amount Including VAT"
                                else
                                    if "Prices Including VAT" then
                                        PurchLine."Line Amount" := PurchLine."Amount Including VAT" + PurchLine."Inv. Discount Amount"
                                    else
                                        PurchLine."Line Amount" := PurchLine.Amount + PurchLine."Inv. Discount Amount";
                                UpdatePrepmtAmounts(PurchLine);
                            end;
                            OnValidatePricesIncludingVATOnBeforePurchLineModify(PurchHeader, PurchLine, Currency, RecalculatePrice);
                            PurchLine.Modify();
                        until PurchLine.Next() = 0;
                    end;
                    OnAfterChangePricesIncludingVAT(Rec);
                end;
            end;
        }
        field(37; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';

            trigger OnValidate()
            begin
                TestStatusOpen();
                MessageIfPurchLinesExist(FieldCaption("Invoice Disc. Code"));
            end;
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnValidate()
            begin
                MessageIfPurchLinesExist(FieldCaption("Language Code"));
            end;
        }
        field(43; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            var
                ApprovalEntry: Record "Approval Entry";
                EnumAssignmentMgt: Codeunit "Enum Assignment Management";
            begin
                ValidatePurchaserOnPurchHeader(Rec, false, false);

                ApprovalEntry.SetRange("Table ID", DATABASE::"Purchase Header");
                ApprovalEntry.SetRange("Document Type", EnumAssignmentMgt.GetPurchApprovalDocumentType("Document Type"));
                ApprovalEntry.SetRange("Document No.", "No.");
                ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Created, ApprovalEntry.Status::Open);
                if not ApprovalEntry.IsEmpty() then
                    Error(Text042, FieldCaption("Purchaser Code"));

                CreateDim(
                  DATABASE::"Salesperson/Purchaser", "Purchaser Code",
                  DATABASE::Vendor, "Pay-to Vendor No.",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center");
            end;
        }
        field(45; "Order Class"; Code[10])
        {
            Caption = 'Order Class';
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = Exist("Purch. Comment Line" WHERE("Document Type" = FIELD("Document Type"),
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
                ApplyVendEntries: Page "Apply Vendor Entries";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupAppliesToDocNo(Rec, VendLedgEntry, IsHandled);
                if IsHandled then
                    exit;

                TestField("Bal. Account No.", '');
                VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
                VendLedgEntry.SetRange("Vendor No.", "Pay-to Vendor No.");
                VendLedgEntry.SetRange(Open, true);
                if "Applies-to Doc. No." <> '' then begin
                    VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                    VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    if VendLedgEntry.FindFirst then;
                    VendLedgEntry.SetRange("Document Type");
                    VendLedgEntry.SetRange("Document No.");
                end else
                    if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
                        VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                        if VendLedgEntry.FindFirst then;
                        VendLedgEntry.SetRange("Document Type");
                    end else
                        if Amount <> 0 then begin
                            VendLedgEntry.SetRange(Positive, Amount < 0);
                            if VendLedgEntry.FindFirst then;
                            VendLedgEntry.SetRange(Positive);
                        end;
                ApplyVendEntries.SetPurch(Rec, VendLedgEntry, PurchHeader.FieldNo("Applies-to Doc. No."));
                ApplyVendEntries.SetTableView(VendLedgEntry);
                ApplyVendEntries.SetRecord(VendLedgEntry);
                ApplyVendEntries.LookupMode(true);
                if ApplyVendEntries.RunModal = ACTION::LookupOK then begin
                    ApplyVendEntries.GetVendLedgEntry(VendLedgEntry);
                    GenJnlApply.CheckAgainstApplnCurrency(
                      "Currency Code", VendLedgEntry."Currency Code", GenJnlLine."Account Type"::Vendor, true);
                    "Applies-to Doc. Type" := VendLedgEntry."Document Type";
                    "Applies-to Doc. No." := VendLedgEntry."Document No.";
                    OnAfterAppliesToDocNoOnLookup(Rec, VendLedgEntry);
                end;
                Clear(ApplyVendEntries);
            end;

            trigger OnValidate()
            begin
                if "Applies-to Doc. No." <> '' then
                    TestField("Bal. Account No.", '');

                if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (xRec."Applies-to Doc. No." <> '') and
                   ("Applies-to Doc. No." <> '')
                then begin
                    SetAmountToApply("Applies-to Doc. No.", "Buy-from Vendor No.");
                    SetAmountToApply(xRec."Applies-to Doc. No.", "Buy-from Vendor No.");
                end else
                    if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (xRec."Applies-to Doc. No." = '') then
                        SetAmountToApply("Applies-to Doc. No.", "Buy-from Vendor No.")
                    else
                        if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and ("Applies-to Doc. No." = '') then
                            SetAmountToApply(xRec."Applies-to Doc. No.", "Buy-from Vendor No.");
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
            CalcFormula = Exist("Purchase Line" WHERE("Document Type" = FIELD("Document Type"),
                                                       "Document No." = FIELD("No."),
                                                       "Recalculate Invoice Disc." = CONST(true)));
            Caption = 'Recalculate Invoice Disc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; Receive; Boolean)
        {
            Caption = 'Receive';
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
            CalcFormula = Sum("Purchase Line".Amount WHERE("Document Type" = FIELD("Document Type"),
                                                            "Document No." = FIELD("No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum("Purchase Line"."Amount Including VAT" WHERE("Document Type" = FIELD("Document Type"),
                                                                            "Document No." = FIELD("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Receiving No."; Code[20])
        {
            Caption = 'Receiving No.';
        }
        field(63; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
        }
        field(64; "Last Receiving No."; Code[20])
        {
            Caption = 'Last Receiving No.';
            Editable = false;
            TableRelation = "Purch. Rcpt. Header";
        }
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            Editable = false;
            TableRelation = "Purch. Inv. Header";
        }
        field(66; "Vendor Order No."; Code[35])
        {
            Caption = 'Vendor Order No.';
        }
        field(67; "Vendor Shipment No."; Code[35])
        {
            Caption = 'Vendor Shipment No.';

            trigger OnValidate()
            var
                WhsePurchRelease: Codeunit "Whse.-Purch. Release";
            begin
                if (xRec."Vendor Shipment No." <> "Vendor Shipment No.") and (Status = Status::Released) and
                   ("Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"])
                then
                    WhsePurchRelease.UpdateExternalDocNoForReleasedOrder(Rec);
            end;
        }
        field(68; "Vendor Invoice No."; Code[35])
        {
            Caption = 'Vendor Invoice No.';

            trigger OnValidate()
            var
                VendorLedgerEntry: Record "Vendor Ledger Entry";
            begin
                if "Vendor Invoice No." <> '' then
                    if FindPostedDocumentWithSameExternalDocNo(VendorLedgerEntry, "Vendor Invoice No.") then
                        ShowExternalDocAlreadyExistNotification(VendorLedgerEntry)
                    else
                        RecallExternalDocAlreadyExistsNotification;
            end;
        }
        field(69; "Vendor Cr. Memo No."; Code[35])
        {
            Caption = 'Vendor Cr. Memo No.';

            trigger OnValidate()
            var
                VendorLedgerEntry: Record "Vendor Ledger Entry";
            begin
                if "Vendor Cr. Memo No." <> '' then
                    if FindPostedDocumentWithSameExternalDocNo(VendorLedgerEntry, "Vendor Cr. Memo No.") then
                        ShowExternalDocAlreadyExistNotification(VendorLedgerEntry)
                    else
                        RecallExternalDocAlreadyExistsNotification;
            end;
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(72; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            begin
                if ("Document Type" = "Document Type"::Order) and
                   (xRec."Sell-to Customer No." <> "Sell-to Customer No.")
                then begin
                    PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                    PurchLine.SetRange("Document No.", "No.");
                    PurchLine.SetFilter("Sales Order Line No.", '<>0');
                    if not PurchLine.IsEmpty() then
                        Error(
                          YouCannotChangeFieldErr,
                          FieldCaption("Sell-to Customer No."));

                    CheckSpecialOrderSalesLineLink();
                end;

                if "Sell-to Customer No." = '' then
                    UpdateLocationCode('')
                else
                    SetShipToCodeEmpty();
            end;
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
                TestStatusOpen();
                if (xRec."Buy-from Vendor No." = "Buy-from Vendor No.") and
                   (xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group")
                then begin
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        "VAT Bus. Posting Group" := GenBusPostingGrp."Def. VAT Bus. Posting Group";
                    RecreatePurchLines(FieldCaption("Gen. Bus. Posting Group"));
                end;
            end;
        }
        field(76; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";

            trigger OnValidate()
            begin
                UpdatePurchLinesByFieldNo(FieldNo("Transaction Type"), CurrFieldNo <> 0);
            end;
        }
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";

            trigger OnValidate()
            begin
                UpdatePurchLinesByFieldNo(FieldNo("Transport Method"), CurrFieldNo <> 0);
            end;
        }
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(79; "Buy-from Vendor Name"; Text[100])
        {
            Caption = 'Buy-from Vendor Name';
            TableRelation = Vendor.Name;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                VendorName: Text;
            begin
                VendorName := "Buy-from Vendor Name";
                LookupBuyFromVendorName(VendorName);
                "Buy-from Vendor Name" := CopyStr(VendorName, 1, MaxStrLen("Buy-from Vendor Name"));
            end;

            trigger OnValidate()
            var
                Vendor: Record Vendor;
                LookupStateManager: Codeunit "Lookup State Manager";
                StandardCodesMgt: Codeunit "Standard Codes Mgt.";
            begin
                if LookupStateManager.IsRecordSaved() then begin
                    Vendor := LookupStateManager.GetSavedRecord();
                    if Vendor."No." <> '' then begin
                        LookupStateManager.ClearSavedRecord();
                        Validate("Buy-from Vendor No.", Vendor."No.");
                        if "No." <> '' then
                            StandardCodesMgt.CheckCreatePurchRecurringLines(Rec);
                        OnLookupBuyfromVendorNameOnAfterSuccessfulLookup(Rec);
                        exit;
                    end;
                end;

                if ShouldSearchForVendorByName("Buy-from Vendor No.") then
                    Validate("Buy-from Vendor No.", Vendor.GetVendorNo("Buy-from Vendor Name"));
            end;
        }
        field(80; "Buy-from Vendor Name 2"; Text[50])
        {
            Caption = 'Buy-from Vendor Name 2';
        }
        field(81; "Buy-from Address"; Text[100])
        {
            Caption = 'Buy-from Address';

            trigger OnValidate()
            begin
                UpdatePayToAddressFromBuyFromAddress(FieldNo("Pay-to Address"));
                ModifyVendorAddress();
            end;
        }
        field(82; "Buy-from Address 2"; Text[50])
        {
            Caption = 'Buy-from Address 2';

            trigger OnValidate()
            begin
                UpdatePayToAddressFromBuyFromAddress(FieldNo("Pay-to Address 2"));
                ModifyVendorAddress();
            end;
        }
        field(83; "Buy-from City"; Text[30])
        {
            Caption = 'Buy-from City';
            TableRelation = IF ("Buy-from Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Buy-from Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Buy-from Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                IsHandled: boolean;
            begin
                IsHandled := false;
                OnBuyFromCityOnBeforeOnLookup(Rec, PostCode, IsHandled);
                if IsHandled then
                    exit;
                LookupPostCode("Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code", CurrFieldNo);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                UpdatePayToAddressFromBuyFromAddress(FieldNo("Pay-to City"));
                ModifyVendorAddress();
            end;
        }
        field(84; "Buy-from Contact"; Text[100])
        {
            Caption = 'Buy-from Contact';

            trigger OnLookup()
            var
                Contact: Record Contact;
            begin
                if "Buy-from Vendor No." = '' then
                    exit;

                Contact.FilterGroup(2);
                LookupContact("Buy-from Vendor No.", "Buy-from Contact No.", Contact);
                if PAGE.RunModal(0, Contact) = ACTION::LookupOK then
                    Validate("Buy-from Contact No.", Contact."No.");
                Contact.FilterGroup(0);
            end;

            trigger OnValidate()
            begin
                ModifyVendorAddress();
            end;
        }
        field(85; "Pay-to Post Code"; Code[20])
        {
            Caption = 'Pay-to Post Code';
            TableRelation = IF ("Pay-to Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Pay-to Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Pay-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                LookupPostCode("Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code", CurrFieldNo);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                ModifyPayToVendorAddress();
            end;
        }
        field(86; "Pay-to County"; Text[30])
        {
            CaptionClass = '5,1,' + "Pay-to Country/Region Code";
            Caption = 'Pay-to County';

            trigger OnValidate()
            begin
                ModifyPayToVendorAddress();
            end;
        }
        field(87; "Pay-to Country/Region Code"; Code[10])
        {
            Caption = 'Pay-to Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                ModifyPayToVendorAddress();
            end;
        }
        field(88; "Buy-from Post Code"; Code[20])
        {
            Caption = 'Buy-from Post Code';
            TableRelation = IF ("Buy-from Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Buy-from Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Buy-from Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBuyFromPostCodeOnBeforeOnLookup(Rec, IsHandled);
                if IsHandled then
                    exit;

                LookupPostCode("Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code", CurrFieldNo);
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Buy-from City", "Buy-from Post Code", "Buy-from County", "Buy-from Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                UpdatePayToAddressFromBuyFromAddress(FieldNo("Pay-to Post Code"));
                ModifyVendorAddress();
            end;
        }
        field(89; "Buy-from County"; Text[30])
        {
            CaptionClass = '5,1,' + "Buy-from Country/Region Code";
            Caption = 'Buy-from County';

            trigger OnValidate()
            begin
                UpdatePayToAddressFromBuyFromAddress(FieldNo("Pay-to County"));
                ModifyVendorAddress();
            end;
        }
        field(90; "Buy-from Country/Region Code"; Code[10])
        {
            Caption = 'Buy-from Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                UpdatePayToAddressFromBuyFromAddress(FieldNo("Pay-to Country/Region Code"));
                ModifyVendorAddress();
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
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnShipToPostCodeOnBeforeOnLookup(Rec, IsHandled, PostCode);
                if IsHandled then
                    exit;

                LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code", CurrFieldNo);
            end;

            trigger OnValidate()
            begin
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
        field(95; "Order Address Code"; Code[10])
        {
            Caption = 'Order Address Code';
            TableRelation = "Order Address".Code WHERE("Vendor No." = FIELD("Buy-from Vendor No."));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "Order Address Code" <> '' then
                    CopyAddressInfoFromOrderAddress()
                else begin
                    GetVend("Buy-from Vendor No.");
                    "Buy-from Vendor Name" := Vend.Name;
                    "Buy-from Vendor Name 2" := Vend."Name 2";
                    CopyBuyFromVendorAddressFieldsFromVendor(Vend, true);

                    OnValidateOrderAddressCodeOnAfterCopyBuyFromVendorAddressFieldsFromVendor(Rec, Vend);

                    if IsCreditDocType() then begin
                        "Ship-to Name" := Vend.Name;
                        "Ship-to Name 2" := Vend."Name 2";
                        CopyShipToVendorAddressFieldsFromVendor(Vend, true);
                        "Ship-to Contact" := Vend.Contact;
                        "Shipment Method Code" := Vend."Shipment Method Code";
                        IsHandled := false;
                        OnValidateOrderAddressCodeOnBeforeUpdateLocationCode(Rec, xRec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            if Vend."Location Code" <> '' then
                                Validate("Location Code", Vend."Location Code");
                    end
                end;
            end;
        }
        field(97; "Entry Point"; Code[10])
        {
            Caption = 'Entry Point';
            TableRelation = "Entry/Exit Point";

            trigger OnValidate()
            begin
                UpdatePurchLinesByFieldNo(FieldNo("Entry Point"), CurrFieldNo <> 0);
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
            begin
                if xRec."Document Date" <> "Document Date" then
                    UpdateDocumentDate := true;
                Validate("Payment Terms Code");
                Validate("Prepmt. Payment Terms Code");
            end;
        }
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;

            trigger OnValidate()
            begin
                UpdatePurchLinesByFieldNo(FieldNo(Area), CurrFieldNo <> 0);
            end;
        }
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";

            trigger OnValidate()
            begin
                UpdatePurchLinesByFieldNo(FieldNo("Transaction Specification"), CurrFieldNo <> 0);
            end;
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            begin
                PaymentMethod.Init();
                if "Payment Method Code" <> '' then
                    PaymentMethod.Get("Payment Method Code");
                "Bal. Account Type" := PaymentMethod."Bal. Account Type";
                "Bal. Account No." := PaymentMethod."Bal. Account No.";
                if "Bal. Account No." <> '' then begin
                    TestField("Applies-to Doc. No.", '');
                    TestField("Applies-to ID", '');
                end;
            end;
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
                with PurchHeader do begin
                    PurchHeader := Rec;
                    GetPurchSetup();
                    TestNoSeries();
                    if NoSeriesMgt.LookupSeries(GetPostingNoSeriesCode, "Posting No. Series") then
                        Validate("Posting No. Series");
                    Rec := PurchHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Posting No. Series" <> '' then begin
                    GetPurchSetup();
                    TestNoSeries();
                    NoSeriesMgt.TestSeries(GetPostingNoSeriesCode, "Posting No. Series");
                end;
                TestField("Posting No.", '');
            end;
        }
        field(109; "Receiving No. Series"; Code[20])
        {
            Caption = 'Receiving No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupReceivingNoSeries(rec, IsHandled);
                if IsHandled then
                    exit;

                with PurchHeader do begin
                    PurchHeader := Rec;
                    GetPurchSetup();
                    PurchSetup.TestField("Posted Receipt Nos.");
                    if NoSeriesMgt.LookupSeries(PurchSetup."Posted Receipt Nos.", "Receiving No. Series") then
                        Validate("Receiving No. Series");
                    Rec := PurchHeader;
                end;
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateReceivingNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Receiving No. Series" <> '' then begin
                    GetPurchSetup();
                    PurchSetup.TestField("Posted Receipt Nos.");
                    NoSeriesMgt.TestSeries(PurchSetup."Posted Receipt Nos.", "Receiving No. Series");
                end;
                TestField("Receiving No.", '');
            end;
        }
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                TestStatusOpen();
                MessageIfPurchLinesExist(FieldCaption("Tax Area Code"));
            end;
        }
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                TestStatusOpen();
                MessageIfPurchLinesExist(FieldCaption("Tax Liable"));
            end;
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if (xRec."Buy-from Vendor No." = "Buy-from Vendor No.") and
                   (xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group")
                then
                    RecreatePurchLines(FieldCaption("VAT Bus. Posting Group"));
            end;
        }
        field(118; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            var
                TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
                VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
            begin
                if "Applies-to ID" <> '' then
                    TestField("Bal. Account No.", '');
                if ("Applies-to ID" <> xRec."Applies-to ID") and (xRec."Applies-to ID" <> '') then begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", Open);
                    VendLedgEntry.SetRange("Vendor No.", "Pay-to Vendor No.");
                    VendLedgEntry.SetRange(Open, true);
                    VendLedgEntry.SetRange("Applies-to ID", xRec."Applies-to ID");
                    if VendLedgEntry.FindFirst() then
                        VendEntrySetApplID.SetApplId(VendLedgEntry, TempVendLedgEntry, '');
                    VendLedgEntry.Reset();
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
            var
                IsHandled: Boolean;
            begin
                GLSetup.Get();
                if "VAT Base Discount %" > GLSetup."VAT Tolerance %" then begin
                    if GetHideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed :=
                          Confirm(
                            Text007 +
                            Text008, false,
                            FieldCaption("VAT Base Discount %"),
                            GLSetup.FieldCaption("VAT Tolerance %"),
                            GLSetup.TableCaption);
                    if not Confirmed then
                        "VAT Base Discount %" := xRec."VAT Base Discount %";
                end;

                if ("VAT Base Discount %" = xRec."VAT Base Discount %") and (CurrFieldNo <> 0) then
                    exit;

                IsHandled := false;
                OnValidateVATBaseAmountPercOnBeforeUpdatePurchAmountLines(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then
                    UpdatePurchAmountLines();
            end;
        }
        field(120; Status; Enum "Purchase Document Status")
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
                    TestField("Buy-from IC Partner Code");
                    TestField("IC Direction", "IC Direction"::Outgoing);
                end;
            end;
        }
        field(124; "IC Status"; Enum "Purchase Document IC Status")
        {
            Caption = 'IC Status';
        }
        field(125; "Buy-from IC Partner Code"; Code[20])
        {
            Caption = 'Buy-from IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(126; "Pay-to IC Partner Code"; Code[20])
        {
            Caption = 'Pay-to IC Partner Code';
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
        field(130; "Prepayment No."; Code[20])
        {
            Caption = 'Prepayment No.';
        }
        field(131; "Last Prepayment No."; Code[20])
        {
            Caption = 'Last Prepayment No.';
            TableRelation = "Purch. Inv. Header";
        }
        field(132; "Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No.';
        }
        field(133; "Last Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Last Prepmt. Cr. Memo No.';
            TableRelation = "Purch. Cr. Memo Hdr.";
        }
        field(134; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if xRec."Prepayment %" <> "Prepayment %" then
                    UpdatePurchLinesByFieldNo(FieldNo("Prepayment %"), CurrFieldNo <> 0);
            end;
        }
        field(135; "Prepayment No. Series"; Code[20])
        {
            Caption = 'Prepayment No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                with PurchHeader do begin
                    PurchHeader := Rec;
                    GetPurchSetup();
                    PurchSetup.TestField("Posted Prepmt. Inv. Nos.");
                    if NoSeriesMgt.LookupSeries(GetPostingPrepaymentNoSeriesCode, "Prepayment No. Series") then
                        Validate("Prepayment No. Series");
                    Rec := PurchHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Prepayment No. Series" <> '' then begin
                    GetPurchSetup();
                    PurchSetup.TestField("Posted Prepmt. Inv. Nos.");
                    NoSeriesMgt.TestSeries(GetPostingPrepaymentNoSeriesCode, "Prepayment No. Series");
                end;
                TestField("Prepayment No.", '');
            end;
        }
        field(136; "Compress Prepayment"; Boolean)
        {
            Caption = 'Compress Prepayment';
            InitValue = true;
        }
        field(137; "Prepayment Due Date"; Date)
        {
            Caption = 'Prepayment Due Date';
        }
        field(138; "Prepmt. Cr. Memo No. Series"; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                with PurchHeader do begin
                    PurchHeader := Rec;
                    GetPurchSetup();
                    PurchSetup.TestField("Posted Prepmt. Cr. Memo Nos.");
                    if NoSeriesMgt.LookupSeries(GetPostingPrepaymentNoSeriesCode, "Prepmt. Cr. Memo No. Series") then
                        Validate("Prepmt. Cr. Memo No. Series");
                    Rec := PurchHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Prepmt. Cr. Memo No. Series" <> '' then begin
                    GetPurchSetup();
                    PurchSetup.TestField("Posted Prepmt. Cr. Memo Nos.");
                    NoSeriesMgt.TestSeries(GetPostingPrepaymentNoSeriesCode, "Prepmt. Cr. Memo No. Series");
                end;
                TestField("Prepmt. Cr. Memo No.", '');
            end;
        }
        field(139; "Prepmt. Posting Description"; Text[100])
        {
            Caption = 'Prepmt. Posting Description';
        }
        field(142; "Prepmt. Pmt. Discount Date"; Date)
        {
            Caption = 'Prepmt. Pmt. Discount Date';
        }
        field(143; "Prepmt. Payment Terms Code"; Code[10])
        {
            Caption = 'Prepmt. Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            var
                PaymentTerms: Record "Payment Terms";
                IsHandled: Boolean;
            begin
                if ("Prepmt. Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                    PaymentTerms.Get("Prepmt. Payment Terms Code");
                    if IsCreditDocType() and not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
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
                    OnValidatePrepmtPaymentTermsCodeOnCaseElseOnBeforeValidatePrepaymentDueDate(Rec, xRec, CurrFieldNo, IsHandled);
                    if not IsHandled then
                        Validate("Prepayment Due Date", "Document Date");
                    if not UpdateDocumentDate then begin
                        Validate("Prepmt. Pmt. Discount Date", 0D);
                        Validate("Prepmt. Payment Discount %", 0);
                    end;
                end;
            end;
        }
        field(144; "Prepmt. Payment Discount %"; Decimal)
        {
            Caption = 'Prepmt. Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date"), FieldNo("Document Date")]) then
                    TestStatusOpen();
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
                    IncomingDocument.SetPurchDoc(Rec);
            end;
        }
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
        }
        field(171; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
            Numeric = true;
        }
        field(300; "A. Rcd. Not Inv. Ex. VAT (LCY)"; Decimal)
        {
            CalcFormula = Sum("Purchase Line"."A. Rcd. Not Inv. Ex. VAT (LCY)" WHERE("Document Type" = FIELD("Document Type"),
                                                                                      "Document No." = FIELD("No.")));
            Caption = 'Amount Received Not Invoiced (LCY)';
            FieldClass = FlowField;
        }
        field(301; "Amt. Rcd. Not Invoiced (LCY)"; Decimal)
        {
            CalcFormula = Sum("Purchase Line"."Amt. Rcd. Not Invoiced (LCY)" WHERE("Document Type" = FIELD("Document Type"),
                                                                                    "Document No." = FIELD("No.")));
            Caption = 'Amount Received Not Invoiced (LCY) Incl. VAT';
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
        field(1305; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum("Purchase Line"."Inv. Discount Amount" WHERE("Document No." = FIELD("No."),
                                                                            "Document Type" = FIELD("Document Type")));
            Caption = 'Invoice Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5043; "No. of Archived Versions"; Integer)
        {
            CalcFormula = Max("Purchase Header Archive"."Version No." WHERE("Document Type" = FIELD("Document Type"),
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
            begin
                CreateDim(
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::Vendor, "Pay-to Vendor No.",
                  DATABASE::"Salesperson/Purchaser", "Purchaser Code",
                  DATABASE::"Responsibility Center", "Responsibility Center");
            end;
        }
        field(5052; "Buy-from Contact No."; Code[20])
        {
            Caption = 'Buy-from Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
            begin
                if "Buy-from Vendor No." <> '' then
                    if Cont.Get("Buy-from Contact No.") then
                        Cont.SetRange("Company No.", Cont."Company No.")
                    else
                        if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Vendor, "Buy-from Vendor No.") then
                            Cont.SetRange("Company No.", ContBusinessRelation."Contact No.")
                        else
                            Cont.SetRange("No.", '');

                if "Buy-from Contact No." <> '' then
                    if Cont.Get("Buy-from Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    xRec := Rec;
                    Validate("Buy-from Contact No.", Cont."No.");
                end;
            end;

            trigger OnValidate()
            var
                ContBusinessRelation: Record "Contact Business Relation";
                Cont: Record Contact;
            begin
                TestStatusOpen();

                if "Buy-from Contact No." <> '' then
                    if Cont.Get("Buy-from Contact No.") then
                        Cont.CheckIfPrivacyBlockedGeneric;

                if ("Buy-from Contact No." <> xRec."Buy-from Contact No.") and
                   (xRec."Buy-from Contact No." <> '')
                then begin
                    if GetHideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Buy-from Contact No."));
                    if Confirmed then begin
                        if InitFromContact("Buy-from Contact No.", "Buy-from Vendor No.", FieldCaption("Buy-from Contact No.")) then
                            exit
                    end else begin
                        Rec := xRec;
                        exit;
                    end;
                end;

                if ("Buy-from Vendor No." <> '') and ("Buy-from Contact No." <> '') then begin
                    Cont.Get("Buy-from Contact No.");
                    if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Vendor, "Buy-from Vendor No.") then
                        if ContBusinessRelation."Contact No." <> Cont."Company No." then
                            Error(Text038, Cont."No.", Cont.Name, "Buy-from Vendor No.");
                end;

                UpdateBuyFromVend("Buy-from Contact No.");
            end;
        }
        field(5053; "Pay-to Contact No."; Code[20])
        {
            Caption = 'Pay-to Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
            begin
                if "Pay-to Vendor No." <> '' then
                    if Cont.Get("Pay-to Contact No.") then
                        Cont.SetRange("Company No.", Cont."Company No.")
                    else
                        if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Vendor, "Pay-to Vendor No.") then
                            Cont.SetRange("Company No.", ContBusinessRelation."Contact No.")
                        else
                            Cont.SetRange("No.", '');

                if "Pay-to Contact No." <> '' then
                    if Cont.Get("Pay-to Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    xRec := Rec;
                    Validate("Pay-to Contact No.", Cont."No.");
                end;
            end;

            trigger OnValidate()
            var
                ContBusinessRelation: Record "Contact Business Relation";
                Cont: Record Contact;
            begin
                TestStatusOpen();

                if "Pay-to Contact No." <> '' then
                    if Cont.Get("Pay-to Contact No.") then
                        Cont.CheckIfPrivacyBlockedGeneric;

                if ("Pay-to Contact No." <> xRec."Pay-to Contact No.") and
                   (xRec."Pay-to Contact No." <> '')
                then begin
                    if GetHideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Pay-to Contact No."));
                    if Confirmed then begin
                        if InitFromContact("Pay-to Contact No.", "Pay-to Vendor No.", FieldCaption("Pay-to Contact No.")) then
                            exit
                    end else begin
                        "Pay-to Contact No." := xRec."Pay-to Contact No.";
                        exit;
                    end;
                end;

                if ("Pay-to Vendor No." <> '') and ("Pay-to Contact No." <> '') then begin
                    Cont.Get("Pay-to Contact No.");
                    if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Vendor, "Pay-to Vendor No.") then
                        if ContBusinessRelation."Contact No." <> Cont."Company No." then
                            Error(Text038, Cont."No.", Cont.Name, "Pay-to Vendor No.");
                end;

                UpdatePayToVend("Pay-to Contact No.");
            end;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if not UserSetupMgt.CheckRespCenter(1, "Responsibility Center") then
                    Error(
                      Text028,
                      RespCenter.TableCaption, UserSetupMgt.GetPurchasesFilter);

                UpdateLocationCode('');
                UpdateInboundWhseHandlingTime();

                UpdateShipToAddress();

                CreateDim(
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::Vendor, "Pay-to Vendor No.",
                  DATABASE::"Salesperson/Purchaser", "Purchaser Code",
                  DATABASE::Campaign, "Campaign No.");

                if xRec."Responsibility Center" <> "Responsibility Center" then begin
                    RecreatePurchLines(FieldCaption("Responsibility Center"));
                    "Assigned User ID" := '';
                end;
            end;
        }
        field(5751; "Partially Invoiced"; Boolean)
        {
            CalcFormula = Exist("Purchase Line" WHERE("Document Type" = FIELD("Document Type"),
                                                       "Document No." = FIELD("No."),
                                                       Type = FILTER(<> " "),
                                                       "Location Code" = FIELD("Location Filter"),
                                                       "Quantity Invoiced" = FILTER(<> 0)));
            Caption = 'Partially Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752; "Completely Received"; Boolean)
        {
            CalcFormula = Min("Purchase Line"."Completely Received" WHERE("Document Type" = FIELD("Document Type"),
                                                                           "Document No." = FIELD("No."),
                                                                           Type = FILTER(<> " "),
                                                                           "Location Code" = FIELD("Location Filter")));
            Caption = 'Completely Received';
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
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';

            trigger OnValidate()
            begin
                if "Promised Receipt Date" <> 0D then
                    Error(
                      Text034,
                      FieldCaption("Requested Receipt Date"),
                      FieldCaption("Promised Receipt Date"));

                if "Requested Receipt Date" <> xRec."Requested Receipt Date" then
                    UpdatePurchLinesByFieldNo(FieldNo("Requested Receipt Date"), CurrFieldNo <> 0);
            end;
        }
        field(5791; "Promised Receipt Date"; Date)
        {
            Caption = 'Promised Receipt Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePromisedReceiptDate(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if "Promised Receipt Date" <> xRec."Promised Receipt Date" then
                    UpdatePurchLinesByFieldNo(FieldNo("Promised Receipt Date"), CurrFieldNo <> 0);
            end;
        }
        field(5792; "Lead Time Calculation"; DateFormula)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lead Time Calculation';

            trigger OnValidate()
            begin
                LeadTimeMgt.CheckLeadTimeIsNotNegative("Lead Time Calculation");

                if "Lead Time Calculation" <> xRec."Lead Time Calculation" then
                    UpdatePurchLinesByFieldNo(FieldNo("Lead Time Calculation"), CurrFieldNo <> 0);
            end;
        }
        field(5793; "Inbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Inbound Whse. Handling Time';

            trigger OnValidate()
            begin
                if "Inbound Whse. Handling Time" <> xRec."Inbound Whse. Handling Time" then
                    UpdatePurchLinesByFieldNo(FieldNo("Inbound Whse. Handling Time"), CurrFieldNo <> 0);
            end;
        }
        field(5796; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5800; "Vendor Authorization No."; Code[35])
        {
            Caption = 'Vendor Authorization No.';
        }
        field(5801; "Return Shipment No."; Code[20])
        {
            Caption = 'Return Shipment No.';
        }
        field(5802; "Return Shipment No. Series"; Code[20])
        {
            Caption = 'Return Shipment No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupReturnShipmentNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                with PurchHeader do begin
                    PurchHeader := Rec;
                    GetPurchSetup();
                    PurchSetup.TestField("Posted Return Shpt. Nos.");
                    if NoSeriesMgt.LookupSeries(PurchSetup."Posted Return Shpt. Nos.", "Return Shipment No. Series") then
                        Validate("Return Shipment No. Series");
                    Rec := PurchHeader;
                end;
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateReturnShipmentNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Return Shipment No. Series" <> '' then begin
                    GetPurchSetup();
                    PurchSetup.TestField("Posted Return Shpt. Nos.");
                    NoSeriesMgt.TestSeries(PurchSetup."Posted Return Shpt. Nos.", "Return Shipment No. Series");
                end;
                TestField("Return Shipment No.", '');
            end;
        }
        field(5803; Ship; Boolean)
        {
            Caption = 'Ship';
        }
        field(5804; "Last Return Shipment No."; Code[20])
        {
            Caption = 'Last Return Shipment No.';
            Editable = false;
            TableRelation = "Return Shipment Header";
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
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
                if not UserSetupMgt.CheckRespCenter(1, "Responsibility Center", "Assigned User ID") then
                    Error(
                      Text049, "Assigned User ID",
                      RespCenter.TableCaption, UserSetupMgt.GetPurchasesFilter("Assigned User ID"));
            end;
        }
        field(9001; "Pending Approvals"; Integer)
        {
            CalcFormula = Count("Approval Entry" WHERE("Table ID" = CONST(38),
                                                        "Document Type" = FIELD("Document Type"),
                                                        "Document No." = FIELD("No."),
                                                        Status = FILTER(Open | Created)));
            Caption = 'Pending Approvals';
            FieldClass = FlowField;
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
        key(Key3; "Document Type", "Buy-from Vendor No.")
        {
        }
        key(Key4; "Document Type", "Pay-to Vendor No.")
        {
        }
        key(Key5; "Buy-from Vendor No.")
        {
        }
        key(Key6; "Incoming Document Entry No.")
        {
        }
        key(Key7; "Document Date")
        {
        }
        key(Key8; Status, "Expected Receipt Date", "Location Code", "Responsibility Center")
        {
        }
        key(Key9; "Assigned User ID")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Buy-from Vendor Name", "Amount Including VAT")
        {
        }
    }

    trigger OnDelete()
    var
        PurchCommentLine: Record "Purch. Comment Line";
        PostPurchDelete: Codeunit "PostPurch-Delete";
        ArchiveManagement: Codeunit ArchiveManagement;
        ShowPostedDocsToPrint: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        if not UserSetupMgt.CheckRespCenter(1, "Responsibility Center") then
            Error(
              Text023,
              RespCenter.TableCaption, UserSetupMgt.GetPurchasesFilter);

        ArchiveManagement.AutoArchivePurchDocument(Rec);
        PostPurchDelete.DeleteHeader(
          Rec, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader,
          ReturnShptHeader, PurchInvHeaderPrepmt, PurchCrMemoHeaderPrepmt);
        Validate("Applies-to ID", '');
        Validate("Incoming Document Entry No.", 0);

        DeleteRecordInApprovalRequest();
        PurchLine.LockTable();

        WhseRequest.SetRange("Source Type", DATABASE::"Purchase Line");
        WhseRequest.SetRange("Source Subtype", "Document Type");
        WhseRequest.SetRange("Source No.", "No.");
        WhseRequest.DeleteAll(true);

        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        PurchLine.SetRange(Type, PurchLine.Type::"Charge (Item)");
        DeletePurchaseLines();
        PurchLine.SetRange(Type);
        DeletePurchaseLines();

        PurchCommentLine.SetRange("Document Type", "Document Type");
        PurchCommentLine.SetRange("No.", "No.");
        PurchCommentLine.DeleteAll();

        ShowPostedDocsToPrint :=
            (PurchRcptHeader."No." <> '') or (PurchInvHeader."No." <> '') or (PurchCrMemoHeader."No." <> '') or
           (ReturnShptHeader."No." <> '') or (PurchInvHeaderPrepmt."No." <> '') or (PurchCrMemoHeaderPrepmt."No." <> '');
        OnBeforeShowPostedDocsToPrintCreatedMsg(ShowPostedDocsToPrint);
        if ShowPostedDocsToPrint then
            Message(PostedDocsToPrintCreatedMsg);
    end;

    trigger OnInsert()
    var
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
    begin
        InitInsert();

        if GetFilter("Buy-from Vendor No.") <> '' then
            if GetRangeMin("Buy-from Vendor No.") = GetRangeMax("Buy-from Vendor No.") then
                Validate("Buy-from Vendor No.", GetRangeMin("Buy-from Vendor No."));

        if "Purchaser Code" = '' then
            SetDefaultPurchaser();

        if "Buy-from Vendor No." <> '' then
            StandardCodesMgt.CheckCreatePurchRecurringLines(Rec);
    end;

    trigger OnRename()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRename(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        Error(Text003, TableCaption);
    end;

    var
        Text003: Label 'You cannot rename a %1.';
        ConfirmChangeQst: Label 'Do you want to change %1?', Comment = '%1 = a Field Caption like Currency Code';
        Text005: Label 'You cannot reset %1 because the document still has one or more lines.';
        YouCannotChangeFieldErr: Label 'You cannot change %1 because the order is associated with one or more sales orders.', Comment = '%1 - fieldcaption';
        Text007: Label '%1 is greater than %2 in the %3 table.\';
        Text008: Label 'Confirm change?';
        Text009: Label 'Deleting this document will cause a gap in the number series for receipts. An empty receipt %1 will be created to fill this gap in the number series.\\Do you want to continue?', Comment = '%1 = Document No.';
        Text012: Label 'Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice %1 will be created to fill this gap in the number series.\\Do you want to continue?', Comment = '%1 = Document No.';
        Text014: Label 'Deleting this document will cause a gap in the number series for posted credit memos. An empty posted credit memo %1 will be created to fill this gap in the number series.\\Do you want to continue?', Comment = '%1 = Document No.';
        RecreatePurchLinesMsg: Label 'If you change %1, the existing purchase lines will be deleted and new purchase lines based on the new information in the header will be created.\\Do you want to continue?', Comment = '%1: FieldCaption';
        ResetItemChargeAssignMsg: Label 'If you change %1, the existing purchase lines will be deleted and new purchase lines based on the new information in the header will be created.\The amount of the item charge assignment will be reset to 0.\\Do you want to continue?', Comment = '%1: FieldCaption';
        LinesNotUpdatedMsg: Label 'You have changed %1 on the purchase header, but it has not been changed on the existing purchase lines.', Comment = 'You have changed Posting Date on the purchase header, but it has not been changed on the existing purchase lines.';
        LinesNotUpdatedDateMsg: Label 'You have changed the %1 on the purchase order, which might affect the prices and discounts on the purchase order lines. You should review the lines and manually update prices and discounts if needed.', Comment = '%1: OrderDate';
        Text020: Label 'You must update the existing purchase lines manually.';
        AffectExchangeRateMsg: Label 'The change may affect the exchange rate that is used for price calculation on the purchase lines.';
        Text022: Label 'Do you want to update the exchange rate?';
        Text023: Label 'You cannot delete this document. Your identification is set up to process from %1 %2 only.';
        Text025: Label 'You have modified the %1 field. Note that the recalculation of VAT may cause penny differences, so you must check the amounts afterwards. ';
        Text027: Label 'Do you want to update the %2 field on the lines to reflect the new value of %1?';
        Text028: Label 'Your identification is set up to process from %1 %2 only.';
        Text029: Label 'Deleting this document will cause a gap in the number series for return shipments. An empty return shipment %1 will be created to fill this gap in the number series.\\Do you want to continue?', Comment = '%1 = Document No.';
        Text032: Label 'You have modified %1.\\Do you want to update the lines?', Comment = 'You have modified Currency Factor.\\Do you want to update the lines?';
        PurchSetup: Record "Purchases & Payables Setup";
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        PurchLine: Record "Purchase Line";
        xPurchLine: Record "Purchase Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Vend: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        CurrExchRate: Record "Currency Exchange Rate";
        PurchHeader: Record "Purchase Header";
        Cust: Record Customer;
        CompanyInfo: Record "Company Information";
        PostCode: Record "Post Code";
        BankAcc: Record "Bank Account";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        ReturnShptHeader: Record "Return Shipment Header";
        PurchInvHeaderPrepmt: Record "Purch. Inv. Header";
        PurchCrMemoHeaderPrepmt: Record "Purch. Cr. Memo Hdr.";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        RespCenter: Record "Responsibility Center";
        Location: Record Location;
        WhseRequest: Record "Warehouse Request";
        InvtSetup: Record "Inventory Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        UserSetupMgt: Codeunit "User Setup Management";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        PostingSetupMgt: Codeunit PostingSetupManagement;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        CurrencyDate: Date;
        Confirmed: Boolean;
        Text034: Label 'You cannot change the %1 when the %2 has been filled in.';
        Text037: Label 'Contact %1 %2 is not related to vendor %3.';
        Text038: Label 'Contact %1 %2 is related to a different company than vendor %3.';
        Text039: Label 'Contact %1 %2 is not related to a vendor.';
        SkipBuyFromContact: Boolean;
        SkipPayToContact: Boolean;
        Text040: Label 'You can not change the %1 field because %2 %3 has %4 = %5 and the %6 has already been assigned %7 %8.';
        Text042: Label 'You must cancel the approval process if you wish to change the %1.';
        Text045: Label 'Deleting this document will cause a gap in the number series for prepayment invoices. An empty prepayment invoice %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text046: Label 'Deleting this document will cause a gap in the number series for prepayment credit memos. An empty prepayment credit memo %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text049: Label '%1 is set up to process from %2 %3 only.';
        Text050: Label 'Reservations exist for this order. These reservations will be canceled if a date conflict is caused by this change.\\Do you want to continue?';
        Text051: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        Text052: Label 'The %1 field on the purchase order %2 must be the same as on sales order %3.';
        UpdateDocumentDate: Boolean;
        PrepaymentInvoicesNotPaidErr: Label 'You cannot post the document of type %1 with the number %2 before all related prepayment invoices are posted.', Comment = 'You cannot post the document of type Order with the number 1001 before all related prepayment invoices are posted.';
        StatisticsInsuffucientPermissionsErr: Label 'You don''t have permission to view statistics.';
        Text054: Label 'There are unpaid prepayment invoices that are related to the document of type %1 with the number %2.';
        DeferralLineQst: Label 'You have changed the %1 on the purchase header, do you want to update the deferral schedules for the lines with this date?', Comment = '%1=The posting date on the document.';
        PostedDocsToPrintCreatedMsg: Label 'One or more related posted documents have been generated during deletion to fill gaps in the posting number series. You can view or print the documents from the respective document archive.';
        BuyFromVendorTxt: Label 'Buy-from Vendor';
        PayToVendorTxt: Label 'Pay-to Vendor';
        DocumentNotPostedClosePageQst: Label 'The document has been saved but is not yet posted.\\Are you sure you want to exit?';
        SelectNoSeriesAllowed: Boolean;
        MixedDropshipmentErr: Label 'You cannot print the purchase order because it contains one or more lines for drop shipment in addition to regular purchase lines.';
        ModifyVendorAddressNotificationLbl: Label 'Update the address';
        DontShowAgainActionLbl: Label 'Don''t show again';
        ModifyVendorAddressNotificationMsg: Label 'The address you entered for %1 is different from the Vendor''s existing address.', Comment = '%1=Vendor name';
        ModifyBuyFromVendorAddressNotificationNameTxt: Label 'Update Buy-from Vendor Address';
        ModifyBuyFromVendorAddressNotificationDescriptionTxt: Label 'Warn if the Buy-from address on sales documents is different from the Vendor''s existing address.';
        ModifyPayToVendorAddressNotificationNameTxt: Label 'Update Pay-to Vendor Address';
        ModifyPayToVendorAddressNotificationDescriptionTxt: Label 'Warn if the Pay-to address on sales documents is different from the Vendor''s existing address.';
        PurchaseAlreadyExistsTxt: Label 'Purchase %1 %2 already exists for this vendor.', Comment = '%1 = Document Type; %2 = Document No.';
        ShowVendLedgEntryTxt: Label 'Show the vendor ledger entry.';
        ShowDocAlreadyExistNotificationNameTxt: Label 'Purchase document with same external document number already exists.';
        ShowDocAlreadyExistNotificationDescriptionTxt: Label 'Warn if purchase document with same external document number already exists.';
        DuplicatedCaptionsNotAllowedErr: Label 'Field captions must not be duplicated when using this method. Use UpdatePurchLinesByFieldNo instead.';
        SplitMessageTxt: Label '%1\%2', Comment = 'Some message text 1.\Some message text 2.';
        StatusCheckSuspended: Boolean;
        FullPurchaseTypesTxt: Label 'Purchase Quote,Purchase Order,Purchase Invoice,Purchase Credit Memo,Purchase Blanket Order,Purchase Return Order';
        RecreatePurchaseLinesCancelErr: Label 'You must delete the existing purchase lines before you can change %1.', Comment = '%1 - Field Name, Sample:You must delete the existing purchase lines before you can change Currency Code.';
        CalledFromWhseDoc: Boolean;

    protected var
        HideValidationDialog: Boolean;

    procedure InitInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitInsert(Rec, xRec, IsHandled);
        if not IsHandled then
            if "No." = '' then begin
                TestNoSeries();
                NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", "Posting Date", "No.", "No. Series");
            end;

        OnInitInsertOnBeforeInitRecord(Rec, xRec);
        InitRecord();
    end;

    procedure InitRecord()
    var
        ArchiveManagement: Codeunit ArchiveManagement;
        IsHandled: Boolean;
    begin
        GetPurchSetup();
        IsHandled := false;
        OnBeforeInitRecord(Rec, IsHandled, xRec, PurchSetup, GLSetup);
        if not IsHandled then
            case "Document Type" of
                "Document Type"::Quote, "Document Type"::Order:
                    begin
                        NoSeriesMgt.SetDefaultSeries("Posting No. Series", PurchSetup."Posted Invoice Nos.");
                        NoSeriesMgt.SetDefaultSeries("Receiving No. Series", PurchSetup."Posted Receipt Nos.");
                        if "Document Type" = "Document Type"::Order then begin
                            NoSeriesMgt.SetDefaultSeries("Prepayment No. Series", PurchSetup."Posted Prepmt. Inv. Nos.");
                            NoSeriesMgt.SetDefaultSeries("Prepmt. Cr. Memo No. Series", PurchSetup."Posted Prepmt. Cr. Memo Nos.");
                        end;
                    end;
                "Document Type"::Invoice:
                    begin
                        if ("No. Series" <> '') and
                           (PurchSetup."Invoice Nos." = PurchSetup."Posted Invoice Nos.")
                        then
                            "Posting No. Series" := "No. Series"
                        else
                            NoSeriesMgt.SetDefaultSeries("Posting No. Series", PurchSetup."Posted Invoice Nos.");
                        if PurchSetup."Receipt on Invoice" then
                            NoSeriesMgt.SetDefaultSeries("Receiving No. Series", PurchSetup."Posted Receipt Nos.");
                    end;
                "Document Type"::"Return Order":
                    begin
                        NoSeriesMgt.SetDefaultSeries("Posting No. Series", PurchSetup."Posted Credit Memo Nos.");
                        NoSeriesMgt.SetDefaultSeries("Return Shipment No. Series", PurchSetup."Posted Return Shpt. Nos.");
                    end;
                "Document Type"::"Credit Memo":
                    begin
                        if ("No. Series" <> '') and
                           (PurchSetup."Credit Memo Nos." = PurchSetup."Posted Credit Memo Nos.")
                        then
                            "Posting No. Series" := "No. Series"
                        else
                            NoSeriesMgt.SetDefaultSeries("Posting No. Series", PurchSetup."Posted Credit Memo Nos.");
                        if PurchSetup."Return Shipment on Credit Memo" then
                            NoSeriesMgt.SetDefaultSeries("Return Shipment No. Series", PurchSetup."Posted Return Shpt. Nos.");
                    end;
            end;

        if "Document Type" = "Document Type"::Invoice then
            "Expected Receipt Date" := WorkDate;

        if not ("Document Type" in ["Document Type"::"Blanket Order", "Document Type"::Quote]) and
           ("Posting Date" = 0D)
        then
            "Posting Date" := WorkDate;

        if PurchSetup."Default Posting Date" = PurchSetup."Default Posting Date"::"No Date" then
            "Posting Date" := 0D;

        "Order Date" := WorkDate;
        "Document Date" := WorkDate;

        OnInitRecordOnAfterAssignDates(Rec);

        ValidateEmptySellToCustomerAndLocation();

        if IsCreditDocType() then begin
            GLSetup.Get();
            Correction := GLSetup."Mark Cr. Memos as Corrections";
        end;

        "Posting Description" := Format("Document Type") + ' ' + "No.";

        UpdateInboundWhseHandlingTime();

        "Responsibility Center" := UserSetupMgt.GetRespCenter(1, "Responsibility Center");
        "Doc. No. Occurrence" :=
            ArchiveManagement.GetNextOccurrenceNo(DATABASE::"Purchase Header", "Document Type".AsInteger(), "No.");

        OnAfterInitRecord(Rec);
    end;

    local procedure InitNoSeries()
    begin
        if xRec."Receiving No." <> '' then begin
            "Receiving No. Series" := xRec."Receiving No. Series";
            "Receiving No." := xRec."Receiving No.";
        end;
        if xRec."Posting No." <> '' then begin
            "Posting No. Series" := xRec."Posting No. Series";
            "Posting No." := xRec."Posting No.";
        end;
        if xRec."Return Shipment No." <> '' then begin
            "Return Shipment No. Series" := xRec."Return Shipment No. Series";
            "Return Shipment No." := xRec."Return Shipment No.";
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

    procedure AssistEdit(OldPurchHeader: Record "Purchase Header"): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldPurchHeader, IsHandled);
        if IsHandled then
            exit;

        GetPurchSetup();
        TestNoSeries();
        if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldPurchHeader."No. Series", "No. Series") then begin
            TestNoSeries();
            NoSeriesMgt.SetSeries("No.");
            exit(true);
        end;
    end;

    procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        GetPurchSetup();
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, IsHandled);
        if not IsHandled then
            case "Document Type" of
                "Document Type"::Quote:
                    PurchSetup.TestField("Quote Nos.");
                "Document Type"::Order:
                    PurchSetup.TestField("Order Nos.");
                "Document Type"::Invoice:
                    begin
                        PurchSetup.TestField("Invoice Nos.");
                        PurchSetup.TestField("Posted Invoice Nos.");
                    end;
                "Document Type"::"Return Order":
                    PurchSetup.TestField("Return Order Nos.");
                "Document Type"::"Credit Memo":
                    begin
                        PurchSetup.TestField("Credit Memo Nos.");
                        PurchSetup.TestField("Posted Credit Memo Nos.");
                    end;
                "Document Type"::"Blanket Order":
                    PurchSetup.TestField("Blanket Order Nos.");
            end;

        OnAfterTestNoSeries(Rec);
    end;

    procedure GetNoSeriesCode(): Code[20]
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        GetPurchSetup();
        IsHandled := false;
        OnBeforeGetNoSeriesCode(PurchSetup, NoSeriesCode, IsHandled, Rec);
        if IsHandled then
            exit(NoSeriesCode);

        case "Document Type" of
            "Document Type"::Quote:
                NoSeriesCode := PurchSetup."Quote Nos.";
            "Document Type"::Order:
                NoSeriesCode := PurchSetup."Order Nos.";
            "Document Type"::Invoice:
                NoSeriesCode := PurchSetup."Invoice Nos.";
            "Document Type"::"Return Order":
                NoSeriesCode := PurchSetup."Return Order Nos.";
            "Document Type"::"Credit Memo":
                NoSeriesCode := PurchSetup."Credit Memo Nos.";
            "Document Type"::"Blanket Order":
                NoSeriesCode := PurchSetup."Blanket Order Nos.";
        end;
        OnAfterGetNoSeriesCode(Rec, PurchSetup, NoSeriesCode);
        exit(NoSeriesMgt.GetNoSeriesWithCheck(NoSeriesCode, SelectNoSeriesAllowed, "No. Series"));
    end;

    local procedure GetPostingNoSeriesCode() PostingNos: Code[20]
    var
        IsHandled: Boolean;
    begin
        GetPurchSetup();
        IsHandled := false;
        OnBeforeGetPostingNoSeriesCode(Rec, PurchSetup, PostingNos, IsHandled);
        if IsHandled then
            exit(PostingNos);

        if IsCreditDocType() then
            PostingNos := PurchSetup."Posted Credit Memo Nos."
        else
            PostingNos := PurchSetup."Posted Invoice Nos.";

        OnAfterGetPostingNoSeriesCode(Rec, PostingNos);
    end;

    local procedure GetPostingPrepaymentNoSeriesCode() PostingNos: Code[20]
    begin
        if IsCreditDocType() then
            PostingNos := PurchSetup."Posted Prepmt. Cr. Memo Nos."
        else
            PostingNos := PurchSetup."Posted Prepmt. Inv. Nos.";

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
                  Text040,
                  FieldCaption("Posting Date"), NoSeriesCapt, NoSeriesCode,
                  NoSeries.FieldCaption("Date Order"), NoSeries."Date Order", "Document Type",
                  NoCapt, No);
        end;
    end;

    procedure ConfirmDeletion(): Boolean
    var
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        PostPurchDelete: Codeunit "PostPurch-Delete";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Deleted Document");
        SourceCode.Get(SourceCodeSetup."Deleted Document");

        PostPurchDelete.InitDeleteHeader(
          Rec, PurchRcptHeader, PurchInvHeader, PurchCrMemoHeader,
          ReturnShptHeader, PurchInvHeaderPrepmt, PurchCrMemoHeaderPrepmt, SourceCode.Code);

        if PurchRcptHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text009, PurchRcptHeader."No."), true) then
                exit;
        if PurchInvHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text012, PurchInvHeader."No."), true) then
                exit;
        if PurchCrMemoHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text014, PurchCrMemoHeader."No."), true) then
                exit;
        if ReturnShptHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text029, ReturnShptHeader."No."), true) then
                exit;
        if "Prepayment No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text045, PurchInvHeaderPrepmt."No."), true) then
                exit;
        if "Prepmt. Cr. Memo No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text046, PurchCrMemoHeaderPrepmt."No."), true) then
                exit;
        exit(true);
    end;

    local procedure GetPurchSetup()
    begin
        PurchSetup.Get();
        OnAfterGetPurchSetup(Rec, PurchSetup, CurrFieldNo);
    end;

    procedure GetVend(VendNo: Code[20])
    begin
        if VendNo <> Vend."No." then
            Vend.Get(VendNo);
    end;

    procedure GetStatusStyleText() StatusStyleText: Text
    begin
        if Status = Status::Open then
            StatusStyleText := 'Favorable'
        else
            StatusStyleText := 'Strong';

        OnAfterGetStatusStyleText(Rec, StatusStyleText);
    end;

    procedure PurchLinesExist(): Boolean
    begin
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        exit(not PurchLine.IsEmpty);
    end;

    procedure RecreatePurchLines(ChangedFieldName: Text[100])
    var
        TempPurchLine: Record "Purchase Line" temporary;
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        TempInteger: Record "Integer" temporary;
        TempPurchCommentLine: Record "Purch. Comment Line" temporary;
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ConfirmManagement: Codeunit "Confirm Management";
        ExtendedTextAdded: Boolean;
        ConfirmText: Text;
        IsHandled: Boolean;
    begin
        if not PurchLinesExist() then
            exit;

        IsHandled := false;
        OnBeforeRecreatePurchLinesHandler(Rec, xRec, ChangedFieldName, IsHandled);
        if IsHandled then
            exit;

        IsHandled := false;
        OnRecreatePurchLinesOnBeforeConfirm(Rec, xRec, ChangedFieldName, HideValidationDialog, Confirmed, IsHandled);
        if not IsHandled then
            if GetHideValidationDialog() then
                Confirmed := true
            else begin
                if HasItemChargeAssignment() then
                    ConfirmText := ResetItemChargeAssignMsg
                else
                    ConfirmText := RecreatePurchLinesMsg;
                Confirmed := ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmText, ChangedFieldName), true);
            end;

        if Confirmed then begin
            PurchLine.LockTable();
            ItemChargeAssgntPurch.LockTable();
            Modify();
            OnBeforeRecreatePurchLines(Rec);

            PurchLine.Reset();
            PurchLine.SetRange("Document Type", "Document Type");
            PurchLine.SetRange("Document No.", "No.");
            OnRecreatePurchLinesOnAfterPurchLineSetFilters(PurchLine);
            if PurchLine.FindSet then begin
                RecreateTempPurchLines(TempPurchLine);
                StorePurchCommentLineToTemp(TempPurchCommentLine);
                DeletePurchCommentLines();

                TransferItemChargeAssgntPurchToTemp(ItemChargeAssgntPurch, TempItemChargeAssgntPurch);

                DeletePurchLines(PurchLine);

                PurchLine.Init();
                PurchLine."Line No." := 0;
                OnRecreatePurchLinesOnBeforeTempPurchLineFindSet(TempPurchLine);
                TempPurchLine.FindSet();
                ExtendedTextAdded := false;
                repeat
                    if TempPurchLine."Attached to Line No." = 0 then begin
                        PurchLine.Init();
                        PurchLine."Line No." := PurchLine."Line No." + 10000;
                        PurchLine."Price Calculation Method" := "Price Calculation Method";
                        PurchLine.Validate(Type, TempPurchLine.Type);
                        OnRecreatePurchLinesOnAfterValidateType(PurchLine, TempPurchLine);
                        if TempPurchLine."No." = '' then begin
                            PurchLine.Validate(Description, TempPurchLine.Description);
                            PurchLine.Validate("Description 2", TempPurchLine."Description 2");
                        end else begin
                            PurchLine.Validate("No.", TempPurchLine."No.");
                            IsHandled := false;
                            OnRecreatePurchLinesOnBeforeTransferSavedFields(Rec, TempPurchLine, IsHandled, PurchLine);
                            if not IsHandled then
                                if PurchLine.Type <> PurchLine.Type::" " then
                                    case true of
                                        TempPurchLine."Drop Shipment":
                                            TransferSavedFieldsDropShipment(PurchLine, TempPurchLine);
                                        TempPurchLine."Special Order":
                                            TransferSavedFieldsSpecialOrder(PurchLine, TempPurchLine);
                                        else
                                            TransferSavedFields(PurchLine, TempPurchLine);
                                    end;
                        end;

                        OnRecreatePurchLinesOnBeforeInsertPurchLine(PurchLine, TempPurchLine, ChangedFieldName);
                        PurchLine.Insert();
                        ExtendedTextAdded := false;

                        OnAfterRecreatePurchLine(PurchLine, TempPurchLine, Rec);

                        if PurchLine.Type = PurchLine.Type::Item then
                            RecreatePurchLinesFillItemChargeAssignment(PurchLine, TempPurchLine, TempItemChargeAssgntPurch);

                        if PurchLine.Type = PurchLine.Type::"Charge (Item)" then begin
                            TempInteger.Init();
                            TempInteger.Number := PurchLine."Line No.";
                            TempInteger.Insert();
                        end;
                    end else
                        if not ExtendedTextAdded then begin
                            TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, true);
                            TransferExtendedText.InsertPurchExtText(PurchLine);
                            OnAfterTransferExtendedTextForPurchaseLineRecreation(PurchLine, TempPurchLine);
                            PurchLine.FindLast();
                            ExtendedTextAdded := true;
                        end;
                    RestorePurchCommentLine(TempPurchCommentLine, TempPurchLine."Line No.", PurchLine."Line No.");
                    OnRecreatePurchLineOnAfterProcessAttachedToLineNo(TempPurchLine, PurchLine);
                until TempPurchLine.Next() = 0;

                RestorePurchCommentLine(TempPurchCommentLine, 0, 0);

                RecreateItemChargeAssgntPurch(TempItemChargeAssgntPurch, TempPurchLine, TempInteger);

                TempPurchLine.SetRange(Type);
                TempPurchLine.DeleteAll();
                OnAfterDeleteAllTempPurchLines(Rec);
            end;
        end else
            Error(RecreatePurchaseLinesCancelErr, ChangedFieldName);
    end;

    local procedure StorePurchCommentLineToTemp(var TempPurchCommentLine: Record "Purch. Comment Line" temporary)
    var
        PurchCommentLine: Record "Purch. Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStorePurchCommentLineToTemp(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        PurchCommentLine.SetRange("Document Type", "Document Type");
        PurchCommentLine.SetRange("No.", "No.");
        if PurchCommentLine.FindSet() then
            repeat
                TempPurchCommentLine := PurchCommentLine;
                TempPurchCommentLine.Insert();
            until PurchCommentLine.Next() = 0;
    end;

    local procedure RestorePurchCommentLine(var TempPurchCommentLine: Record "Purch. Comment Line" temporary; OldDocumentLineNo: Integer; NewDocumentLineNo: Integer)
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        TempPurchCommentLine.SetRange("Document Type", "Document Type");
        TempPurchCommentLine.SetRange("No.", "No.");
        TempPurchCommentLine.SetRange("Document Line No.", OldDocumentLineNo);
        if TempPurchCommentLine.FindSet() then
            repeat
                PurchCommentLine := TempPurchCommentLine;
                PurchCommentLine."Document Line No." := NewDocumentLineNo;
                PurchCommentLine.Insert();
            until TempPurchCommentLine.Next() = 0;
    end;

    local procedure RecreatePurchLinesFillItemChargeAssignment(PurchLine: Record "Purchase Line"; var TempPurchLine: Record "Purchase Line" temporary; var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary)
    begin
        ClearItemAssgntPurchFilter(TempItemChargeAssgntPurch);
        TempItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", TempPurchLine."Document Type");
        TempItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", TempPurchLine."Document No.");
        TempItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", TempPurchLine."Line No.");
        if TempItemChargeAssgntPurch.FindSet() then
            repeat
                if not TempItemChargeAssgntPurch.Mark then begin
                    TempItemChargeAssgntPurch."Applies-to Doc. Line No." := PurchLine."Line No.";
                    TempItemChargeAssgntPurch.Description := PurchLine.Description;
                    TempItemChargeAssgntPurch.Modify();
                    TempItemChargeAssgntPurch.Mark(true);
                end;
            until TempItemChargeAssgntPurch.Next() = 0;
    end;

    local procedure RecreateItemChargeAssgntPurch(var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary; var TempPurchLine: Record "Purchase Line" temporary; var TempInteger: Record "Integer" temporary)
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        ClearItemAssgntPurchFilter(TempItemChargeAssgntPurch);
        TempPurchLine.SetRange(Type, TempPurchLine.Type::"Charge (Item)");
        if TempPurchLine.FindSet() then
            repeat
                TempItemChargeAssgntPurch.SetRange("Document Line No.", TempPurchLine."Line No.");
                if TempItemChargeAssgntPurch.FindSet then begin
                    repeat
                        TempInteger.FindFirst();
                        ItemChargeAssgntPurch.Init();
                        ItemChargeAssgntPurch := TempItemChargeAssgntPurch;
                        ItemChargeAssgntPurch."Document Line No." := TempInteger.Number;
                        ItemChargeAssgntPurch.Validate("Qty. to Assign", 0);
                        ItemChargeAssgntPurch.Insert();
                    until TempItemChargeAssgntPurch.Next() = 0;
                    TempInteger.Delete();
                end;
            until TempPurchLine.Next() = 0;

        ClearItemAssgntPurchFilter(TempItemChargeAssgntPurch);
        TempItemChargeAssgntPurch.DeleteAll();
    end;

    local procedure TransferSavedFields(var DestinationPurchaseLine: Record "Purchase Line"; var SourcePurchaseLine: Record "Purchase Line")
    begin
        OnBeforeTransferSavedFields(DestinationPurchaseLine, SourcePurchaseLine);

        DestinationPurchaseLine.Validate("Unit of Measure Code", SourcePurchaseLine."Unit of Measure Code");
        DestinationPurchaseLine.Validate("Variant Code", SourcePurchaseLine."Variant Code");
        DestinationPurchaseLine."Prod. Order No." := SourcePurchaseLine."Prod. Order No.";
        if DestinationPurchaseLine."Prod. Order No." <> '' then begin
            DestinationPurchaseLine.Description := SourcePurchaseLine.Description;
            DestinationPurchaseLine.Validate("VAT Prod. Posting Group", SourcePurchaseLine."VAT Prod. Posting Group");
            DestinationPurchaseLine.Validate("Gen. Prod. Posting Group", SourcePurchaseLine."Gen. Prod. Posting Group");
            DestinationPurchaseLine.Validate("Expected Receipt Date", SourcePurchaseLine."Expected Receipt Date");
            DestinationPurchaseLine.Validate("Requested Receipt Date", SourcePurchaseLine."Requested Receipt Date");
            DestinationPurchaseLine.Validate("Qty. per Unit of Measure", SourcePurchaseLine."Qty. per Unit of Measure");
        end;
        TransferSavedJobFields(DestinationPurchaseLine, SourcePurchaseLine);
        if SourcePurchaseLine.Quantity <> 0 then
            DestinationPurchaseLine.Validate(Quantity, SourcePurchaseLine.Quantity);
        if ("Currency Code" = xRec."Currency Code") and (PurchLine."Direct Unit Cost" = 0) then
            DestinationPurchaseLine.Validate("Direct Unit Cost", SourcePurchaseLine."Direct Unit Cost");
        DestinationPurchaseLine."Routing No." := SourcePurchaseLine."Routing No.";
        DestinationPurchaseLine."Routing Reference No." := SourcePurchaseLine."Routing Reference No.";
        DestinationPurchaseLine."Operation No." := SourcePurchaseLine."Operation No.";
        DestinationPurchaseLine."Work Center No." := SourcePurchaseLine."Work Center No.";
        DestinationPurchaseLine."Prod. Order Line No." := SourcePurchaseLine."Prod. Order Line No.";
        DestinationPurchaseLine."Overhead Rate" := SourcePurchaseLine."Overhead Rate";

        OnAfterTransferSavedFields(DestinationPurchaseLine, SourcePurchaseLine);
    end;

    local procedure TransferSavedJobFields(var DestinationPurchaseLine: Record "Purchase Line"; SourcePurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferSavedJobFields(DestinationPurchaseLine, SourcePurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if (SourcePurchaseLine."Job No." <> '') and (SourcePurchaseLine."Job Task No." <> '') then begin
            DestinationPurchaseLine.Validate("Job No.", SourcePurchaseLine."Job No.");
            DestinationPurchaseLine.Validate("Job Task No.", SourcePurchaseLine."Job Task No.");
            DestinationPurchaseLine."Job Line Type" := SourcePurchaseLine."Job Line Type";
        end;
    end;

    local procedure TransferSavedFieldsDropShipment(var DestinationPurchaseLine: Record "Purchase Line"; var SourcePurchaseLine: Record "Purchase Line")
    var
        SalesLine: Record "Sales Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferSavedFieldsDropShipment(DestinationPurchaseLine, SourcePurchaseLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Get(
            SalesLine."Document Type"::Order,
            SourcePurchaseLine."Sales Order No.",
            SourcePurchaseLine."Sales Order Line No.");
        CopyDocMgt.TransfldsFromSalesToPurchLine(SalesLine, DestinationPurchaseLine);
        DestinationPurchaseLine."Drop Shipment" := SourcePurchaseLine."Drop Shipment";
        DestinationPurchaseLine."Purchasing Code" := SalesLine."Purchasing Code";
        DestinationPurchaseLine."Sales Order No." := SourcePurchaseLine."Sales Order No.";
        DestinationPurchaseLine."Sales Order Line No." := SourcePurchaseLine."Sales Order Line No.";
        Evaluate(DestinationPurchaseLine."Inbound Whse. Handling Time", '<0D>');
        DestinationPurchaseLine.Validate("Inbound Whse. Handling Time");
        SalesLine.Validate("Unit Cost (LCY)", DestinationPurchaseLine."Unit Cost (LCY)");
        SalesLine."Purchase Order No." := DestinationPurchaseLine."Document No.";
        SalesLine."Purch. Order Line No." := DestinationPurchaseLine."Line No.";
        SalesLine.Modify();
    end;

    local procedure TransferSavedFieldsSpecialOrder(var DestinationPurchaseLine: Record "Purchase Line"; var SourcePurchaseLine: Record "Purchase Line")
    var
        SalesLine: Record "Sales Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferSavedFieldsSpecialOrder(DestinationPurchaseLine, SourcePurchaseLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Get(
            SalesLine."Document Type"::Order,
            SourcePurchaseLine."Special Order Sales No.",
            SourcePurchaseLine."Special Order Sales Line No.");
        CopyDocMgt.TransfldsFromSalesToPurchLine(SalesLine, DestinationPurchaseLine);
        DestinationPurchaseLine."Special Order" := SourcePurchaseLine."Special Order";
        DestinationPurchaseLine."Purchasing Code" := SalesLine."Purchasing Code";
        DestinationPurchaseLine."Special Order Sales No." := SourcePurchaseLine."Special Order Sales No.";
        DestinationPurchaseLine."Special Order Sales Line No." := SourcePurchaseLine."Special Order Sales Line No.";
        DestinationPurchaseLine.Validate("Unit of Measure Code", SourcePurchaseLine."Unit of Measure Code");
        if SourcePurchaseLine.Quantity <> 0 then
            DestinationPurchaseLine.Validate(Quantity, SourcePurchaseLine.Quantity);

        SalesLine.Validate("Unit Cost (LCY)", DestinationPurchaseLine."Unit Cost (LCY)");
        SalesLine."Special Order Purchase No." := DestinationPurchaseLine."Document No.";
        SalesLine."Special Order Purch. Line No." := DestinationPurchaseLine."Line No.";
        SalesLine.Modify();
    end;

    procedure MessageIfPurchLinesExist(ChangedFieldName: Text[100])
    var
        MessageText: Text;
    begin
        if PurchLinesExist and not GetHideValidationDialog then begin
            MessageText := StrSubstNo(LinesNotUpdatedMsg, ChangedFieldName);
            MessageText := StrSubstNo(SplitMessageTxt, MessageText, Text020);
            Message(MessageText);
        end;
    end;

    procedure PriceMessageIfPurchLinesExist(ChangedFieldName: Text[100])
    var
        MessageText: Text;
    begin
        if PurchLinesExist and not GetHideValidationDialog then begin
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
                    RecreatePurchLines(FieldCaption("Currency Code"));
            end else
                UpdateCurrencyExchangeRates.ShowMissingExchangeRatesNotification("Currency Code");
        end else begin
            "Currency Factor" := 0;
            if "Currency Code" <> xRec."Currency Code" then
                RecreatePurchLines(FieldCaption("Currency Code"));
        end;

        OnAfterUpdateCurrencyFactor(Rec, GetHideValidationDialog);
    end;

    procedure ConfirmCurrencyFactorUpdate(): Boolean
    begin
        OnBeforeConfirmUpdateCurrencyFactor(Rec, HideValidationDialog);
        if GetHideValidationDialog or not GuiAllowed then
            Confirmed := true
        else
            Confirmed := Confirm(Text022, false);
        if Confirmed then
            Validate("Currency Factor")
        else
            "Currency Factor" := xRec."Currency Factor";
        exit(Confirmed);
    end;

    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure UpdateLocationCode(LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLocationCode(Rec, LocationCode, IsHandled);
        if not IsHandled then
            Validate("Location Code", UserSetupMgt.GetLocation(1, LocationCode, "Responsibility Center"));
    end;

    procedure UpdatePurchLines(ChangedFieldName: Text[100]; AskQuestion: Boolean)
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, DATABASE::"Purchase Header");
        Field.SetRange("Field Caption", ChangedFieldName);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.Find('-');
        if Field.Next <> 0 then
            Error(DuplicatedCaptionsNotAllowedErr);
        UpdatePurchLinesByFieldNo(Field."No.", AskQuestion);

        OnAfterUpdatePurchLines(Rec);
    end;

    local procedure UpdatePurchAmountLines()
    var
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchLineAmounts(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        PurchLine.Reset();
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        PurchLine.SetFilter(Type, '<>%1', PurchLine.Type::" ");
        PurchLine.SetFilter(Quantity, '<>0');
        PurchLine.LockTable();
        if PurchLine.FindSet then begin
            Modify();
            repeat
                PurchLine.UpdateAmounts();
                PurchLine.Modify();
            until PurchLine.Next() = 0;
        end;
    end;

    procedure UpdatePurchLinesByFieldNo(ChangedFieldNo: Integer; AskQuestion: Boolean)
    var
        "Field": Record "Field";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        Question: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchLinesByFieldNo(Rec, ChangedFieldNo, AskQuestion, IsHandled);
        if IsHandled then
            exit;

        if not PurchLinesExist() then
            exit;

        if not Field.Get(DATABASE::"Purchase Header", ChangedFieldNo) then
            Field.Get(DATABASE::"Purchase Line", ChangedFieldNo);

        if AskQuestion then begin
            Question := StrSubstNo(Text032, Field."Field Caption");
            if GuiAllowed then
                if DIALOG.Confirm(Question, true) then
                    case ChangedFieldNo of
                        FieldNo("Expected Receipt Date"),
                        FieldNo("Requested Receipt Date"),
                        FieldNo("Promised Receipt Date"),
                        FieldNo("Lead Time Calculation"),
                        FieldNo("Inbound Whse. Handling Time"):
                            ConfirmReservationDateConflict(ChangedFieldNo);
                    end
                else
                    exit;
        end;

        PurchLine.LockTable();
        Modify;

        PurchLine.Reset();
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        if PurchLine.FindSet() then
            repeat
                xPurchLine := PurchLine;
                IsHandled := false;
                OnUpdatePurchLinesByFieldNoOnBeforeValidateFields(PurchLine, xPurchLine, ChangedFieldNo, Rec, IsHandled);
                if not IsHandled then
                    case ChangedFieldNo of
                        FieldNo("Expected Receipt Date"):
                            if PurchLine."No." <> '' then
                                PurchLine.Validate("Expected Receipt Date", "Expected Receipt Date");
                        FieldNo("Currency Factor"):
                            if PurchLine.Type <> PurchLine.Type::" " then
                                PurchLine.Validate("Direct Unit Cost");
                        FieldNo("Transaction Type"):
                            PurchLine.Validate("Transaction Type", "Transaction Type");
                        FieldNo("Transport Method"):
                            PurchLine.Validate("Transport Method", "Transport Method");
                        FieldNo("Entry Point"):
                            PurchLine.Validate("Entry Point", "Entry Point");
                        FieldNo(Area):
                            PurchLine.Validate(Area, Area);
                        FieldNo("Transaction Specification"):
                            PurchLine.Validate("Transaction Specification", "Transaction Specification");
                        FieldNo("Requested Receipt Date"):
                            if PurchLine."No." <> '' then
                                PurchLine.Validate("Requested Receipt Date", "Requested Receipt Date");
                        FieldNo("Prepayment %"):
                            if PurchLine."No." <> '' then
                                PurchLine.Validate("Prepayment %", "Prepayment %");
                        FieldNo("Promised Receipt Date"):
                            if PurchLine."No." <> '' then
                                PurchLine.Validate("Promised Receipt Date", "Promised Receipt Date");
                        FieldNo("Lead Time Calculation"):
                            if PurchLine."No." <> '' then
                                PurchLine.Validate("Lead Time Calculation", "Lead Time Calculation");
                        FieldNo("Inbound Whse. Handling Time"):
                            if PurchLine."No." <> '' then
                                PurchLine.Validate("Inbound Whse. Handling Time", "Inbound Whse. Handling Time");
                        PurchLine.FieldNo("Deferral Code"):
                            if PurchLine."No." <> '' then
                                PurchLine.Validate("Deferral Code");
                        else
                            OnUpdatePurchLinesByChangedFieldName(Rec, PurchLine, Field.FieldName, ChangedFieldNo);
                    end;
                OnUpdatePurchLinesByFieldNoOnBeforeLineModify(Rec, xRec, PurchLine);
                PurchLine.Modify(true);
                PurchLineReserve.VerifyChange(PurchLine, xPurchLine);
            until PurchLine.Next() = 0;

        OnAfterUpdatePurchLinesByFieldNo(Rec, xRec, ChangedFieldNo);
    end;

    procedure ConfirmReservationDateConflict()
    begin
        ConfirmReservationDateConflict(0);
    end;

    procedure ConfirmReservationDateConflict(ChangedFieldNo: Integer)
    var
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmResvDateConflict(Rec, IsHandled, ChangedFieldNo);
        if IsHandled then
            exit;

        if ReservationEngineMgt.ResvExistsForPurchHeader(Rec) then
            if not ConfirmManagement.GetResponseOrDefault(Text050, true) then
                Error('');
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20])
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
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Purchases, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnCreateDimOnBeforeUpdateLines(Rec, xRec, CurrFieldNo);

        if (OldDimSetID <> "Dimension Set ID") and PurchLinesExist then begin
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
            if PurchLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    local procedure ValidateDocumentDateWithPostingDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateDocumentDateWithPostingDate(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        Validate("Document Date", "Posting Date");
    end;

    procedure ReceivedPurchLinesExist(): Boolean
    begin
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        PurchLine.SetFilter("Quantity Received", '<>0');
        exit(PurchLine.FindFirst());
    end;

    procedure ReturnShipmentExist(): Boolean
    begin
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        PurchLine.SetFilter("Return Qty. Shipped", '<>0');
        exit(PurchLine.FindFirst());
    end;

    procedure UpdateShipToAddress()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShipToAddress(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsCreditDocType() then begin
            OnAfterUpdateShipToAddress(Rec);
            exit;
        end;

        if ("Location Code" <> '') and Location.Get("Location Code") and ("Sell-to Customer No." = '') then begin
            SetShipToAddress(
              Location.Name, Location."Name 2", Location.Address, Location."Address 2",
              Location.City, Location."Post Code", Location.County, Location."Country/Region Code");
            "Ship-to Contact" := Location.Contact;
        end;

        if ("Location Code" = '') and ("Sell-to Customer No." = '') then begin
            CompanyInfo.Get();
            "Ship-to Code" := '';
            SetShipToAddress(
              CompanyInfo."Ship-to Name", CompanyInfo."Ship-to Name 2", CompanyInfo."Ship-to Address", CompanyInfo."Ship-to Address 2",
              CompanyInfo."Ship-to City", CompanyInfo."Ship-to Post Code", CompanyInfo."Ship-to County",
              CompanyInfo."Ship-to Country/Region Code");
            "Ship-to Contact" := CompanyInfo."Ship-to Contact";
        end;

        OnAfterUpdateShipToAddress(Rec);
    end;

    local procedure DeletePurchaseLines()
    var
        ReservMgt: Codeunit "Reservation Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeletePurchaseLines(PurchLine, IsHandled, Rec);
        if IsHandled then
            exit;

        if PurchLine.FindSet() then begin
            ReservMgt.DeleteDocumentReservation(
                DATABASE::"Purchase Line", "Document Type".AsInteger(), "No.", GetHideValidationDialog);
            repeat
                PurchLine.SuspendStatusCheck(true);
                PurchLine.Delete(true);
            until PurchLine.Next() = 0;
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

    local procedure ClearItemAssgntPurchFilter(var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary)
    begin
        TempItemChargeAssgntPurch.SetRange("Document Line No.");
        TempItemChargeAssgntPurch.SetRange("Applies-to Doc. Type");
        TempItemChargeAssgntPurch.SetRange("Applies-to Doc. No.");
        TempItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.");
    end;

    local procedure CheckReceiptInfo(var PurchLine: Record "Purchase Line"; PayTo: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReceiptInfo(Rec, xRec, PurchLine, PayTo, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::Order then
            PurchLine.SetFilter("Quantity Received", '<>0')
        else
            if "Document Type" = "Document Type"::Invoice then begin
                if not PayTo then
                    PurchLine.SetRange("Buy-from Vendor No.", xRec."Buy-from Vendor No.");
                PurchLine.SetFilter("Receipt No.", '<>%1', '');
            end;

        if PurchLine.FindFirst() then
            if "Document Type" = "Document Type"::Order then
                PurchLine.TestField("Quantity Received", 0)
            else
                PurchLine.TestField("Receipt No.", '');
        PurchLine.SetRange("Receipt No.");
        PurchLine.SetRange("Quantity Received");
        if not PayTo then
            PurchLine.SetRange("Buy-from Vendor No.");
    end;

    local procedure CheckPrepmtInfo(var PurchLine: Record "Purchase Line")
    begin
        if "Document Type" = "Document Type"::Order then begin
            PurchLine.SetFilter("Prepmt. Amt. Inv.", '<>0');
            if PurchLine.Find('-') then
                PurchLine.TestField("Prepmt. Amt. Inv.", 0);
            PurchLine.SetRange("Prepmt. Amt. Inv.");
        end;
    end;

    local procedure CheckReturnInfo(var PurchLine: Record "Purchase Line"; PayTo: Boolean)
    begin
        if "Document Type" = "Document Type"::"Return Order" then
            PurchLine.SetFilter("Return Qty. Shipped", '<>0')
        else
            if "Document Type" = "Document Type"::"Credit Memo" then begin
                if not PayTo then
                    PurchLine.SetRange("Buy-from Vendor No.", xRec."Buy-from Vendor No.");
                PurchLine.SetFilter("Return Shipment No.", '<>%1', '');
            end;

        if PurchLine.FindFirst() then
            if "Document Type" = "Document Type"::"Return Order" then
                PurchLine.TestField("Return Qty. Shipped", 0)
            else
                PurchLine.TestField("Return Shipment No.", '');
    end;

    local procedure CheckShipToCodeChange(PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShipToCodeChange(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        with PurchHeader do begin
            if ("Document Type" = "Document Type"::Order) and (xRec."Ship-to Code" <> "Ship-to Code") then begin
                PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                PurchLine.SetRange("Document No.", "No.");
                PurchLine.SetFilter("Sales Order Line No.", '<>0');
                if not PurchLine.IsEmpty() then
                    Error(YouCannotChangeFieldErr, FieldCaption("Ship-to Code"));
            end;
        end;
    end;

    local procedure CheckSpecialOrderSalesLineLink()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSpecialOrderSalesLineLink(Rec, IsHandled);
        if IsHandled then
            exit;

        PurchLine.SetRange("Sales Order Line No.");
        PurchLine.SetFilter("Special Order Sales Line No.", '<>0');
        if not PurchLine.IsEmpty() then
            Error(
              YouCannotChangeFieldErr,
              FieldCaption("Sell-to Customer No."));
    end;

    local procedure CheckShipToCode(ShipToCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShipToCode(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Ship-to Code", ShipToCode);
    end;

    local procedure UpdateBuyFromCont(VendorNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Vend: Record Vendor;
        OfficeContact: Record Contact;
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.GetContact(OfficeContact, VendorNo) then begin
            SetHideValidationDialog(true);
            UpdateBuyFromVend(OfficeContact."No.");
            SetHideValidationDialog(false);
        end else
            if Vend.Get(VendorNo) then begin
                if Vend."Primary Contact No." <> '' then
                    "Buy-from Contact No." := Vend."Primary Contact No."
                else
                    "Buy-from Contact No." := ContBusRel.GetContactNo(ContBusRel."Link to Table"::Vendor, "Buy-from Vendor No.");
                "Buy-from Contact" := Vend.Contact;
            end;

        if "Buy-from Contact No." <> '' then
            if OfficeContact.Get("Buy-from Contact No.") then
                OfficeContact.CheckIfPrivacyBlockedGeneric;

        OnAfterUpdateBuyFromCont(Rec, Vend, OfficeContact);
    end;

    local procedure UpdatePayToCont(VendorNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Vend: Record Vendor;
        Contact: Record Contact;
    begin
        if Vend.Get(VendorNo) then begin
            if Vend."Primary Contact No." <> '' then
                "Pay-to Contact No." := Vend."Primary Contact No."
            else
                "Pay-to Contact No." := ContBusRel.GetContactNo(ContBusRel."Link to Table"::Vendor, "Pay-to Vendor No.");
            "Pay-to Contact" := Vend.Contact;
        end;

        if "Pay-to Contact No." <> '' then
            if Contact.Get("Pay-to Contact No.") then
                Contact.CheckIfPrivacyBlockedGeneric;

        OnAfterUpdatePayToCont(Rec, Vend, Contact);
    end;

    local procedure UpdateBuyFromVend(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Vend: Record Vendor;
        Cont: Record Contact;
    begin
        if Cont.Get(ContactNo) then begin
            "Buy-from Contact No." := Cont."No.";
            if Cont.Type = Cont.Type::Person then
                "Buy-from Contact" := Cont.Name
            else
                if Vend.Get("Buy-from Vendor No.") then
                    "Buy-from Contact" := Vend.Contact
                else
                    "Buy-from Contact" := ''
        end else begin
            "Buy-from Contact" := '';
            exit;
        end;

        if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Vendor, Cont."Company No.") then begin
            if ("Buy-from Vendor No." <> '') and
               ("Buy-from Vendor No." <> ContBusinessRelation."No.")
            then
                Error(Text037, Cont."No.", Cont.Name, "Buy-from Vendor No.");
            if "Buy-from Vendor No." = '' then begin
                SkipBuyFromContact := true;
                Validate("Buy-from Vendor No.", ContBusinessRelation."No.");
                SkipBuyFromContact := false;
            end;
        end else
            ContactIsNotRelatedToVendorError(Cont, ContactNo);

        if ("Buy-from Vendor No." = "Pay-to Vendor No.") or
           ("Pay-to Vendor No." = '')
        then
            Validate("Pay-to Contact No.", "Buy-from Contact No.");

        OnAfterUpdateBuyFromVend(Rec, Cont);
    end;

    local procedure UpdatePayToVend(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Vend: Record Vendor;
        Cont: Record Contact;
    begin
        if Cont.Get(ContactNo) then begin
            "Pay-to Contact No." := Cont."No.";
            if Cont.Type = Cont.Type::Person then
                "Pay-to Contact" := Cont.Name
            else
                if Vend.Get("Pay-to Vendor No.") then
                    "Pay-to Contact" := Vend.Contact
                else
                    "Pay-to Contact" := '';
        end else begin
            "Pay-to Contact" := '';
            exit;
        end;

        OnUpdatePayToVendOnBeforeFindByContact(Rec, Vend, Cont);
        if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Vendor, Cont."Company No.") then begin
            if "Pay-to Vendor No." = '' then begin
                SkipPayToContact := true;
                Validate("Pay-to Vendor No.", ContBusinessRelation."No.");
                SkipPayToContact := false;
            end else
                if "Pay-to Vendor No." <> ContBusinessRelation."No." then
                    Error(Text037, Cont."No.", Cont.Name, "Pay-to Vendor No.");
        end else
            ContactIsNotRelatedToVendorError(Cont, ContactNo);
        OnAfterUpdatePayToVend(Rec, Cont);
    end;

    local procedure ContactIsNotRelatedToVendorError(Cont: Record Contact; ContactNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeContactIsNotRelatedToVendorError(Cont, ContactNo, IsHandled);
        if IsHandled then
            exit;

        Error(Text039, Cont."No.", Cont.Name);
    end;

    procedure CreateInvtPutAwayPick()
    var
        WhseRequest: Record "Warehouse Request";
    begin
        TestField(Status, Status::Released);

        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        case "Document Type" of
            "Document Type"::Order:
                WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Purchase Order");
            "Document Type"::"Return Order":
                WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Purchase Return Order");
        end;
        WhseRequest.SetRange("Source No.", "No.");
        REPORT.RunModal(REPORT::"Create Invt Put-away/Pick/Mvmt", true, false, WhseRequest);
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

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if PurchLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        NewDimSetID: Integer;
        ReceivedShippedItemLineDimChangeConfirmed: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAllLineDim(Rec, NewParentDimSetID, OldParentDimSetID, IsHandled, xRec);
        if IsHandled then
            exit;

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not GetHideValidationDialog then
            if not ConfirmManagement.GetResponseOrDefault(Text051, true) then
                exit;

        PurchLine.Reset();
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        PurchLine.LockTable();
        if PurchLine.Find('-') then
            repeat
                OnUpdateAllLineDimOnBeforeGetPurchLineNewDimsetID(PurchLine, NewParentDimSetID, OldParentDimSetID);
                NewDimSetID := DimMgt.GetDeltaDimSetID(PurchLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                OnUpdateAllLineDimOnAfterGetPurchLineNewDimsetID(Rec, xRec, PurchLine, NewDimSetID, NewParentDimSetID, OldParentDimSetID);
                if PurchLine."Dimension Set ID" <> NewDimSetID then begin
                    PurchLine."Dimension Set ID" := NewDimSetID;

                    if not GetHideValidationDialog and GuiAllowed then
                        VerifyReceivedShippedItemLineDimChange(ReceivedShippedItemLineDimChangeConfirmed);

                    DimMgt.UpdateGlobalDimFromDimSetID(
                      PurchLine."Dimension Set ID", PurchLine."Shortcut Dimension 1 Code", PurchLine."Shortcut Dimension 2 Code");

                    OnUpdateAllLineDimOnBeforePurchLineModify(PurchLine);
                    PurchLine.Modify();
                end;
            until PurchLine.Next() = 0;
    end;

    local procedure VerifyReceivedShippedItemLineDimChange(var ReceivedShippedItemLineDimChangeConfirmed: Boolean)
    begin
        if PurchLine.IsReceivedShippedItemDimChanged then
            if not ReceivedShippedItemLineDimChangeConfirmed then
                ReceivedShippedItemLineDimChangeConfirmed := PurchLine.ConfirmReceivedShippedItemDimChange;
    end;

    procedure SetAmountToApply(AppliesToDocNo: Code[20]; VendorNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        OnBeforeSetAmountToApply(Rec, VendLedgEntry);

        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Document No.", AppliesToDocNo);
        VendLedgEntry.SetRange("Vendor No.", VendorNo);
        VendLedgEntry.SetRange(Open, true);
        if VendLedgEntry.FindFirst() then begin
            if VendLedgEntry."Amount to Apply" = 0 then begin
                VendLedgEntry.CalcFields("Remaining Amount");
                VendLedgEntry."Amount to Apply" := VendLedgEntry."Remaining Amount";
            end else
                VendLedgEntry."Amount to Apply" := 0;
            VendLedgEntry."Accepted Payment Tolerance" := 0;
            VendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
        end;
    end;

    procedure SetShipToForSpecOrder()
    begin
        if Location.Get("Location Code") then begin
            "Ship-to Code" := '';
            SetShipToAddress(
              Location.Name, Location."Name 2", Location.Address, Location."Address 2",
              Location.City, Location."Post Code", Location.County, Location."Country/Region Code");
            "Ship-to Contact" := Location.Contact;
            "Location Code" := Location.Code;
        end else begin
            CompanyInfo.Get();
            "Ship-to Code" := '';
            SetShipToAddress(
              CompanyInfo."Ship-to Name", CompanyInfo."Ship-to Name 2", CompanyInfo."Ship-to Address", CompanyInfo."Ship-to Address 2",
              CompanyInfo."Ship-to City", CompanyInfo."Ship-to Post Code", CompanyInfo."Ship-to County",
              CompanyInfo."Ship-to Country/Region Code");
            "Ship-to Contact" := CompanyInfo."Ship-to Contact";
            "Location Code" := '';
        end;

        OnAfterSetShipToForSpecOrder(Rec);
    end;

    local procedure JobUpdatePurchLines(SkipJobCurrFactorUpdate: Boolean)
    begin
        with PurchLine do begin
            SetFilter("Job No.", '<>%1', '');
            SetFilter("Job Task No.", '<>%1', '');
            LockTable();
            if FindSet(true, false) then begin
                SetPurchHeader(Rec);
                repeat
                    if not SkipJobCurrFactorUpdate then
                        JobSetCurrencyFactor;
                    CreateTempJobJnlLine(false);
                    UpdateJobPrices();
                    Modify();
                until Next() = 0;
            end;
        end
    end;

    procedure GetPstdDocLinesToReverse()
    var
        PurchPostedDocLines: Page "Posted Purchase Document Lines";
    begin
        GetVend("Buy-from Vendor No.");
        PurchPostedDocLines.SetToPurchHeader(Rec);
        PurchPostedDocLines.SetRecord(Vend);
        PurchPostedDocLines.LookupMode := true;
        if PurchPostedDocLines.RunModal = ACTION::LookupOK then
            PurchPostedDocLines.CopyLineToDoc();

        Clear(PurchPostedDocLines);
    end;

    procedure SetSecurityFilterOnRespCenter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if (not IsHandled) and (UserSetupMgt.GetPurchasesFilter <> '') then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetPurchasesFilter);
            FilterGroup(0);
        end;

        SetRange("Date Filter", 0D, WorkDate());
    end;

    procedure CalcInvDiscForHeader()
    var
        PurchaseInvDisc: Codeunit "Purch.-Calc.Discount";
    begin
        GetPurchSetup();
        if PurchSetup."Calc. Inv. Discount" then
            PurchaseInvDisc.CalculateIncDiscForHeader(Rec);
    end;

    procedure AddShipToAddress(SalesHeader: Record "Sales Header"; ShowError: Boolean)
    var
        PurchLine2: Record "Purchase Line";
    begin
        if ShowError then begin
            PurchLine2.Reset();
            PurchLine2.SetRange("Document Type", "Document Type"::Order);
            PurchLine2.SetRange("Document No.", "No.");
            if not PurchLine2.IsEmpty() then begin
                if "Ship-to Name" <> SalesHeader."Ship-to Name" then
                    Error(Text052, FieldCaption("Ship-to Name"), "No.", SalesHeader."No.");
                if "Ship-to Name 2" <> SalesHeader."Ship-to Name 2" then
                    Error(Text052, FieldCaption("Ship-to Name 2"), "No.", SalesHeader."No.");
                if "Ship-to Address" <> SalesHeader."Ship-to Address" then
                    Error(Text052, FieldCaption("Ship-to Address"), "No.", SalesHeader."No.");
                if "Ship-to Address 2" <> SalesHeader."Ship-to Address 2" then
                    Error(Text052, FieldCaption("Ship-to Address 2"), "No.", SalesHeader."No.");
                if "Ship-to Post Code" <> SalesHeader."Ship-to Post Code" then
                    Error(Text052, FieldCaption("Ship-to Post Code"), "No.", SalesHeader."No.");
                if "Ship-to Country/Region Code" <> SalesHeader."Ship-to Country/Region Code" then
                    Error(Text052, FieldCaption("Ship-to Country/Region Code"), "No.", SalesHeader."No.");
                if "Ship-to County" <> SalesHeader."Ship-to County" then
                    Error(Text052, FieldCaption("Ship-to County"), "No.", SalesHeader."No.");
                if "Ship-to City" <> SalesHeader."Ship-to City" then
                    Error(Text052, FieldCaption("Ship-to City"), "No.", SalesHeader."No.");
                if "Ship-to Contact" <> SalesHeader."Ship-to Contact" then
                    Error(Text052, FieldCaption("Ship-to Contact"), "No.", SalesHeader."No.");
            end else begin
                // no purchase line exists
                SetShipToAddress(
                    SalesHeader."Ship-to Name", SalesHeader."Ship-to Name 2", SalesHeader."Ship-to Address",
                    SalesHeader."Ship-to Address 2", SalesHeader."Ship-to City", SalesHeader."Ship-to Post Code",
                    SalesHeader."Ship-to County", SalesHeader."Ship-to Country/Region Code");
                "Ship-to Contact" := SalesHeader."Ship-to Contact";
            end;
        end;

        OnAfterAddShipToAddress(Rec, SalesHeader, ShowError);
    end;

    local procedure CopyAddressInfoFromOrderAddress()
    var
        OrderAddr: Record "Order Address";
    begin
        OrderAddr.Get("Buy-from Vendor No.", "Order Address Code");
        "Buy-from Vendor Name" := OrderAddr.Name;
        "Buy-from Vendor Name 2" := OrderAddr."Name 2";
        "Buy-from Address" := OrderAddr.Address;
        "Buy-from Address 2" := OrderAddr."Address 2";
        "Buy-from City" := OrderAddr.City;
        "Buy-from Contact" := OrderAddr.Contact;
        "Buy-from Post Code" := OrderAddr."Post Code";
        "Buy-from County" := OrderAddr.County;
        "Buy-from Country/Region Code" := OrderAddr."Country/Region Code";

        if IsCreditDocType() then begin
            SetShipToAddress(
                OrderAddr.Name, OrderAddr."Name 2", OrderAddr.Address, OrderAddr."Address 2",
                OrderAddr.City, OrderAddr."Post Code", OrderAddr.County, OrderAddr."Country/Region Code");
            "Ship-to Contact" := OrderAddr.Contact;
        end;
        OnAfterCopyAddressInfoFromOrderAddress(OrderAddr);
    end;

    procedure DropShptOrderExists(SalesHeader: Record "Sales Header"): Boolean
    var
        SalesLine2: Record "Sales Line";
    begin
        // returns TRUE if sales is either Drop Shipment of Special Order
        SalesLine2.Reset();
        SalesLine2.SetRange("Document Type", SalesLine2."Document Type"::Order);
        SalesLine2.SetRange("Document No.", SalesHeader."No.");
        SalesLine2.SetRange("Drop Shipment", true);
        exit(not SalesLine2.IsEmpty());
    end;

    procedure SpecialOrderExists(SalesHeader: Record "Sales Header"): Boolean
    var
        SalesLine3: Record "Sales Line";
    begin
        SalesLine3.Reset();
        SalesLine3.SetRange("Document Type", SalesLine3."Document Type"::Order);
        SalesLine3.SetRange("Document No.", SalesHeader."No.");
        SalesLine3.SetRange("Special Order", true);
        exit(not SalesLine3.IsEmpty());
    end;

    local procedure CheckDropShipmentLineExists()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Purchase Order No.", "No.");
        SalesShipmentLine.SetRange("Drop Shipment", true);
        if not SalesShipmentLine.IsEmpty() then
            Error(YouCannotChangeFieldErr, FieldCaption("Buy-from Vendor No."));
    end;

    procedure QtyToReceiveIsZero(): Boolean
    begin
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        PurchLine.SetFilter("Qty. to Receive", '<>0');
        exit(PurchLine.IsEmpty);
    end;

    procedure IsApprovedForPosting() Approved: Boolean
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ApprovalsMgmt.PrePostApprovalCheckPurch(Rec) then begin
            if PrepaymentMgt.TestPurchasePrepayment(Rec) then
                Error(PrepaymentInvoicesNotPaidErr, "Document Type", "No.");
            Approved := true;
            if PrepaymentMgt.TestPurchasePayment(Rec) then
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text054, "Document Type", "No."), true) then
                    Approved := false;
            OnAfterIsApprovedForPosting(Rec, Approved);
        end;
    end;

    procedure IsApprovedForPostingBatch() Approved: Boolean
    begin
        Approved := ApprovedForPostingBatch();
        OnAfterIsApprovedForPostingBatch(Rec, Approved);
    end;

    [TryFunction]
    local procedure ApprovedForPostingBatch()
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        if ApprovalsMgmt.PrePostApprovalCheckPurch(Rec) then begin
            if PrepaymentMgt.TestPurchasePrepayment(Rec) then
                Error(PrepaymentInvoicesNotPaidErr, "Document Type", "No.");
            if PrepaymentMgt.TestPurchasePayment(Rec) then
                Error(Text054, "Document Type", "No.");
        end;
    end;

    procedure IsTotalValid(): Boolean
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseLine: Record "Purchase Line";
        TempTotalPurchaseLine: Record "Purchase Line" temporary;
        GeneralLedgerSetup: Record "General Ledger Setup";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeIsTotalValid(Rec, IsHandled);
        if IsHandled then
            exit(true);

        if not IncomingDocument.Get("Incoming Document Entry No.") then
            exit(true);

        if IncomingDocument."Amount Incl. VAT" = 0 then
            exit(true);

        PurchaseLine.SetRange("Document Type", "Document Type");
        PurchaseLine.SetRange("Document No.", "No.");
        if not PurchaseLine.FindFirst() then
            exit(true);

        GeneralLedgerSetup.Get();
        if (IncomingDocument."Currency Code" <> PurchaseLine."Currency Code") and
           (IncomingDocument."Currency Code" <> GeneralLedgerSetup."LCY Code")
        then
            exit(true);

        TempTotalPurchaseLine.Init();
        DocumentTotals.PurchaseCalculateTotalsWithInvoiceRounding(PurchaseLine, VATAmount, TempTotalPurchaseLine);

        exit(IncomingDocument."Amount Incl. VAT" = TempTotalPurchaseLine."Amount Including VAT");
    end;

    procedure SendToPosting(PostingCodeunitID: Integer) IsSuccess: Boolean
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendToPosting(Rec, IsSuccess, IsHandled);
        if IsHandled then
            exit(IsSuccess);

        if not IsApprovedForPosting() then
            exit;

        Commit();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, '');
        IsSuccess := CODEUNIT.Run(PostingCodeunitID, Rec);
        if not IsSuccess then
            ErrorMessageHandler.ShowErrors();
    end;

    procedure CancelBackgroundPosting()
    var
        PurchasePostViaJobQueue: Codeunit "Purchase Post via Job Queue";
    begin
        PurchasePostViaJobQueue.CancelQueueEntry(Rec);
    end;

    procedure AddSpecialOrderToAddress(var SalesHeader: Record "Sales Header"; ShowError: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddSpecialOrderToAddress(Rec, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if ShowError then
            if PurchLinesExist() then begin
                PurchaseHeader := Rec;
                PurchaseHeader.SetShipToForSpecOrder();
                if "Ship-to Name" <> PurchaseHeader."Ship-to Name" then
                    Error(Text052, FieldCaption("Ship-to Name"), "No.", SalesHeader."No.");
                if "Ship-to Name 2" <> PurchaseHeader."Ship-to Name 2" then
                    Error(Text052, FieldCaption("Ship-to Name 2"), "No.", SalesHeader."No.");
                if "Ship-to Address" <> PurchaseHeader."Ship-to Address" then
                    Error(Text052, FieldCaption("Ship-to Address"), "No.", SalesHeader."No.");
                if "Ship-to Address 2" <> PurchaseHeader."Ship-to Address 2" then
                    Error(Text052, FieldCaption("Ship-to Address 2"), "No.", SalesHeader."No.");
                if "Ship-to Post Code" <> PurchaseHeader."Ship-to Post Code" then
                    Error(Text052, FieldCaption("Ship-to Post Code"), "No.", SalesHeader."No.");
                if "Ship-to City" <> PurchaseHeader."Ship-to City" then
                    Error(Text052, FieldCaption("Ship-to City"), "No.", SalesHeader."No.");
                if "Ship-to Contact" <> PurchaseHeader."Ship-to Contact" then
                    Error(Text052, FieldCaption("Ship-to Contact"), "No.", SalesHeader."No.");
            end else
                SetShipToForSpecOrder();
    end;

    procedure InvoicedLineExists(): Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        PurchLine.SetFilter(Type, '<>%1', PurchLine.Type::" ");
        PurchLine.SetFilter("Quantity Invoiced", '<>%1', 0);
        exit(not PurchLine.IsEmpty);
    end;

    procedure CreateDimSetForPrepmtAccDefaultDim()
    var
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
    begin
        PurchaseLine.SetRange("Document Type", "Document Type");
        PurchaseLine.SetRange("Document No.", "No.");
        PurchaseLine.SetFilter("Prepmt. Amt. Inv.", '<>%1', 0);
        if PurchaseLine.FindSet then
            repeat
                CollectParamsInBufferForCreateDimSet(TempPurchaseLine, PurchaseLine);
            until PurchaseLine.Next() = 0;
        TempPurchaseLine.Reset();
        TempPurchaseLine.MarkedOnly(false);
        if TempPurchaseLine.FindSet then
            repeat
                PurchaseLine.CreateDim(DATABASE::"G/L Account", TempPurchaseLine."No.",
                  DATABASE::Job, TempPurchaseLine."Job No.",
                  DATABASE::"Responsibility Center", TempPurchaseLine."Responsibility Center",
                  DATABASE::"Work Center", TempPurchaseLine."Work Center No.");
            until TempPurchaseLine.Next() = 0;
    end;

    local procedure CollectParamsInBufferForCreateDimSet(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        DefaultDimension: Record "Default Dimension";
    begin
        TempPurchaseLine.SetRange("Gen. Bus. Posting Group", PurchaseLine."Gen. Bus. Posting Group");
        TempPurchaseLine.SetRange("Gen. Prod. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        if not TempPurchaseLine.FindFirst then begin
            GenPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
            GenPostingSetup.TestField("Purch. Prepayments Account");
            DefaultDimension.SetRange("Table ID", DATABASE::"G/L Account");
            DefaultDimension.SetRange("No.", GenPostingSetup."Purch. Prepayments Account");
            InsertTempPurchaseLineInBuffer(TempPurchaseLine, PurchaseLine,
              GenPostingSetup."Purch. Prepayments Account", DefaultDimension.IsEmpty);
        end else
            if not TempPurchaseLine.Mark then begin
                TempPurchaseLine.SetRange("Job No.", PurchaseLine."Job No.");
                TempPurchaseLine.SetRange("Responsibility Center", PurchaseLine."Responsibility Center");
                TempPurchaseLine.SetRange("Work Center No.", PurchaseLine."Work Center No.");
                OnCollectParamsInBufferForCreateDimSetOnAfterSetTempPurchLineFilters(TempPurchaseLine, PurchaseLine);
                if TempPurchaseLine.IsEmpty() then
                    InsertTempPurchaseLineInBuffer(TempPurchaseLine, PurchaseLine, TempPurchaseLine."No.", false)
            end;
    end;

    local procedure InsertTempPurchaseLineInBuffer(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line"; AccountNo: Code[20]; DefaultDimenstionsNotExist: Boolean)
    begin
        TempPurchaseLine.Init();
        TempPurchaseLine."Line No." := PurchaseLine."Line No.";
        TempPurchaseLine."No." := AccountNo;
        TempPurchaseLine."Job No." := PurchaseLine."Job No.";
        TempPurchaseLine."Responsibility Center" := PurchaseLine."Responsibility Center";
        TempPurchaseLine."Work Center No." := PurchaseLine."Work Center No.";
        TempPurchaseLine."Gen. Bus. Posting Group" := PurchaseLine."Gen. Bus. Posting Group";
        TempPurchaseLine."Gen. Prod. Posting Group" := PurchaseLine."Gen. Prod. Posting Group";
        TempPurchaseLine.Mark := DefaultDimenstionsNotExist;
        OnInsertTempPurchLineInBufferOnBeforeTempPurchLineInsert(TempPurchaseLine, PurchaseLine);
        TempPurchaseLine.Insert();
    end;

    local procedure TransferItemChargeAssgntPurchToTemp(var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferItemChargeAssgntPurchToTemp(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", "No.");
        if ItemChargeAssgntPurch.FindSet then begin
            repeat
                TempItemChargeAssgntPurch := ItemChargeAssgntPurch;
                TempItemChargeAssgntPurch.Insert();
            until ItemChargeAssgntPurch.Next() = 0;
            ItemChargeAssgntPurch.DeleteAll();
        end;
    end;

    procedure OpenPurchaseOrderStatistics()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenPurchaseOrderStatistics(Rec, IsHandled);
        if IsHandled then
            exit;

        OpenDocumentStatisticsInternal();
    end;

    procedure OpenDocumentStatistics()
    begin
        OpenDocumentStatisticsInternal();
    end;

    procedure PrepareOpeningDocumentStatistics()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if not WritePermission() or not PurchaseLine.WritePermission() then
            Error(StatisticsInsuffucientPermissionsErr);

        CalcInvDiscForHeader();
        if IsOrderDocument() then
            CreateDimSetForPrepmtAccDefaultDim();

        OnAfterPrepareOpeningDocumentStatistics(Rec);

        Commit();
    end;

    procedure ShowDocumentStatisticsPage()
    var
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        StatisticsPageId: Integer;
    begin
        StatisticsPageId := GetStatisticsPageID();

        OnGetStatisticsPageID(StatisticsPageId, Rec);

        PAGE.RunModal(StatisticsPageId, Rec);

        PurchCalcDiscByType.ResetRecalculateInvoiceDisc(Rec);
    end;

    local procedure OpenDocumentStatisticsInternal()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenDocumentStatistics(Rec, IsHandled);
        if IsHandled then
            exit;

        PrepareOpeningDocumentStatistics();
        ShowDocumentStatisticsPage();
    end;

    local procedure IsOrderDocument(): Boolean
    begin
        case "Document Type" of
            "Document Type"::Order,
            "Document Type"::"Blanket Order",
            "Document Type"::"Return Order":
                exit(true);
        end;

        exit(false);
    end;

    local procedure GetStatisticsPageID(): Integer
    begin
        if IsOrderDocument() then
            exit(PAGE::"Purchase Order Statistics");

        exit(PAGE::"Purchase Statistics");
    end;

    procedure GetCardpageID(): Integer
    begin
        case "Document Type" of
            "Document Type"::Quote:
                exit(PAGE::"Purchase Quote");
            "Document Type"::Order:
                exit(PAGE::"Purchase Order");
            "Document Type"::Invoice:
                exit(PAGE::"Purchase Invoice");
            "Document Type"::"Credit Memo":
                exit(PAGE::"Purchase Credit Memo");
            "Document Type"::"Blanket Order":
                exit(PAGE::"Blanket Purchase Order");
            "Document Type"::"Return Order":
                exit(PAGE::"Purchase Return Order");
        end;
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnCheckPurchasePostRestrictions()
    begin
    end;

    procedure CheckPurchasePostRestrictions()
    begin
        OnCheckPurchasePostRestrictions();
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnCheckPurchaseReleaseRestrictions()
    begin
    end;

    procedure CheckPurchaseReleaseRestrictions()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OnCheckPurchaseReleaseRestrictions();
        ApprovalsMgmt.PrePostApprovalCheckPurch(Rec);
    end;

    procedure SetStatus(NewStatus: Option)
    begin
        Status := "Purchase Document Status".FromInteger(NewStatus);
        Modify;
    end;

    procedure TriggerOnAfterPostPurchaseDoc(var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20])
    var
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchPost.OnAfterPostPurchaseDoc(Rec, GenJnlPostLine, PurchRcpHdrNo, RetShptHdrNo, PurchInvHdrNo, PurchCrMemoHdrNo, false);
    end;

    procedure DeferralHeadersExist(): Boolean
    var
        DeferralHeader: Record "Deferral Header";
    begin
        DeferralHeader.SetRange("Deferral Doc. Type", "Deferral Document Type"::Purchase);
        DeferralHeader.SetRange("Gen. Jnl. Template Name", '');
        DeferralHeader.SetRange("Gen. Jnl. Batch Name", '');
        DeferralHeader.SetRange("Document Type", "Document Type");
        DeferralHeader.SetRange("Document No.", "No.");
        exit(not DeferralHeader.IsEmpty);
    end;

    local procedure ConfirmUpdateDeferralDate()
    begin
        if GetHideValidationDialog or not GuiAllowed then
            Confirmed := true
        else
            Confirmed := Confirm(DeferralLineQst, false, FieldCaption("Posting Date"));
        if Confirmed then
            UpdatePurchLinesByFieldNo(PurchLine.FieldNo("Deferral Code"), false);
    end;

    procedure IsCreditDocType(): Boolean
    var
        CreditDocType: Boolean;
    begin
        CreditDocType := "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"];
        OnBeforeIsCreditDocType(Rec, CreditDocType);
        exit(CreditDocType);
    end;

    procedure SetBuyFromVendorFromFilter()
    var
        BuyFromVendorNo: Code[20];
    begin
        BuyFromVendorNo := GetFilterVendNo;
        if BuyFromVendorNo = '' then begin
            FilterGroup(2);
            BuyFromVendorNo := GetFilterVendNo;
            FilterGroup(0);
        end;
        if BuyFromVendorNo <> '' then
            Validate("Buy-from Vendor No.", BuyFromVendorNo);
    end;

    procedure CopyBuyFromVendorFilter()
    var
        BuyFromVendorFilter: Text;
    begin
        BuyFromVendorFilter := GetFilter("Buy-from Vendor No.");
        if BuyFromVendorFilter <> '' then begin
            FilterGroup(2);
            SetFilter("Buy-from Vendor No.", BuyFromVendorFilter);
            FilterGroup(0)
        end;
    end;

    local procedure GetFilterVendNo(): Code[20]
    begin
        if GetFilter("Buy-from Vendor No.") <> '' then
            if GetRangeMin("Buy-from Vendor No.") = GetRangeMax("Buy-from Vendor No.") then
                exit(GetRangeMax("Buy-from Vendor No."));
    end;

    procedure HasBuyFromAddress() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasBuyFromAddress(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case true of
            "Buy-from Address" <> '':
                exit(true);
            "Buy-from Address 2" <> '':
                exit(true);
            "Buy-from City" <> '':
                exit(true);
            "Buy-from Country/Region Code" <> '':
                exit(true);
            "Buy-from County" <> '':
                exit(true);
            "Buy-from Post Code" <> '':
                exit(true);
            "Buy-from Contact" <> '':
                exit(true);
        end;

        exit(false);
    end;

    procedure HasShipToAddress() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasShipToAddress(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

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

    procedure HasPayToAddress() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasPayToAddress(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case true of
            "Pay-to Address" <> '':
                exit(true);
            "Pay-to Address 2" <> '':
                exit(true);
            "Pay-to City" <> '':
                exit(true);
            "Pay-to Country/Region Code" <> '':
                exit(true);
            "Pay-to County" <> '':
                exit(true);
            "Pay-to Post Code" <> '':
                exit(true);
            "Pay-to Contact" <> '':
                exit(true);
        end;

        exit(false);
    end;

    local procedure HasItemChargeAssignment(): Boolean
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", "No.");
        ItemChargeAssgntPurch.SetFilter("Amount to Assign", '<>%1', 0);
        exit(not ItemChargeAssgntPurch.IsEmpty);
    end;

    local procedure CopyBuyFromVendorAddressFieldsFromVendor(var BuyFromVendor: Record Vendor; ForceCopy: Boolean)
    begin
        if BuyFromVendorIsReplaced or ShouldCopyAddressFromBuyFromVendor(BuyFromVendor) or ForceCopy then begin
            "Buy-from Address" := BuyFromVendor.Address;
            "Buy-from Address 2" := BuyFromVendor."Address 2";
            "Buy-from City" := BuyFromVendor.City;
            "Buy-from Post Code" := BuyFromVendor."Post Code";
            "Buy-from County" := BuyFromVendor.County;
            "Buy-from Country/Region Code" := BuyFromVendor."Country/Region Code";
            OnAfterCopyBuyFromVendorAddressFieldsFromVendor(Rec, BuyFromVendor);
        end;
    end;

    local procedure CopyShipToVendorAddressFieldsFromVendor(var BuyFromVendor: Record Vendor; ForceCopy: Boolean)
    begin
        if BuyFromVendorIsReplaced or (not HasShipToAddress) or ForceCopy then begin
            "Ship-to Address" := BuyFromVendor.Address;
            "Ship-to Address 2" := BuyFromVendor."Address 2";
            "Ship-to City" := BuyFromVendor.City;
            "Ship-to Post Code" := BuyFromVendor."Post Code";
            "Ship-to County" := BuyFromVendor.County;
            Validate("Ship-to Country/Region Code", BuyFromVendor."Country/Region Code");
            OnAfterCopyShipToVendorAddressFieldsFromVendor(Rec, BuyFromVendor);
        end;
    end;

    local procedure CopyPayToVendorAddressFieldsFromVendor(var PayToVendor: Record Vendor; ForceCopy: Boolean)
    begin
        if PayToVendorIsReplaced or ShouldCopyAddressFromPayToVendor(PayToVendor) or ForceCopy then begin
            "Pay-to Address" := PayToVendor.Address;
            "Pay-to Address 2" := PayToVendor."Address 2";
            "Pay-to City" := PayToVendor.City;
            "Pay-to Post Code" := PayToVendor."Post Code";
            "Pay-to County" := PayToVendor.County;
            "Pay-to Country/Region Code" := PayToVendor."Country/Region Code";
            OnAfterCopyPayToVendorAddressFieldsFromVendor(Rec, PayToVendor);
        end;
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

    local procedure ShouldCopyAddressFromBuyFromVendor(BuyFromVendor: Record Vendor): Boolean
    begin
        exit((not HasBuyFromAddress) and BuyFromVendor.HasAddress);
    end;

    local procedure ShouldCopyAddressFromPayToVendor(PayToVendor: Record Vendor): Boolean
    begin
        exit((not HasPayToAddress) and PayToVendor.HasAddress);
    end;

    procedure ShouldSearchForVendorByName(VendorNo: Code[20]) Result: Boolean
    var
        Vendor: Record Vendor;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldSearchForVendorByName(VendorNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if VendorNo = '' then
            exit(true);

        if not Vendor.Get(VendorNo) then
            exit(true);

        exit(not Vendor."Disable Search by Name");
    end;

    local procedure BuyFromVendorIsReplaced(): Boolean
    begin
        exit((xRec."Buy-from Vendor No." <> '') and (xRec."Buy-from Vendor No." <> "Buy-from Vendor No."));
    end;

    local procedure PayToVendorIsReplaced(): Boolean
    begin
        exit((xRec."Pay-to Vendor No." <> '') and (xRec."Pay-to Vendor No." <> "Pay-to Vendor No."));
    end;

    procedure CopyBuyFromAddressToPayToAddress()
    begin
        if "Pay-to Vendor No." = "Buy-from Vendor No." then begin
            "Pay-to Address" := "Buy-from Address";
            "Pay-to Address 2" := "Buy-from Address 2";
            "Pay-to Post Code" := "Buy-from Post Code";
            "Pay-to Country/Region Code" := "Buy-from Country/Region Code";
            "Pay-to City" := "Buy-from City";
            "Pay-to County" := "Buy-from County";
            OnAfterCopyBuyFromAddressToPayToAddress(Rec);
        end;
    end;

    local procedure UpdatePayToAddressFromBuyFromAddress(FieldNumber: Integer)
    begin
        if ("Order Address Code" = '') and PayToAddressEqualsOldBuyFromAddress then
            case FieldNumber of
                FieldNo("Pay-to Address"):
                    if xRec."Buy-from Address" = "Pay-to Address" then
                        "Pay-to Address" := "Buy-from Address";
                FieldNo("Pay-to Address 2"):
                    if xRec."Buy-from Address 2" = "Pay-to Address 2" then
                        "Pay-to Address 2" := "Buy-from Address 2";
                FieldNo("Pay-to City"), FieldNo("Pay-to Post Code"):
                    begin
                        if xRec."Buy-from City" = "Pay-to City" then
                            "Pay-to City" := "Buy-from City";
                        if xRec."Buy-from Post Code" = "Pay-to Post Code" then
                            "Pay-to Post Code" := "Buy-from Post Code";
                        if xRec."Buy-from County" = "Pay-to County" then
                            "Pay-to County" := "Buy-from County";
                        if xRec."Buy-from Country/Region Code" = "Pay-to Country/Region Code" then
                            "Pay-to Country/Region Code" := "Buy-from Country/Region Code";
                    end;
                FieldNo("Pay-to County"):
                    if xRec."Buy-from County" = "Pay-to County" then
                        "Pay-to County" := "Buy-from County";
                FieldNo("Pay-to Country/Region Code"):
                    if xRec."Buy-from Country/Region Code" = "Pay-to Country/Region Code" then
                        "Pay-to Country/Region Code" := "Buy-from Country/Region Code";
            end;
    end;

    local procedure PayToAddressEqualsOldBuyFromAddress(): Boolean
    begin
        if (xRec."Buy-from Address" = "Pay-to Address") and
           (xRec."Buy-from Address 2" = "Pay-to Address 2") and
           (xRec."Buy-from City" = "Pay-to City") and
           (xRec."Buy-from County" = "Pay-to County") and
           (xRec."Buy-from Post Code" = "Pay-to Post Code") and
           (xRec."Buy-from Country/Region Code" = "Pay-to Country/Region Code")
        then
            exit(true);
    end;

    procedure ConfirmCloseUnposted(): Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if PurchLinesExist then
            if InstructionMgt.IsUnpostedEnabledForRecord(Rec) then
                exit(InstructionMgt.ShowConfirm(DocumentNotPostedClosePageQst, InstructionMgt.QueryPostOnCloseCode));
        exit(true)
    end;

    procedure InitFromPurchHeader(SourcePurchHeader: Record "Purchase Header")
    begin
        "Document Date" := SourcePurchHeader."Document Date";
        "Expected Receipt Date" := SourcePurchHeader."Expected Receipt Date";
        "Shortcut Dimension 1 Code" := SourcePurchHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := SourcePurchHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SourcePurchHeader."Dimension Set ID";
        "Location Code" := SourcePurchHeader."Location Code";
        SetShipToAddress(
          SourcePurchHeader."Ship-to Name", SourcePurchHeader."Ship-to Name 2", SourcePurchHeader."Ship-to Address",
          SourcePurchHeader."Ship-to Address 2", SourcePurchHeader."Ship-to City", SourcePurchHeader."Ship-to Post Code",
          SourcePurchHeader."Ship-to County", SourcePurchHeader."Ship-to Country/Region Code");
        "Ship-to Contact" := SourcePurchHeader."Ship-to Contact";

        OnInitFromPurchHeader(Rec, SourcePurchHeader);
    end;

    local procedure InitFromVendor(VendorNo: Code[20]; VendorCaption: Text): Boolean
    begin
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        if VendorNo = '' then begin
            if not PurchLine.IsEmpty() then
                Error(Text005, VendorCaption);
            Init;
            "No. Series" := xRec."No. Series";
            OnInitFromVendorOnBeforeInitRecord(Rec, xRec);
            InitRecord;
            InitNoSeries;
            exit(true);
        end;
    end;

    local procedure InitFromContact(ContactNo: Code[20]; VendorNo: Code[20]; ContactCaption: Text): Boolean
    begin
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        if (ContactNo = '') and (VendorNo = '') then begin
            if not PurchLine.IsEmpty() then
                Error(Text005, ContactCaption);
            Init;
            GetPurchSetup();
            "No. Series" := xRec."No. Series";
            OnInitFromContactOnBeforeInitRecord(Rec, xRec);
            InitRecord;
            InitNoSeries;
            exit(true);
        end;
    end;

    local procedure LookupContact(VendorNo: Code[20]; ContactNo: Code[20]; var Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Vendor, VendorNo) then
            Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.")
        else
            Contact.SetRange("Company No.", '');
        if ContactNo <> '' then
            if Contact.Get(ContactNo) then;
    end;

    procedure SendRecords()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportSelections: Record "Report Selections";
        DocTxt: Text[150];
    begin
        CheckMixedDropShipment;
        OnSendRecordsOnAfterCheckMixedDropShipment(Rec);

        GetReportSelectionsUsageFromDocumentType(ReportSelections.Usage, DocTxt);

        DocumentSendingProfile.SendVendorRecords(
          ReportSelections.Usage.AsInteger(), Rec, DocTxt, "Buy-from Vendor No.", "No.",
          FieldNo("Buy-from Vendor No."), FieldNo("No."));
    end;

    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        CheckMixedDropShipment;
        OnPrintRecordsOnAfterCheckMixedDropShipment(Rec);

        IsHandled := false;
        OnPrintRecordsOnBeforeTrySendToPrinterVendor(Rec, IsHandled);
        if not IsHandled then
            DocumentSendingProfile.TrySendToPrinterVendor(
                DummyReportSelections.Usage::"P.Order".AsInteger(), Rec, FieldNo("Buy-from Vendor No."), ShowRequestForm);
    end;

    procedure SendProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    var
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        IsHandled: Boolean;
    begin
        CheckMixedDropShipment;
        IsHandled := false;
        OnSendProfileOnBeforeSendVendor(Rec, IsHandled);
        if not IsHandled then
            DocumentSendingProfile.SendVendor(
                DummyReportSelections.Usage::"P.Order".AsInteger(), Rec, "No.", "Buy-from Vendor No.",
                ReportDistributionMgt.GetFullDocumentTypeText(Rec), FieldNo("Buy-from Vendor No."), FieldNo("No."));
    end;

    local procedure CheckMixedDropShipment()
    begin
        if HasMixedDropShipment then
            Error(MixedDropshipmentErr);
    end;

    local procedure HasMixedDropShipment(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        HasDropShipmentLines: Boolean;
    begin
        PurchaseLine.SetRange("Document Type", "Document Type");
        PurchaseLine.SetRange("Document No.", "No.");
        PurchaseLine.SetFilter("No.", '<>%1', '');
        PurchaseLine.SetFilter(Type, '%1|%2', PurchaseLine.Type::Item, PurchaseLine.Type::"Fixed Asset");
        PurchaseLine.SetRange("Drop Shipment", true);

        HasDropShipmentLines := not PurchaseLine.IsEmpty;

        PurchaseLine.SetRange("Drop Shipment", false);

        exit(HasDropShipmentLines and not PurchaseLine.IsEmpty);
    end;

    local procedure SetDefaultPurchaser()
    var
        UserSetupPurchaserCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultPurchaser(Rec, IsHandled);
        if IsHandled then
            exit;

        UserSetupPurchaserCode := GetUserSetupPurchaserCode;
        if UserSetupPurchaserCode <> '' then
            if SalespersonPurchaser.Get(UserSetupPurchaserCode) then
                if not SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
                    Validate("Purchaser Code", UserSetupPurchaserCode);
    end;

    local procedure GetUserSetupPurchaserCode(): Code[20]
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit;

        exit(UserSetup."Salespers./Purch. Code");
    end;

    local procedure SetShipToCodeEmpty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetShipToCodeEmpty(Rec, IsHandled);
        if IsHandled then
            exit;

        Validate("Ship-to Code", '');
    end;

    procedure OnAfterValidateBuyFromVendorNo(var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader.GetFilter("Buy-from Vendor No.") = xPurchaseHeader."Buy-from Vendor No." then
            if PurchaseHeader."Buy-from Vendor No." <> xPurchaseHeader."Buy-from Vendor No." then
                PurchaseHeader.SetRange("Buy-from Vendor No.");
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
                UpdatePurchLinesByFieldNo(PurchLine.FieldNo("Deferral Code"), false);
        end;
        Commit();
    end;

    procedure SetAllowSelectNoSeries()
    begin
        SelectNoSeriesAllowed := true;
    end;

    local procedure ModifyPayToVendorAddress()
    var
        Vendor: Record Vendor;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeModifyPayToVendorAddress(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        GetPurchSetup();
        if PurchSetup."Ignore Updated Addresses" then
            exit;
        if IsCreditDocType() then
            exit;
        if ("Pay-to Vendor No." <> "Buy-from Vendor No.") and Vendor.Get("Pay-to Vendor No.") then
            if HasPayToAddress and HasDifferentPayToAddress(Vendor) then
                ShowModifyAddressNotification(GetModifyPayToVendorAddressNotificationId,
                  ModifyVendorAddressNotificationLbl, ModifyVendorAddressNotificationMsg,
                  'CopyPayToVendorAddressFieldsFromSalesDocument', "Pay-to Vendor No.",
                  "Pay-to Name", FieldName("Pay-to Vendor No."));
    end;

    local procedure ModifyVendorAddress()
    var
        Vendor: Record Vendor;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeModifyVendorAddress(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        GetPurchSetup();
        if PurchSetup."Ignore Updated Addresses" then
            exit;
        if IsCreditDocType() then
            exit;
        if Vendor.Get("Buy-from Vendor No.") and HasBuyFromAddress and HasDifferentBuyFromAddress(Vendor) then
            ShowModifyAddressNotification(GetModifyVendorAddressNotificationId,
              ModifyVendorAddressNotificationLbl, ModifyVendorAddressNotificationMsg,
              'CopyBuyFromVendorAddressFieldsFromSalesDocument', "Buy-from Vendor No.",
              "Buy-from Vendor Name", FieldName("Buy-from Vendor No."));
    end;

    local procedure ShowModifyAddressNotification(NotificationID: Guid; NotificationLbl: Text; NotificationMsg: Text; NotificationFunctionTok: Text; VendorNumber: Code[20]; VendorName: Text[100]; VendorNumberFieldName: Text)
    var
        MyNotifications: Record "My Notifications";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ModifyVendorAddressNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(NotificationID) then
            exit;

        ModifyVendorAddressNotification.Id := NotificationID;
        ModifyVendorAddressNotification.Message := StrSubstNo(NotificationMsg, VendorName);
        ModifyVendorAddressNotification.AddAction(NotificationLbl, CODEUNIT::"Document Notifications", NotificationFunctionTok);
        ModifyVendorAddressNotification.AddAction(
          DontShowAgainActionLbl, CODEUNIT::"Document Notifications", 'HidePurchaseNotificationForCurrentUser');
        ModifyVendorAddressNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        ModifyVendorAddressNotification.SetData(FieldName("Document Type"), Format("Document Type"));
        ModifyVendorAddressNotification.SetData(FieldName("No."), "No.");
        ModifyVendorAddressNotification.SetData(VendorNumberFieldName, VendorNumber);
        NotificationLifecycleMgt.SendNotification(ModifyVendorAddressNotification, RecordId);
    end;

    procedure RecallModifyAddressNotification(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
        ModifyVendorAddressNotification: Notification;
    begin
        if IsCreditDocType() or (not MyNotifications.IsEnabled(NotificationID)) then
            exit;
        ModifyVendorAddressNotification.Id := NotificationID;
        ModifyVendorAddressNotification.Recall;
    end;

    procedure GetModifyVendorAddressNotificationId(): Guid
    begin
        exit('CF3D0CD3-C54A-47D1-8A3F-57A6CCBA8DDE');
    end;

    procedure GetModifyPayToVendorAddressNotificationId(): Guid
    begin
        exit('16E45B3A-CB9F-4B2C-9F08-2BCE39E9E980');
    end;

    procedure GetShowExternalDocAlreadyExistNotificationId(): Guid
    begin
        exit('D87F624C-D3BE-4E6B-A369-D18AE269181A');
    end;

    procedure GetLineInvoiceDiscountResetNotificationId(): Guid
    begin
        exit('3DC9C8BC-0512-4A49-B587-256C308EBCAA');
    end;

    procedure SetModifyVendorAddressNotificationDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetModifyVendorAddressNotificationId,
          ModifyBuyFromVendorAddressNotificationNameTxt, ModifyBuyFromVendorAddressNotificationDescriptionTxt, true);
    end;

    procedure SetModifyPayToVendorAddressNotificationDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetModifyPayToVendorAddressNotificationId,
          ModifyPayToVendorAddressNotificationNameTxt, ModifyPayToVendorAddressNotificationDescriptionTxt, true);
    end;

    procedure SetShowExternalDocAlreadyExistNotificationDefaultState(DefaultState: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetShowExternalDocAlreadyExistNotificationId,
          ShowDocAlreadyExistNotificationNameTxt, ShowDocAlreadyExistNotificationDescriptionTxt, DefaultState);
    end;

    procedure DontNotifyCurrentUserAgain(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(NotificationID) then
            case NotificationID of
                GetModifyVendorAddressNotificationId:
                    MyNotifications.InsertDefault(NotificationID, ModifyBuyFromVendorAddressNotificationNameTxt,
                      ModifyBuyFromVendorAddressNotificationDescriptionTxt, false);
                GetModifyPayToVendorAddressNotificationId:
                    MyNotifications.InsertDefault(NotificationID, ModifyPayToVendorAddressNotificationNameTxt,
                      ModifyPayToVendorAddressNotificationDescriptionTxt, false);
            end;
    end;

    local procedure HasDifferentBuyFromAddress(Vendor: Record Vendor): Boolean
    begin
        exit(("Buy-from Address" <> Vendor.Address) or
          ("Buy-from Address 2" <> Vendor."Address 2") or
          ("Buy-from City" <> Vendor.City) or
          ("Buy-from Country/Region Code" <> Vendor."Country/Region Code") or
          ("Buy-from County" <> Vendor.County) or
          ("Buy-from Post Code" <> Vendor."Post Code") or
          ("Buy-from Contact" <> Vendor.Contact));
    end;

    local procedure HasDifferentPayToAddress(Vendor: Record Vendor): Boolean
    begin
        exit(("Pay-to Address" <> Vendor.Address) or
          ("Pay-to Address 2" <> Vendor."Address 2") or
          ("Pay-to City" <> Vendor.City) or
          ("Pay-to Country/Region Code" <> Vendor."Country/Region Code") or
          ("Pay-to County" <> Vendor.County) or
          ("Pay-to Post Code" <> Vendor."Post Code") or
          ("Pay-to Contact" <> Vendor.Contact));
    end;

    procedure FindPostedDocumentWithSameExternalDocNo(var VendorLedgerEntry: Record "Vendor Ledger Entry"; ExternalDocumentNo: Code[35]): Boolean
    var
        VendorMgt: Codeunit "Vendor Mgt.";
    begin
        VendorMgt.SetFilterForExternalDocNo(
          VendorLedgerEntry, GetGenJnlDocumentType, ExternalDocumentNo, "Pay-to Vendor No.", "Document Date");
        exit(VendorLedgerEntry.FindFirst);
    end;

    procedure FilterPartialReceived()
    var
        PurchaseHeaderOriginal: Record "Purchase Header";
        ReceiveFilter: Text;
        IsMarked: Boolean;
        ReceiveValue: Boolean;
    begin
        ReceiveFilter := GetFilter(Receive);
        SetRange(Receive);
        Evaluate(ReceiveValue, ReceiveFilter);

        PurchaseHeaderOriginal := Rec;
        if FindSet then
            repeat
                if not HasReceivedLines then
                    IsMarked := not ReceiveValue
                else
                    IsMarked := ReceiveValue;
                Mark(IsMarked);
            until Next() = 0;

        Rec := PurchaseHeaderOriginal;
        MarkedOnly(true);
    end;

    procedure FilterPartialInvoiced()
    var
        PurchaseHeaderOriginal: Record "Purchase Header";
        InvoiceFilter: Text;
        IsMarked: Boolean;
        InvoiceValue: Boolean;
    begin
        InvoiceFilter := GetFilter(Invoice);
        SetRange(Invoice);
        Evaluate(InvoiceValue, InvoiceFilter);

        PurchaseHeaderOriginal := Rec;
        if FindSet then
            repeat
                if not HasInvoicedLines then
                    IsMarked := not InvoiceValue
                else
                    IsMarked := InvoiceValue;
                Mark(IsMarked);
            until Next() = 0;

        Rec := PurchaseHeaderOriginal;
        MarkedOnly(true);
    end;

    local procedure HasReceivedLines(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", "Document Type");
        PurchaseLine.SetRange("Document No.", "No.");
        PurchaseLine.SetFilter("No.", '<>%1', '');
        PurchaseLine.SetFilter("Quantity Received", '<>%1', 0);
        exit(not PurchaseLine.IsEmpty);
    end;

    local procedure HasInvoicedLines(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", "Document Type");
        PurchaseLine.SetRange("Document No.", "No.");
        PurchaseLine.SetFilter("No.", '<>%1', '');
        PurchaseLine.SetFilter("Quantity Invoiced", '<>%1', 0);
        exit(not PurchaseLine.IsEmpty);
    end;

    local procedure ShowExternalDocAlreadyExistNotification(VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        InstructionMgt: Codeunit "Instruction Mgt.";
        DocAlreadyExistNotification: Notification;
    begin
        InstructionMgt.CreateMissingMyNotificationsWithDefaultState(GetShowExternalDocAlreadyExistNotificationId);

        if not IsDocAlreadyExistNotificationEnabled then
            exit;

        DocAlreadyExistNotification.Id := GetShowExternalDocAlreadyExistNotificationId;
        DocAlreadyExistNotification.Message :=
          StrSubstNo(PurchaseAlreadyExistsTxt, VendorLedgerEntry."Document Type", VendorLedgerEntry."External Document No.");
        DocAlreadyExistNotification.AddAction(ShowVendLedgEntryTxt, CODEUNIT::"Document Notifications", 'ShowVendorLedgerEntry');
        DocAlreadyExistNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        DocAlreadyExistNotification.SetData(FieldName("Document Type"), Format("Document Type"));
        DocAlreadyExistNotification.SetData(FieldName("No."), "No.");
        DocAlreadyExistNotification.SetData(VendorLedgerEntry.FieldName("Entry No."), Format(VendorLedgerEntry."Entry No."));
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(
          DocAlreadyExistNotification, RecordId, GetShowExternalDocAlreadyExistNotificationId);
    end;

    local procedure GetGenJnlDocumentType(): Enum "Gen. Journal Document Type"
    var
        RefGenJournalLine: Record "Gen. Journal Line";
    begin
        case "Document Type" of
            "Document Type"::"Blanket Order",
            "Document Type"::Quote,
            "Document Type"::Invoice,
            "Document Type"::Order:
                exit(RefGenJournalLine."Document Type"::Invoice);
            else
                exit(RefGenJournalLine."Document Type"::"Credit Memo");
        end;
    end;

    local procedure RecallExternalDocAlreadyExistsNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        if not IsDocAlreadyExistNotificationEnabled then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          RecordId, GetShowExternalDocAlreadyExistNotificationId, true);
    end;

    procedure IsDocAlreadyExistNotificationEnabled(): Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        exit(InstructionMgt.IsMyNotificationEnabled(GetShowExternalDocAlreadyExistNotificationId));
    end;

    procedure ShipToAddressEqualsCompanyShipToAddress(): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(IsShipToAddressEqualToCompanyShipToAddress(Rec, CompanyInformation));
    end;

    local procedure IsShipToAddressEqualToCompanyShipToAddress(PurchaseHeader: Record "Purchase Header"; CompanyInformation: Record "Company Information"): Boolean
    begin
        exit(
          (PurchaseHeader."Ship-to Address" = CompanyInformation."Ship-to Address") and
          (PurchaseHeader."Ship-to Address 2" = CompanyInformation."Ship-to Address 2") and
          (PurchaseHeader."Ship-to City" = CompanyInformation."Ship-to City") and
          (PurchaseHeader."Ship-to County" = CompanyInformation."Ship-to County") and
          (PurchaseHeader."Ship-to Post Code" = CompanyInformation."Ship-to Post Code") and
          (PurchaseHeader."Ship-to Country/Region Code" = CompanyInformation."Ship-to Country/Region Code") and
          (PurchaseHeader."Ship-to Name" = CompanyInformation."Ship-to Name"));
    end;

    procedure BuyFromAddressEqualsShipToAddress(): Boolean
    begin
        exit(
          ("Ship-to Address" = "Buy-from Address") and
          ("Ship-to Address 2" = "Buy-from Address 2") and
          ("Ship-to City" = "Buy-from City") and
          ("Ship-to County" = "Buy-from County") and
          ("Ship-to Post Code" = "Buy-from Post Code") and
          ("Ship-to Country/Region Code" = "Buy-from Country/Region Code") and
          ("Ship-to Name" = "Buy-from Vendor Name"));
    end;

    procedure BuyFromAddressEqualsPayToAddress(): Boolean
    begin
        exit(
          ("Pay-to Address" = "Buy-from Address") and
          ("Pay-to Address 2" = "Buy-from Address 2") and
          ("Pay-to City" = "Buy-from City") and
          ("Pay-to County" = "Buy-from County") and
          ("Pay-to Post Code" = "Buy-from Post Code") and
          ("Pay-to Country/Region Code" = "Buy-from Country/Region Code") and
          ("Pay-to Contact No." = "Buy-from Contact No.") and
          ("Pay-to Contact" = "Buy-from Contact"));
    end;

    local procedure SetPurchaserCode(PurchaserCodeToCheck: Code[20]; var PurchaserCodeToAssign: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPurchaserCode(Rec, PurchaserCodeToCheck, PurchaserCodeToAssign, IsHandled);
        if IsHandled then
            exit;

        if PurchaserCodeToCheck = '' then
            PurchaserCodeToCheck := GetUserSetupPurchaserCode();
        if SalespersonPurchaser.Get(PurchaserCodeToCheck) then begin
            if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
                PurchaserCodeToAssign := ''
            else
                PurchaserCodeToAssign := PurchaserCodeToCheck;
        end else
            PurchaserCodeToAssign := '';
    end;

    procedure ValidatePurchaserOnPurchHeader(PurchaseHeader2: Record "Purchase Header"; IsTransaction: Boolean; IsPostAction: Boolean)
    begin
        if PurchaseHeader2."Purchaser Code" <> '' then
            if SalespersonPurchaser.Get(PurchaseHeader2."Purchaser Code") then
                if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then begin
                    if IsTransaction then
                        Error(SalespersonPurchaser.GetPrivacyBlockedTransactionText(SalespersonPurchaser, IsPostAction, false));
                    if not IsTransaction then
                        Error(SalespersonPurchaser.GetPrivacyBlockedGenericText(SalespersonPurchaser, false));
                end;
    end;

    local procedure GetReportSelectionsUsageFromDocumentType(var ReportSelectionsUsage: Enum "Report Selection Usage"; var DocTxt: Text[150])
    var
        ReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        ReportUsage: Option;
    begin
        DocTxt := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        case "Document Type" of
            "Document Type"::Order:
                ReportSelectionsUsage := ReportSelections.Usage::"P.Order";
            "Document Type"::Quote:
                ReportSelectionsUsage := ReportSelections.Usage::"P.Quote";
        end;

        ReportUsage := ReportSelectionsUsage.AsInteger();
        OnAfterGetReportSelectionsUsageFromDocumentType(Rec, ReportUsage, DocTxt);
        ReportSelectionsUsage := "Report Selection Usage".FromInteger(ReportUsage);
    end;

    local procedure ValidateEmptySellToCustomerAndLocation()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateEmptySellToCustomerAndLocation(Rec, Vend, IsHandled);
        if IsHandled then
            exit;

        Validate("Sell-to Customer No.", '');
        if "Buy-from Vendor No." <> '' then
            GetVend("Buy-from Vendor No.");
        UpdateLocationCode(Vend."Location Code");
    end;

    procedure CheckForBlockedLines()
    var
        CurrentPurchLine: Record "Purchase Line";
        Item: Record Item;
        Resource: Record Resource;
    begin
        CurrentPurchLine.SetCurrentKey("Document Type", "Document No.", Type);
        CurrentPurchLine.SetRange("Document Type", "Document Type");
        CurrentPurchLine.SetRange("Document No.", "No.");
        CurrentPurchLine.SetFilter(Type, '%1|%2', CurrentPurchLine.Type::Item, CurrentPurchLine.Type::Resource);
        CurrentPurchLine.SetFilter("No.", '<>''''');

        if CurrentPurchLine.FindSet then
            repeat
                case CurrentPurchLine.Type of
                    CurrentPurchLine.Type::Item:
                        begin
                            Item.Get(CurrentPurchLine."No.");
                            Item.TestField(Blocked, false);
                        end;
                    CurrentPurchLine.Type::Resource:
                        begin
                            Resource.Get(CurrentPurchLine."No.");
                            Resource.CheckResourcePrivacyBlocked(false);
                            Resource.TestField(Blocked, false);
                        end;
                end;
            until CurrentPurchLine.Next() = 0;
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

        OnAfterTestStatusOpen();
    end;

    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    local procedure UpdateInboundWhseHandlingTime()
    begin
        if "Location Code" = '' then begin
            if InvtSetup.Get then
                "Inbound Whse. Handling Time" := InvtSetup."Inbound Whse. Handling Time";
        end else begin
            if Location.Get("Location Code") then;
            "Inbound Whse. Handling Time" := Location."Inbound Whse. Handling Time";
        end;

        OnAfterUpdateInboundWhseHandlingTime(Rec, CurrFieldNo);
    end;

    procedure GetFullDocTypeTxt() FullDocTypeTxt: Text
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetFullDocTypeTxt(Rec, FullDocTypeTxt, IsHandled);

        if IsHandled then
            exit;

        FullDocTypeTxt := SelectStr("Document Type".AsInteger() + 1, FullPurchaseTypesTxt);
    end;

    local procedure LookupPostCode(var City: Text[30]; var PCode: Code[20]; var County: Text[30]; var CountryRegionCode: Code[10]; CalledFromFieldNo: Integer)
    var
        xRecPurchaseHeader: Record "Purchase Header";
    begin
        xRecPurchaseHeader := Rec;
        PostCode.LookupPostCode(City, PCode, County, CountryRegionCode);
        OnLookupPostCode(CalledFromFieldNo, xRecPurchaseHeader, Rec);
    end;

    procedure CopyDocument()
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDocument(Rec, IsHandled);
        if IsHandled then
            exit;

        CopyPurchaseDocument.SetPurchHeader(Rec);
        CopyPurchaseDocument.RunModal;
    end;

    local procedure CheckBlockedVendOnDocs(Vend: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBlockedVendOnDocs(Rec, xRec, Vend, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        Vend.CheckBlockedVendOnDocs(Vend, false);
    end;

#if not CLEAN19
    [Obsolete('Replaced with LookupBuyFromVendorName(var VendorName: Text[100]): Boolean', '19.0')]
    procedure LookupBuyfromVendorName(): Boolean
    var
        Vendor: Record Vendor;
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
    begin
        Vendor.SetFilter("Date Filter", GetFilter("Date Filter"));
        if "Buy-from Vendor No." <> '' then
            Vendor.Get("Buy-from Vendor No.");

        if Vendor.LookupVendor(Vendor) then begin
            "Buy-from Vendor Name" := Vendor.Name;
            Validate("Buy-from Vendor No.", Vendor."No.");
            if "No." <> '' then
                StandardCodesMgt.CheckCreatePurchRecurringLines(Rec);
            OnLookupBuyfromVendorNameOnAfterSuccessfulLookup(Rec);
            exit(true);
        end;
    end;
#endif

    procedure LookupBuyFromVendorName(var VendorName: Text): Boolean
    var
        Vendor: Record Vendor;
        LookupStateManager: Codeunit "Lookup State Manager";
        RecVariant: Variant;
    begin
        Vendor.SetFilter("Date Filter", GetFilter("Date Filter"));
        if "Buy-from Vendor No." <> '' then
            Vendor.Get("Buy-from Vendor No.");

        if Vendor.LookupVendor(Vendor) then begin
            if Rec."Buy-from Vendor Name" = Vendor.Name then
                VendorName := ''
            else
                VendorName := Vendor.Name;
            RecVariant := Vendor;
            LookupStateManager.SaveRecord(RecVariant);
            exit(true);
        end;
    end;

    local procedure RecreateTempPurchLines(var TempPurchLine: Record "Purchase Line")
    begin
        repeat
            TestPurchLineFieldsBeforeRecreate();
            TempPurchLine := PurchLine;
            if PurchLine.Nonstock then begin
                PurchLine.Nonstock := false;
                PurchLine.Modify();
            end;
            OnRecreatePurchLinesOnBeforeTempPurchLineInsert(TempPurchLine, PurchLine);
            TempPurchLine.Insert();
            OnRecreateTempPurchLinesOnAfterTempPurchLineInsert(Rec, PurchLine, TempPurchLine);
        until PurchLine.Next() = 0;
    end;

    local procedure TestPurchLineFieldsBeforeRecreate()
    var
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchLineFieldsBeforeRecreate(Rec, PurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchLine.TestField("Quantity Received", 0);
        PurchLine.TestField("Quantity Invoiced", 0);
        PurchLine.TestField("Return Qty. Shipped", 0);
        PurchLine.CalcFields("Reserved Qty. (Base)");
        PurchLine.TestField("Reserved Qty. (Base)", 0);
        PurchLine.TestField("Receipt No.", '');
        PurchLine.TestField("Return Shipment No.", '');
        PurchLine.TestField("Blanket Order No.", '');
        IsHandled := false;
        OnRecreatePurchLinesOnDropShipmentSpecialOrder(PurchLine, IsHandled);
        if not IsHandled then
            if PurchLine."Drop Shipment" or PurchLine."Special Order" then begin
                case true of
                    PurchLine."Drop Shipment":
                        SalesHeader.Get(SalesHeader."Document Type"::Order, PurchLine."Sales Order No.");
                    PurchLine."Special Order":
                        SalesHeader.Get(SalesHeader."Document Type"::Order, PurchLine."Special Order Sales No.");
                end;
                TestField("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
                CheckShipToCode(SalesHeader."Ship-to Code");
            end;

        PurchLine.TestField("Prepmt. Amt. Inv.", 0);
    end;

    local procedure DeletePurchCommentLines()
    var
        PurchCommentLine: Record "Purch. Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeletePurchCommentLines(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        PurchCommentLine.DeleteComments("Document Type".AsInteger(), "No.");
    end;

    local procedure DeletePurchLines(var PurchLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeletePurchLines(Rec, xRec, PurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchLine.DeleteAll(true);
    end;

    procedure SetCalledFromWhseDoc(NewCalledFromWhseDoc: Boolean)
    begin
        CalledFromWhseDoc := NewCalledFromWhseDoc;
    end;

    local procedure UpdatePrepmtAmounts(var PurchaseLine: Record "Purchase Line")
    var
        Currency: Record Currency;
    begin
        Currency.Initialize("Currency Code");
        if "Document Type" = "Document Type"::Order then begin
            PurchaseLine."Prepmt. Line Amount" := Round(
                PurchaseLine."Line Amount" * PurchaseLine."Prepayment %" / 100, Currency."Amount Rounding Precision");
            if Abs(PurchaseLine."Inv. Discount Amount" + PurchaseLine."Prepmt. Line Amount") > Abs(PurchaseLine."Line Amount") then
                PurchaseLine."Prepmt. Line Amount" := PurchaseLine."Line Amount" - PurchaseLine."Inv. Discount Amount";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFullDocTypeTxt(var PurchaseHeader: Record "Purchase Header"; var FullDocTypeTxt: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetNoSeriesCode(PurchSetup: Record "Purchases & Payables Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostingNoSeriesCode(var PurchaseHeader: Record "Purchase Header"; PurchasesPayablesSetup: Record "Purchases & Payables Setup"; var PostingNos: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddShipToAddress(var PurchaseHeader: Record "Purchase Header"; SalesHeader: Record "Sales Header"; ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyAddressInfoFromOrderAddress(var OrderAddress: Record "Order Address")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNoSeries(var PurchHeader: Record "Purchase Header"; xPurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterChangePricesIncludingVAT(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBuyFromVendor(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPayToVendor(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPurchPrice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyBuyFromVendorFieldsFromVendor(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; xPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyBuyFromVendorAddressFieldsFromVendor(var PurchaseHeader: Record "Purchase Header"; BuyFromVendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPayToVendorAddressFieldsFromVendor(var PurchaseHeader: Record "Purchase Header"; PayToVendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyShipToVendorAddressFieldsFromVendor(var PurchaseHeader: Record "Purchase Header"; BuyFromVendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecreatePurchLine(var PurchLine: Record "Purchase Line"; var TempPurchLine: Record "Purchase Line" temporary; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteAllTempPurchLines(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsApprovedForPosting(PurchaseHeader: Record "Purchase Header"; var Approved: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsApprovedForPostingBatch(PurchaseHeader: Record "Purchase Header"; var Approved: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var PurchHeader: Record "Purchase Header"; PurchSetup: Record "Purchases & Payables Setup"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPostingNoSeriesCode(PurchaseHeader: Record "Purchase Header"; var PostingNos: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPrepaymentPostingNoSeriesCode(PurchaseHeader: Record "Purchase Header"; var PostingNos: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchSetup(PurchaseHeader: Record "Purchase Header"; var PurchasesPayablesSetup: Record "Purchases & Payables Setup"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetReportSelectionsUsageFromDocumentType(PurchaseHeader: Record "Purchase Header"; var ReportSelectionsUsage: Option; var DocTxt: Text[150]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetStatusStyleText(PurchaseHeader: Record "Purchase Header"; var StatusStyleText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetShipToForSpecOrder(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestNoSeries(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferSavedFields(var DestinationPurchaseLine: Record "Purchase Line"; SourcePurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBuyFromVend(var PurchaseHeader: Record "Purchase Header"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBuyFromCont(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePayToCont(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePayToVend(var PurchaseHeader: Record "Purchase Header"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchLinesByFieldNo(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; ChangedFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateShipToAddress(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCurrencyFactor(var PurchaseHeader: Record "Purchase Header"; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateInboundWhseHandlingTime(var PurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShipToCode(var PurchHeader: Record "Purchase Header"; Cust: Record Customer; ShipToAddr: Record "Ship-to Address")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAppliesToDocNoOnLookup(var PurchaseHeader: Record "Purchase Header"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchLinesByChangedFieldName(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; ChangedFieldName: Text[100]; ChangedFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var PurchaseHeader: Record "Purchase Header"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var PurchHeader: Record "Purchase Header"; xPurchHeader: Record "Purchase Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferExtendedTextForPurchaseLineRecreation(var PurchLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    procedure OnValidatePurchaseHeaderPayToVendorNo(Vendor: Record Vendor; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePurchaseHeaderPayToVendorNoOnBeforeCheckDocType(Vendor: Record Vendor; var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddSpecialOrderToAddress(var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var PurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReceiptInfo(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; PayTo: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShipToCodeChange(PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSpecialOrderSalesLineLink(PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShipToCode(PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmUpdateCurrencyFactor(PurchaseHeader: Record "Purchase Header"; var HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeContactIsNotRelatedToVendorError(Contact: Record Contact; ContactNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmResvDateConflict(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; ChangedFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchaseLines(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRecordInApprovalRequest(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitInsert(var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRecord(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; xPurchaseHeader: Record "Purchase Header"; PurchSetup: Record "Purchases & Payables Setup"; GLSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsCreditDocType(PurchaseHeader: Record "Purchase Header"; var CreditDocType: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsTotalValid(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasBuyFromAddress(var PurchaseHeader: Record "Purchase Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasShipToAddress(var PurchaseHeader: Record "Purchase Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasPayToAddress(var PurchaseHeader: Record "Purchase Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupAppliesToDocNo(var PurchaseHeader: Record "Purchase Header"; var VendorLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupReceivingNoSeries(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupReturnShipmentNoSeries(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPayToVendorAddress(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyVendorAddress(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPurchaseOrderStatistics(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetShipToCodeEmpty(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldSearchForVendorByName(VendorNo: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferSavedJobFields(var DestinationPurchaseLine: Record "Purchase Line"; SourcePurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferSavedFields(var DestinationPurchaseLine: Record "Purchase Line"; SourcePurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCurrencyFactor(var PurchaseHeader: Record "Purchase Header"; var Updated: Boolean; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchLineAmounts(var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreatePurchLines(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreatePurchLinesHandler(var PurchHeader: Record "Purchase Header"; xPurchHeader: Record "Purchase Header"; ChangedFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDocDim(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendToPosting(var PurchaseHeader: Record "Purchase Header"; var IsSuccess: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultPurchaser(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPurchaserCode(var PurchaseHeader: Record "Purchase Header"; PurchaserCodeToCheck: Code[20]; var PurchaserCodeToAssign: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferSavedFieldsDropShipment(var DestinationPurchaseLine: Record "Purchase Line"; var SourcePurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferSavedFieldsSpecialOrder(var DestinationPurchaseLine: Record "Purchase Line"; var SourcePurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAllLineDim(var PurchaseHeader: Record "Purchase Header"; NewParentDimSetID: Integer; OldParentDimSetID: Integer; var IsHandled: Boolean; xPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLocationCode(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchLinesByFieldNo(var PurchaseHeader: Record "Purchase Header"; ChangedFieldNo: Integer; var AskQuestion: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToAddress(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEmptySellToCustomerAndLocation(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectParamsInBufferForCreateDimSetOnAfterSetTempPurchLineFilters(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePayToVendorNo(var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header"; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePricesIncludingVAT(var PurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLocationCode(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDocumentDateWithPostingDate(var PurchaseHeader: Record "Purchase Header"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBuyFromCityOnBeforeOnLookup(var PurchaseHeader: Record "Purchase Header"; PostCode: record "Post Code"; var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBuyFromPostCodeOnBeforeOnLookup(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnBeforeUpdateLines(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempPurchLineInBufferOnBeforeTempPurchLineInsert(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreatePurchLinesOnAfterValidateType(var PurchaseLine: Record "Purchase Line"; TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreatePurchLinesOnBeforeInsertPurchLine(var PurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary; ChangedFieldName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreatePurchLinesOnBeforeTempPurchLineInsert(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreatePurchLineOnAfterProcessAttachedToLineNo(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintRecordsOnAfterCheckMixedDropShipment(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendRecordsOnAfterCheckMixedDropShipment(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShipToPostCodeOnBeforeOnLookup(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; PostCode: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBuyFromVendorNoOnAfterRecreateLines(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBuyFromVendorNoBeforeRecreateLines(var PurchaseHeader: Record "Purchase Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBuyFromVendorNoOnAfterUpdateBuyFromCont(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBuyFromVendorNoOnValidateBuyFromVendorNoOnBeforeValidatePayToVendor(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRename(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPostedDocsToPrintCreatedMsg(var ShowPostedDocsToPrint: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenDocumentStatistics(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareOpeningDocumentStatistics(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetStatisticsPageID(var PageID: Integer; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeTestStatusOpen(var PurchHeader: Record "Purchase Header"; xPurchHeader: Record "Purchase Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterTestStatusOpen()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchLines(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromPurchHeader(var PurchaseHeader: Record "Purchase Header"; SourcePurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromContactOnBeforeInitRecord(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromVendorOnBeforeInitRecord(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitInsertOnBeforeInitRecord(var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitRecordOnAfterAssignDates(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreatePurchLinesOnBeforeConfirm(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; ChangedFieldName: Text[100]; HideValidationDialog: Boolean; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintRecordsOnBeforeTrySendToPrinterVendor(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendProfileOnBeforeSendVendor(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestStatusIsNotPendingApproval(PurchaseHeader: Record "Purchase Header"; var NotPending: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestStatusIsNotPendingPrepayment(PurchaseHeader: Record "Purchase Header"; var NotPending: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestStatusIsNotReleased(PurchaseHeader: Record "Purchase Header"; var NotReleased: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforePurchLineModify(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchLinesByFieldNoOnBeforeLineModify(var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchLinesByFieldNoOnBeforeValidateFields(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var ChangedFieldNo: Integer; var PurchaseHeader: record "Purchase Header"; var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderAddressCodeOnAfterCopyBuyFromVendorAddressFieldsFromVendor(var PurchaseHeader: Record "Purchase Header"; Vend: Record Vendor);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOrderAddressCodeOnBeforeUpdateLocationCode(var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalcDueDate(var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalcPmtDiscDate(var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeValidateDueDate(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeValidateDueDateWhenBlank(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePayToVendorNoOnBeforeGetPayToVend(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePayToVendorNoOnBeforeRecallModifyAddressNotification(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaytoVendorNoBeforeRecreateLines(var PurchaseHeader: Record "Purchase Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePricesIncludingVATOnBeforePurchLineModify(var PurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; Currency: Record Currency; RecalculatePrice: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATBaseAmountPercOnBeforeUpdatePurchAmountLines(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupPostCode(CalledFromFieldNo: Integer; xRecPurchaseHeader: Record "Purchase Header"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupBuyfromVendorNameOnAfterSuccessfulLookup(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreatePurchLinesOnAfterPurchLineSetFilters(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreatePurchLinesOnDropShipmentSpecialOrder(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDocument(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreatePurchLinesOnBeforeTempPurchLineFindSet(var TempPurchLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeGetPurchLineNewDimsetID(var PurchLine: Record "Purchase Line"; NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnAfterGetPurchLineNewDimsetID(PurchHeader: Record "Purchase Header"; xPurchHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var NewDimSetID: Integer; NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePayToVendOnBeforeFindByContact(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePromisedReceiptDate(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReceivingNoSeries(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReturnShipmentNoSeries(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlockedVendOnDocs(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var Vend: Record Vendor; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchLineFieldsBeforeRecreate(var PurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateTempPurchLinesOnAfterTempPurchLineInsert(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchCommentLines(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStorePurchCommentLineToTemp(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferItemChargeAssgntPurchToTemp(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchLines(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreatePurchLinesOnBeforeTransferSavedFields(var Rec: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary; var IsHandled: Boolean; var PurchaseLine: record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyBuyFromAddressToPayToAddress(var Rec: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePrepmtPaymentTermsCodeOnCaseElseOnBeforeValidatePrepaymentDueDate(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePrepmtPaymentTermsCodeOnCaseIfOnBeforeValidatePrepaymentDueDate(var PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountToApply(var PurchaseHeader: Record "Purchase Header"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;
}

