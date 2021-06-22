table 5900 "Service Header"
{
    Caption = 'Service Header';
    DataCaptionFields = "No.", Name, Description;
    DrillDownPageID = "Service List";
    LookupPageID = "Service List";
    Permissions = TableData "Loaner Entry" = d,
                  TableData "Service Order Allocation" = rimd;

    fields
    {
        field(1; "Document Type"; Enum "Service Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                if ("Customer No." <> xRec."Customer No.") and (xRec."Customer No." <> '') then begin
                    if "Contract No." <> '' then
                        Error(
                          Text003,
                          FieldCaption("Customer No."),
                          "Document Type", FieldCaption("No."), "No.",
                          FieldCaption("Contract No."), "Contract No.");
                    if HideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        if ServItemLineExists then
                            Confirmed :=
                              ConfirmManagement.GetResponseOrDefault(
                                StrSubstNo(Text004, FieldCaption("Customer No.")), true)
                        else
                            if ServLineExists then
                                Confirmed :=
                                  ConfirmManagement.GetResponseOrDefault(
                                    StrSubstNo(Text057, FieldCaption("Customer No.")), true)
                            else
                                Confirmed :=
                                  ConfirmManagement.GetResponseOrDefault(
                                    StrSubstNo(Text005, FieldCaption("Customer No.")), true);
                    if Confirmed then begin
                        ServLine.SetRange("Document Type", "Document Type");
                        ServLine.SetRange("Document No.", "No.");
                        if "Document Type" = "Document Type"::Order then
                            ServLine.SetFilter("Quantity Shipped", '<>0')
                        else
                            if "Document Type" = "Document Type"::Invoice then begin
                                ServLine.SetRange("Customer No.", xRec."Customer No.");
                                ServLine.SetFilter("Shipment No.", '<>%1', '');
                            end;

                        if ServLine.FindFirst then begin
                            if "Document Type" = "Document Type"::Order then
                                ServLine.TestField("Quantity Shipped", 0)
                            else
                                ServLine.TestField("Shipment No.", '');
                        end;
                        Modify(true);

                        IsHandled := false;
                        OnValidateCustomerNoOnBeforeDeleteLines(Rec, IsHandled);
                        if IsHandled then begin
                            ServLine.LockTable();
                            ServLine.Reset();
                            ServLine.SetRange("Document Type", "Document Type");
                            ServLine.SetRange("Document No.", "No.");
                            ServLine.DeleteAll(true);

                            ServItemLine.LockTable();
                            ServItemLine.Reset();
                            ServItemLine.SetRange("Document Type", "Document Type");
                            ServItemLine.SetRange("Document No.", "No.");
                            ServItemLine.DeleteAll(true);
                        end;

                        Get("Document Type", "No.");
                        if "Customer No." = '' then begin
                            Init;
                            ServSetup.Get();
                            "No. Series" := xRec."No. Series";
                            InitRecord;
                            if xRec."Shipping No." <> '' then begin
                                "Shipping No. Series" := xRec."Shipping No. Series";
                                "Shipping No." := xRec."Shipping No.";
                            end;
                            if xRec."Posting No." <> '' then begin
                                "Posting No. Series" := xRec."Posting No. Series";
                                "Posting No." := xRec."Posting No.";
                            end;
                            exit;
                        end;
                    end else begin
                        Rec := xRec;
                        exit;
                    end;
                end;

                GetCust("Customer No.");
                if "Customer No." <> '' then begin
                    IsHandled := false;
                    OnBeforeCheckBlockedCustomer(Cust, IsHandled);
                    if not IsHandled then
                        Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, false);
                    Cust.TestField("Gen. Bus. Posting Group");
                    CopyCustomerFields(Cust);
                end;

                if "Customer No." = xRec."Customer No." then
                    if ShippedServLinesExist then
                        if not ApplicationAreaMgmt.IsSalesTaxEnabled then begin
                            TestField("VAT Bus. Posting Group", xRec."VAT Bus. Posting Group");
                            TestField("Gen. Bus. Posting Group", xRec."Gen. Bus. Posting Group");
                        end;

                Commit();
                Validate("Ship-to Code", Cust."Ship-to Code");
                if Cust."Bill-to Customer No." <> '' then
                    Validate("Bill-to Customer No.", Cust."Bill-to Customer No.")
                else begin
                    if "Bill-to Customer No." = "Customer No." then
                        SkipBillToContact := true;
                    Validate("Bill-to Customer No.", "Customer No.");
                    SkipBillToContact := false;
                end;

                Validate("Service Zone Code");

                if not SkipContact then
                    UpdateCont("Customer No.");
            end;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    ServSetup.Get();
                    TestNoSeriesManual;
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
                CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                if (xRec."Bill-to Customer No." <> "Bill-to Customer No.") and
                   (xRec."Bill-to Customer No." <> '')
                then begin
                    if HideValidationDialog then
                        Confirmed := true
                    else
                        Confirmed :=
                          ConfirmManagement.GetResponseOrDefault(
                            StrSubstNo(Text005, FieldCaption("Bill-to Customer No.")), true);
                    if Confirmed then begin
                        ServLine.SetRange("Document Type", "Document Type");
                        ServLine.SetRange("Document No.", "No.");
                        if "Document Type" = "Document Type"::Order then
                            ServLine.SetFilter("Quantity Shipped", '<>0')
                        else
                            if "Document Type" = "Document Type"::Invoice then
                                ServLine.SetFilter("Shipment No.", '<>%1', '');

                        if ServLine.FindFirst then
                            if "Document Type" = "Document Type"::Order then
                                ServLine.TestField("Quantity Shipped", 0)
                            else
                                ServLine.TestField("Shipment No.", '');
                        ServLine.Reset();
                    end else
                        "Bill-to Customer No." := xRec."Bill-to Customer No.";
                end;

                GetCust("Bill-to Customer No.");

                IsHandled := false;
                OnBeforeCheckBlockedCustomer(Cust, IsHandled);
                if not IsHandled then
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, false);

                Cust.TestField("Customer Posting Group");

                if GuiAllowed and not HideValidationDialog and
                   ("Document Type" in ["Document Type"::Quote, "Document Type"::Order, "Document Type"::Invoice])
                then
                    CustCheckCrLimit.ServiceHeaderCheck(Rec);

                CopyBillToCustomerFields(Cust);

                ValidateServPriceGrOnServItem;

                if "Bill-to Customer No." = xRec."Bill-to Customer No." then
                    if ShippedServLinesExist then begin
                        TestField("Customer Disc. Group", xRec."Customer Disc. Group");
                        TestField("Currency Code", xRec."Currency Code");
                    end;

                CreateDim(
                  DATABASE::"Service Order Type", "Service Order Type",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Service Contract Header", "Contract No.");

                Validate("Payment Terms Code");
                Validate("Payment Method Code");
                Validate("Currency Code");

                if (xRec."Customer No." = "Customer No.") and
                   (xRec."Bill-to Customer No." <> "Bill-to Customer No.")
                then
                    RecreateServLines(FieldCaption("Bill-to Customer No."));

                if not SkipBillToContact then
                    UpdateBillToCont("Bill-to Customer No.");
            end;
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
            end;
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
            TableRelation = "Ship-to Address".Code WHERE("Customer No." = FIELD("Customer No."));

            trigger OnValidate()
            var
                ShipToAddr: Record "Ship-to Address";
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                if ("Ship-to Code" <> xRec."Ship-to Code") and
                   ("Customer No." = xRec."Customer No.")
                then begin
                    if ("Contract No." <> '') and not HideValidationDialog then
                        Error(
                          Text003,
                          FieldCaption("Ship-to Code"),
                          "Document Type", FieldCaption("No."), "No.",
                          FieldCaption("Contract No."), "Contract No.");
                    if ServItemLineExists then begin
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text004, FieldCaption("Ship-to Code")), true)
                        then begin
                            "Ship-to Code" := xRec."Ship-to Code";
                            exit;
                        end;
                    end else
                        if ServLineExists then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text057, FieldCaption("Ship-to Code")), true)
                            then begin
                                "Ship-to Code" := xRec."Ship-to Code";
                                exit;
                            end;
                end;

                if "Document Type" <> "Document Type"::"Credit Memo" then
                    if "Ship-to Code" <> '' then begin
                        if xRec."Ship-to Code" <> '' then begin
                            GetCust("Customer No.");
                            if Cust."Location Code" <> '' then
                                "Location Code" := Cust."Location Code";
                            "Tax Area Code" := Cust."Tax Area Code";
                        end;
                        ShipToAddr.Get("Customer No.", "Ship-to Code");
                        SetShipToAddress(
                          ShipToAddr.Name, ShipToAddr."Name 2", ShipToAddr.Address, ShipToAddr."Address 2",
                          ShipToAddr.City, ShipToAddr."Post Code", ShipToAddr.County, ShipToAddr."Country/Region Code");
                        "Ship-to Contact" := ShipToAddr.Contact;
                        "Ship-to Phone" := ShipToAddr."Phone No.";
                        if ShipToAddr."Location Code" <> '' then
                            "Location Code" := ShipToAddr."Location Code";
                        "Ship-to Fax No." := ShipToAddr."Fax No.";
                        "Ship-to E-Mail" := ShipToAddr."E-Mail";
                        if ShipToAddr."Tax Area Code" <> '' then
                            "Tax Area Code" := ShipToAddr."Tax Area Code";
                        "Tax Liable" := ShipToAddr."Tax Liable";
                    end else
                        if "Customer No." <> '' then begin
                            GetCust("Customer No.");
                            SetShipToAddress(
                              Cust.Name, Cust."Name 2", Cust.Address, Cust."Address 2",
                              Cust.City, Cust."Post Code", Cust.County, Cust."Country/Region Code");
                            "Ship-to Contact" := Cust.Contact;
                            "Ship-to Phone" := Cust."Phone No.";
                            "Tax Area Code" := Cust."Tax Area Code";
                            "Tax Liable" := Cust."Tax Liable";
                            if Cust."Location Code" <> '' then
                                "Location Code" := Cust."Location Code";
                            "Ship-to Fax No." := Cust."Fax No.";
                            "Ship-to E-Mail" := Cust."E-Mail";
                        end;

                if (xRec."Customer No." = "Customer No.") and
                   (xRec."Ship-to Code" <> "Ship-to Code")
                then
                    if (xRec."VAT Country/Region Code" <> "VAT Country/Region Code") or
                       (xRec."Tax Area Code" <> "Tax Area Code")
                    then
                        RecreateServLines(FieldCaption("Ship-to Code"))
                    else begin
                        if xRec."Tax Liable" <> "Tax Liable" then
                            Validate("Tax Liable");
                    end;

                Validate("Service Zone Code");

                IsHandled := false;
                OnValidateShipToCodeOnBeforeDleereLines(Rec, IsHandled);
                if not IsHandled then
                    if ("Ship-to Code" <> xRec."Ship-to Code") and
                    ("Customer No." = xRec."Customer No.")
                    then begin
                        Modify(true);
                        ServLine.LockTable();
                        ServItemLine.LockTable();
                        ServLine.Reset();
                        ServLine.SetRange("Document Type", "Document Type");
                        ServLine.SetRange("Document No.", "No.");
                        ServLine.DeleteAll(true);
                        ServItemLine.Reset();
                        ServItemLine.SetRange("Document Type", "Document Type");
                        ServItemLine.SetRange("Document No.", "No.");
                        ServItemLine.DeleteAll(true);
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
                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
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
            Caption = 'Order Date';
            NotBlank = true;

            trigger OnValidate()
            begin
                if "Order Date" <> xRec."Order Date" then begin
                    if ("Order Date" > "Starting Date") and
                       ("Starting Date" <> 0D)
                    then
                        Error(Text007, FieldCaption("Order Date"), FieldCaption("Starting Date"));

                    if ("Order Date" > "Finishing Date") and
                       ("Finishing Date" <> 0D)
                    then
                        Error(Text007, FieldCaption("Order Date"), FieldCaption("Finishing Date"));

                    if "Starting Time" <> 0T then
                        Validate("Starting Time");
                    ServItemLine.Reset();
                    ServItemLine.SetCurrentKey("Document Type", "Document No.", "Starting Date");
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    ServItemLine.SetFilter("Starting Date", '<>%1', 0D);
                    if ServItemLine.Find('-') then
                        repeat
                            if ServItemLine."Starting Date" < "Order Date" then
                                Error(
                                  Text027, FieldCaption("Order Date"),
                                  ServItemLine.FieldCaption("Starting Date"));
                        until ServItemLine.Next = 0;

                    ServItemLine.Reset();
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    if ServItemLine.Find('-') then
                        repeat
                            ServItemLine.CheckWarranty("Order Date");
                            ServItemLine.CalculateResponseDateTime("Order Date", "Order Time");
                            ServItemLine.Modify();
                        until ServItemLine.Next = 0;
                    UpdateServLinesByFieldNo(FieldNo("Order Date"), false);
                end;
            end;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            var
                NoSeries: Record "No. Series";
            begin
                if ("Posting No." <> '') and ("Posting No. Series" <> '') then begin
                    NoSeries.Get("Posting No. Series");
                    if NoSeries."Date Order" then
                        Error(
                          Text045,
                          FieldCaption("Posting Date"), FieldCaption("Posting No. Series"), "Posting No. Series",
                          NoSeries.FieldCaption("Date Order"), NoSeries."Date Order", "Document Type",
                          FieldCaption("Posting No."), "Posting No.");
                end;

                TestField("Posting Date");
                Validate("Document Date", "Posting Date");

                ServLine.SetRange("Document Type", "Document Type");
                ServLine.SetRange("Document No.", "No.");
                if ServLine.FindSet then
                    repeat
                        if "Posting Date" <> ServLine."Posting Date" then begin
                            ServLine."Posting Date" := "Posting Date";
                            ServLine.Modify();
                        end;
                    until ServLine.Next = 0;

                if ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) and
                   not ("Posting Date" = xRec."Posting Date")
                then begin
                    if ServLineExists then
                        ServLine.ModifyAll("Posting Date", "Posting Date");
                end;

                if "Currency Code" <> '' then begin
                    UpdateCurrencyFactor;
                    if "Currency Factor" <> xRec."Currency Factor" then
                        ConfirmUpdateCurrencyFactor;
                end;
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
                PaymentTerms: Record "Payment Terms";
                IsHandled: Boolean;
            begin
                if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                    PaymentTerms.Get("Payment Terms Code");
                    if ("Document Type" in ["Document Type"::"Credit Memo"]) and
                       not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos"
                    then begin
                        Validate("Due Date", "Document Date");
                        Validate("Pmt. Discount Date", 0D);
                        Validate("Payment Discount %", 0);
                    end else begin
                        "Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                        "Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                        Validate("Payment Discount %", PaymentTerms."Discount %")
                    end;
                end else begin
                    IsHandled := false;
                    OnValidatePaymentTermsCodeOnBeforeValidateDueDate(Rec, IsHandled);
                    if not IsHandled then
                        Validate("Due Date", "Document Date");
                    Validate("Pmt. Discount Date", 0D);
                    Validate("Payment Discount %", 0);
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
                TestField("Release Status", "Release Status"::Open);
            end;
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;

            trigger OnValidate()
            begin
                if ("Location Code" <> xRec."Location Code") and
                   ("Customer No." = xRec."Customer No.")
                then
                    MessageIfServLinesExist(FieldCaption("Location Code"));

                UpdateShipToAddress;
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
                CheckHeaderDimension;
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
                CheckHeaderDimension;
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
            begin
                if CurrFieldNo <> FieldNo("Currency Code") then
                    UpdateCurrencyFactor
                else
                    if "Currency Code" <> xRec."Currency Code" then begin
                        if ServLineExists and ("Contract No." <> '') and
                           ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"])
                        then
                            Error(Text058, FieldCaption("Currency Code"), "Document Type", "No.", "Contract No.");

                        UpdateCurrencyFactor;
                        ValidateServPriceGrOnServItem;
                    end else
                        if "Currency Code" <> '' then begin
                            UpdateCurrencyFactor;
                            if "Currency Factor" <> xRec."Currency Factor" then
                                ConfirmUpdateCurrencyFactor;
                        end;
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
                    UpdateServLinesByFieldNo(FieldNo("Currency Factor"), false);
            end;
        }
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                PriceMsgIfServLinesExist(FieldCaption("Customer Price Group"));
            end;
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';

            trigger OnValidate()
            var
                ServLine: Record "Service Line";
                Currency: Record Currency;
                ConfirmManagement: Codeunit "Confirm Management";
                RecalculatePrice: Boolean;
            begin
                if "Prices Including VAT" <> xRec."Prices Including VAT" then begin
                    TestField("Max. Labor Unit Price", 0);
                    ServLine.SetRange("Document Type", "Document Type");
                    ServLine.SetRange("Document No.", "No.");
                    ServLine.SetFilter(Type, '>0');
                    ServLine.SetFilter(Quantity, '<>0');
                    if ServLine.Find('-') then
                        repeat
                            ServLine.Amount := 0;
                            ServLine."Amount Including VAT" := 0;
                            ServLine."VAT Base Amount" := 0;
                            ServLine.InitOutstandingAmount;
                            ServLine.Modify();
                        until ServLine.Next = 0;
                    ServLine.SetRange(Type);
                    ServLine.SetRange(Quantity);

                    ServLine.SetFilter("Unit Price", '<>%1', 0);
                    ServLine.SetFilter("VAT %", '<>%1', 0);
                    if ServLine.Find('-') then begin
                        RecalculatePrice :=
                          ConfirmManagement.GetResponseOrDefault(
                            StrSubstNo(
                              Text055,
                              FieldCaption("Prices Including VAT"), ServLine.FieldCaption("Unit Price")),
                            true);
                        ServLine.SetServHeader(Rec);

                        if "Currency Code" = '' then
                            Currency.InitRoundingPrecision
                        else
                            Currency.Get("Currency Code");

                        repeat
                            ServLine.TestField("Quantity Invoiced", 0);
                            if not RecalculatePrice then begin
                                ServLine."VAT Difference" := 0;
                                ServLine.InitOutstandingAmount;
                            end else
                                if "Prices Including VAT" then begin
                                    ServLine."Unit Price" :=
                                      Round(
                                        ServLine."Unit Price" * (1 + (ServLine."VAT %" / 100)),
                                        Currency."Unit-Amount Rounding Precision");
                                    if ServLine.Quantity <> 0 then begin
                                        ServLine."Line Discount Amount" :=
                                          Round(
                                            ServLine.CalcChargeableQty * ServLine."Unit Price" * ServLine."Line Discount %" / 100,
                                            Currency."Amount Rounding Precision");
                                        ServLine.Validate("Inv. Discount Amount",
                                          Round(
                                            ServLine."Inv. Discount Amount" * (1 + (ServLine."VAT %" / 100)),
                                            Currency."Amount Rounding Precision"));
                                    end;
                                end else begin
                                    ServLine."Unit Price" :=
                                      Round(
                                        ServLine."Unit Price" / (1 + (ServLine."VAT %" / 100)),
                                        Currency."Unit-Amount Rounding Precision");
                                    if ServLine.Quantity <> 0 then begin
                                        ServLine."Line Discount Amount" :=
                                          Round(
                                            ServLine.CalcChargeableQty * ServLine."Unit Price" * ServLine."Line Discount %" / 100,
                                            Currency."Amount Rounding Precision");
                                        ServLine.Validate("Inv. Discount Amount",
                                          Round(
                                            ServLine."Inv. Discount Amount" / (1 + (ServLine."VAT %" / 100)),
                                            Currency."Amount Rounding Precision"));
                                    end;
                                end;
                            ServLine.Modify();
                        until ServLine.Next = 0;
                    end;
                end;
            end;
        }
        field(37; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';

            trigger OnLookup()
            begin
                MessageIfServLinesExist(FieldCaption("Invoice Disc. Code"));
            end;
        }
        field(40; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";

            trigger OnValidate()
            begin
                MessageIfServLinesExist(FieldCaption("Customer Disc. Group"));
            end;
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnValidate()
            begin
                MessageIfServLinesExist(FieldCaption("Language Code"));
            end;
        }
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                ValidateSalesPersonOnServiceHeader(Rec, false, false);

                CreateDim(
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Service Order Type", "Service Order Type",
                  DATABASE::"Service Contract Header", "Contract No.");
            end;
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = Exist ("Service Comment Line" WHERE("Table Name" = CONST("Service Header"),
                                                              "Table Subtype" = FIELD("Document Type"),
                                                              "No." = FIELD("No."),
                                                              Type = CONST(General)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
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
                GenJnlLine: Record "Gen. Journal Line";
                GenJnlApply: Codeunit "Gen. Jnl.-Apply";
                ApplyCustEntries: Page "Apply Customer Entries";
            begin
                TestField("Bal. Account No.", '');
                CustLedgEntry.SetApplyToFilters("Bill-to Customer No.", "Applies-to Doc. Type", "Applies-to Doc. No.", 0);

                ApplyCustEntries.SetService(Rec, CustLedgEntry, ServHeader.FieldNo("Applies-to Doc. No."));
                ApplyCustEntries.SetTableView(CustLedgEntry);
                ApplyCustEntries.SetRecord(CustLedgEntry);
                ApplyCustEntries.LookupMode(true);
                if ApplyCustEntries.RunModal = ACTION::LookupOK then begin
                    ApplyCustEntries.GetCustLedgEntry(CustLedgEntry);
                    GenJnlApply.CheckAgainstApplnCurrency(
                      "Currency Code", CustLedgEntry."Currency Code", GenJnlLine."Account Type"::Customer, true);
                    "Applies-to Doc. Type" := CustLedgEntry."Document Type";
                    "Applies-to Doc. No." := CustLedgEntry."Document No.";
                end;
                Clear(ApplyCustEntries);
            end;

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
            begin
                if "Applies-to Doc. No." <> '' then
                    TestField("Bal. Account No.", '');

                if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (xRec."Applies-to Doc. No." <> '') and
                   ("Applies-to Doc. No." <> '')
                then begin
                    CustLedgEntry.SetAmountToApply("Applies-to Doc. No.", "Customer No.");
                    CustLedgEntry.SetAmountToApply(xRec."Applies-to Doc. No.", "Customer No.");
                end else
                    if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (xRec."Applies-to Doc. No." = '') then
                        CustLedgEntry.SetAmountToApply("Applies-to Doc. No.", "Customer No.")
                    else
                        if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and ("Applies-to Doc. No." = '') then
                            CustLedgEntry.SetAmountToApply(xRec."Applies-to Doc. No.", "Customer No.");
            end;
        }
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account";

            trigger OnValidate()
            var
                GLAcc: Record "G/L Account";
                BankAcc: Record "Bank Account";
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
            TableRelation = "Service Shipment Header";
        }
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            Editable = false;
            TableRelation = "Service Invoice Header";
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

            trigger OnValidate()
            var
                GenBusPostingGroup: Record "Gen. Business Posting Group";
            begin
                if "Gen. Bus. Posting Group" <> xRec."Gen. Bus. Posting Group" then begin
                    if GenBusPostingGroup.ValidateVatBusPostingGroup(GenBusPostingGroup, "Gen. Bus. Posting Group") then
                        "VAT Bus. Posting Group" := GenBusPostingGroup."Def. VAT Bus. Posting Group";
                    RecreateServLines(FieldCaption("Gen. Bus. Posting Group"));
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
                UpdateServLinesByFieldNo(FieldNo("Transaction Type"), false);
            end;
        }
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";

            trigger OnValidate()
            begin
                UpdateServLinesByFieldNo(FieldNo("Transport Method"), false);
            end;
        }
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(79; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(80; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(81; Address; Text[100])
        {
            Caption = 'Address';

            trigger OnValidate()
            begin
                UpdateShipToAddressFromGeneralAddress(FieldNo("Ship-to Address"));
            end;
        }
        field(82; "Address 2"; Text[50])
        {
            Caption = 'Address 2';

            trigger OnValidate()
            begin
                UpdateShipToAddressFromGeneralAddress(FieldNo("Ship-to Address 2"));
            end;
        }
        field(83; City; Text[30])
        {
            Caption = 'City';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code".City
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code".City WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                UpdateShipToAddressFromGeneralAddress(FieldNo("Ship-to City"));
            end;
        }
        field(84; "Contact Name"; Text[100])
        {
            Caption = 'Contact Name';
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = IF ("Bill-to Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Bill-to Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Bill-to Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
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
        field(88; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = IF ("Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Country/Region Code"));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                UpdateShipToAddressFromGeneralAddress(FieldNo("Ship-to Post Code"));
            end;
        }
        field(89; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';

            trigger OnValidate()
            begin
                UpdateShipToAddressFromGeneralAddress(FieldNo("Ship-to County"));
            end;
        }
        field(90; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                UpdateShipToAddressFromGeneralAddress(FieldNo("Ship-to Country/Region Code"));

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
                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
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
        field(97; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";

            trigger OnValidate()
            begin
                UpdateServLinesByFieldNo(FieldNo("Exit Point"), false);
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
                Validate("Payment Terms Code");
            end;
        }
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;

            trigger OnValidate()
            begin
                UpdateServLinesByFieldNo(FieldNo(Area), false);
            end;
        }
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";

            trigger OnValidate()
            begin
                UpdateServLinesByFieldNo(FieldNo("Transaction Specification"), false);
            end;
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            var
                PaymentMethod: Record "Payment Method";
                SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
            begin
                if PaymentMethod.Get("Payment Method Code") then begin
                    "Bal. Account Type" := PaymentMethod."Bal. Account Type";
                    "Bal. Account No." := PaymentMethod."Bal. Account No.";
                    if PaymentMethod."Direct Debit" then begin
                        "Direct Debit Mandate ID" := SEPADirectDebitMandate.GetDefaultMandate("Bill-to Customer No.", "Due Date");
                        if "Payment Terms Code" = '' then
                            "Payment Terms Code" := PaymentMethod."Direct Debit Pmt. Terms Code";
                    end else
                        "Direct Debit Mandate ID" := '';
                end;
                if "Bal. Account No." <> '' then begin
                    TestField("Applies-to Doc. No.", '');
                    TestField("Applies-to ID", '');
                end;
            end;
        }
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                TestField("Release Status", "Release Status"::Open);
                if xRec."Shipping Agent Code" = "Shipping Agent Code" then
                    exit;

                "Shipping Agent Service Code" := '';
                GetShippingTime(FieldNo("Shipping Agent Code"));
                UpdateServLinesByFieldNo(FieldNo("Shipping Agent Code"), CurrFieldNo <> 0);
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
                with ServHeader do begin
                    ServHeader := Rec;
                    ServSetup.Get();
                    TestNoSeries;
                    if NoSeriesMgt.LookupSeries(GetPostingNoSeriesCode, "Posting No. Series") then
                        Validate("Posting No. Series");
                    Rec := ServHeader;
                end;
            end;

            trigger OnValidate()
            begin
                if "Posting No. Series" <> '' then begin
                    ServSetup.Get();
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

            trigger OnValidate()
            begin
                if "Shipping No. Series" <> '' then begin
                    ServSetup.Get();
                    ServSetup.TestField("Posted Service Shipment Nos.");
                    NoSeriesMgt.TestSeries(ServSetup."Posted Service Shipment Nos.", "Shipping No. Series");
                end;
                TestField("Shipping No.", '');
            end;
        }
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                MessageIfServLinesExist(FieldCaption("Tax Area Code"));
            end;
        }
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                MessageIfServLinesExist(FieldCaption("Tax Liable"));
            end;
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if "VAT Bus. Posting Group" <> xRec."VAT Bus. Posting Group" then
                    RecreateServLines(FieldCaption("VAT Bus. Posting Group"));
            end;
        }
        field(117; Reserve; Enum "Reserve Method")
        {
            Caption = 'Reserve';
        }
        field(118; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
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
            var
                IsHandled: Boolean;
            begin
                GLSetup.Get();
                if "VAT Base Discount %" > GLSetup."VAT Tolerance %" then
                    Error(
                      Text011,
                      FieldCaption("VAT Base Discount %"),
                      GLSetup.FieldCaption("VAT Tolerance %"),
                      GLSetup.TableCaption);

                if ("VAT Base Discount %" = xRec."VAT Base Discount %") and
                   (CurrFieldNo <> 0)
                then
                    exit;

                IsHandled := false;
                OnValidateVATBaseDiscountPctOnBeforeUpdateLineAmounts(Rec, IsHandled);
                if not IsHandled then begin
                    ServLine.Reset();
                    ServLine.SetRange("Document Type", "Document Type");
                    ServLine.SetRange("Document No.", "No.");
                    ServLine.SetFilter(Type, '<>%1', ServLine.Type::" ");
                    ServLine.SetFilter(Quantity, '<>0');
                    ServLine.LockTable();
                    LockTable();
                    if ServLine.FindSet then begin
                        Modify;
                        repeat
                            if (ServLine."Quantity Invoiced" <> ServLine.Quantity) or
                            ("Shipping Advice" = "Shipping Advice"::Complete) or
                            (CurrFieldNo <> 0)
                            then begin
                                ServLine.UpdateAmounts;
                                ServLine.Modify();
                            end;
                        until ServLine.Next = 0;
                    end;
                end;
            end;
        }
        field(120; Status; Enum "Service Document Status")
        {
            Caption = 'Status';

            trigger OnValidate()
            var
                JobQueueEntry: Record "Job Queue Entry";
                RepairStatus: Record "Repair Status";
            begin
                ServItemLine.Reset();
                ServItemLine.SetRange("Document Type", "Document Type");
                ServItemLine.SetRange("Document No.", "No.");
                LinesExist := true;
                if ServItemLine.Find('-') then
                    repeat
                        if ServItemLine."Repair Status Code" <> '' then begin
                            RepairStatus.Get(ServItemLine."Repair Status Code");
                            if ((Status = Status::Pending) and not RepairStatus."Pending Status Allowed") or
                               ((Status = Status::"In Process") and not RepairStatus."In Process Status Allowed") or
                               ((Status = Status::Finished) and not RepairStatus."Finished Status Allowed") or
                               ((Status = Status::"On Hold") and not RepairStatus."On Hold Status Allowed")
                            then
                                Error(
                                  Text031,
                                  FieldCaption(Status), Format(Status), TableCaption, "No.", ServItemLine.FieldCaption("Repair Status Code"),
                                  ServItemLine."Repair Status Code", ServItemLine.TableCaption, ServItemLine."Line No.")
                        end;
                    until ServItemLine.Next = 0
                else
                    LinesExist := false;

                case Status of
                    Status::"In Process":
                        begin
                            if not LinesExist then begin
                                "Starting Date" := WorkDate;
                                Validate("Starting Time", Time);
                            end else
                                UpdateStartingDateTime;
                        end;
                    Status::Finished:
                        begin
                            TestMandatoryFields(ServLine);
                            if Status <> xRec.Status then
                                if "Notify Customer" = "Notify Customer"::"By Email" then begin
                                    TestField("Customer No.");
                                    Clear(NotifyCust);
                                    NotifyCust.Run(Rec);
                                end;
                            if not LinesExist then begin
                                if ("Finishing Date" = 0D) and ("Finishing Time" = 0T) then begin
                                    "Finishing Date" := WorkDate;
                                    "Finishing Time" := Time;
                                end;
                            end else
                                UpdateFinishingDateTime;
                        end;
                end;

                if Status <> Status::Finished then begin
                    "Finishing Date" := 0D;
                    "Finishing Time" := 0T;
                    "Service Time (Hours)" := 0;
                end;

                if ("Starting Date" <> 0D) and
                   ("Finishing Date" <> 0D) and
                   not LinesExist
                then begin
                    CalcFields("Contract Serv. Hours Exist");
                    "Service Time (Hours)" :=
                      ServOrderMgt.CalcServTime(
                        "Starting Date", "Starting Time", "Finishing Date", "Finishing Time",
                        "Contract No.", "Contract Serv. Hours Exist");
                end;

                if Status = Status::Pending then
                    if ServSetup.Get then
                        if ServSetup."First Warning Within (Hours)" <> 0 then
                            if JobQueueEntry.WritePermission then begin
                                JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                                JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"ServOrder-Check Response Time");
                                JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"On Hold");
                                if JobQueueEntry.FindFirst then
                                    JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
                            end;
            end;
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
        field(130; "Release Status"; Option)
        {
            Caption = 'Release Status';
            Editable = false;
            OptionCaption = 'Open,Released to Ship';
            OptionMembers = Open,"Released to Ship";
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
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" WHERE("Customer No." = FIELD("Bill-to Customer No."),
                                                               Closed = CONST(false),
                                                               Blocked = CONST(false));
            DataClassification = SystemMetadata;
        }
        field(5052; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
            begin
                if "Customer No." <> '' then
                    if Cont.Get("Contact No.") then
                        Cont.SetRange("Company No.", Cont."Company No.")
                    else
                        if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Customer No.") then
                            Cont.SetRange("Company No.", ContBusinessRelation."Contact No.")
                        else
                            Cont.SetRange("No.", '');

                if "Contact No." <> '' then
                    if Cont.Get("Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    xRec := Rec;
                    Validate("Contact No.", Cont."No.");
                end;
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if ("Contact No." <> xRec."Contact No.") and
                   (xRec."Contact No." <> '')
                then begin
                    if HideValidationDialog then
                        Confirmed := true
                    else
                        Confirmed :=
                          ConfirmManagement.GetResponseOrDefault(
                            StrSubstNo(Text005, FieldCaption("Contact No.")), true);
                    if Confirmed then begin
                        ServLine.Reset();
                        ServLine.SetRange("Document Type", "Document Type");
                        ServLine.SetRange("Document No.", "No.");
                        if ("Contact No." = '') and ("Customer No." = '') then begin
                            if not ServLine.IsEmpty then
                                Error(Text050, FieldCaption("Contact No."));
                            InitRecordFromContact;
                            exit;
                        end;
                    end else begin
                        Rec := xRec;
                        exit;
                    end;
                end;

                if ("Customer No." <> '') and ("Contact No." <> '') then begin
                    Cont.Get("Contact No.");
                    if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Customer No.") and
                       (ContBusinessRelation."Contact No." <> Cont."Company No.")
                    then
                        Error(Text038, Cont."No.", Cont.Name, "Customer No.");
                end;

                UpdateCust("Contact No.");
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
            begin
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
                ContBusinessRelation: Record "Contact Business Relation";
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if ("Bill-to Contact No." <> xRec."Bill-to Contact No.") and
                   (xRec."Bill-to Contact No." <> '')
                then begin
                    if HideValidationDialog then
                        Confirmed := true
                    else
                        Confirmed :=
                          ConfirmManagement.GetResponseOrDefault(
                            StrSubstNo(Text005, FieldCaption("Bill-to Contact No.")), true);
                    if Confirmed then begin
                        ServLine.Reset();
                        ServLine.SetRange("Document Type", "Document Type");
                        ServLine.SetRange("Document No.", "No.");
                        if ("Bill-to Contact No." = '') and ("Bill-to Customer No." = '') then begin
                            if not ServLine.IsEmpty then
                                Error(Text050, FieldCaption("Bill-to Contact No."));
                            InitRecordFromContact;
                            exit;
                        end;
                    end else begin
                        "Bill-to Contact No." := xRec."Bill-to Contact No.";
                        exit;
                    end;
                end;

                if ("Bill-to Customer No." <> '') and ("Bill-to Contact No." <> '') then begin
                    Cont.Get("Bill-to Contact No.");
                    if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Bill-to Customer No.") and
                       (ContBusinessRelation."Contact No." <> Cont."Company No.")
                    then
                        Error(Text038, Cont."No.", Cont.Name, "Bill-to Customer No.");
                end;

                UpdateBillToCust("Bill-to Contact No.");
            end;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            var
                RespCenter: Record "Responsibility Center";
            begin
                if not UserSetupMgt.CheckRespCenter(2, "Responsibility Center") then
                    Error(
                      Text010,
                      RespCenter.TableCaption, UserSetupMgt.GetServiceFilter);

                UpdateShipToAddress;

                CreateDim(
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::"Service Order Type", "Service Order Type",
                  DATABASE::"Service Contract Header", "Contract No.");

                ServItemLine.Reset();
                ServItemLine.SetRange("Document Type", "Document Type");
                ServItemLine.SetRange("Document No.", "No.");
                if ServItemLine.Find('-') then
                    repeat
                        ServItemLine.Validate("Responsibility Center", "Responsibility Center");
                        ServItemLine.Modify(true);
                    until ServItemLine.Next = 0;

                if xRec."Responsibility Center" <> "Responsibility Center" then begin
                    RecreateServLines(FieldCaption("Responsibility Center"));
                    Validate("Location Code", UserSetupMgt.GetLocation(2, '', "Responsibility Center"));
                    "Assigned User ID" := '';
                end;
            end;
        }
        field(5750; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';

            trigger OnValidate()
            var
                WhseValidateSourceHeader: Codeunit "Whse. Validate Source Header";
            begin
                TestField("Release Status", "Release Status"::Open);
                if InventoryPickConflict("Document Type", "No.", "Shipping Advice") then
                    Error(Text064, FieldCaption("Shipping Advice"), Format("Shipping Advice"), TableCaption);
                if WhseShpmntConflict("Document Type", "No.", "Shipping Advice") then
                    Error(Text065, FieldCaption("Shipping Advice"), Format("Shipping Advice"), TableCaption);
                WhseValidateSourceHeader.ServiceHeaderVerifyChange(Rec, xRec);
            end;
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            CalcFormula = Min ("Service Line"."Completely Shipped" WHERE("Document Type" = FIELD("Document Type"),
                                                                         "Document No." = FIELD("No."),
                                                                         Type = FILTER(<> " "),
                                                                         "Location Code" = FIELD("Location Filter")));
            Caption = 'Completely Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5754; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location.Code;
        }
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                TestField("Release Status", "Release Status"::Open);
                if "Shipping Time" <> xRec."Shipping Time" then
                    UpdateServLinesByFieldNo(FieldNo("Shipping Time"), CurrFieldNo <> 0);
            end;
        }
        field(5794; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code WHERE("Shipping Agent Code" = FIELD("Shipping Agent Code"));

            trigger OnValidate()
            begin
                TestField("Release Status", "Release Status"::Open);
                GetShippingTime(FieldNo("Shipping Agent Service Code"));
                UpdateServLinesByFieldNo(FieldNo("Shipping Agent Service Code"), CurrFieldNo <> 0);
            end;
        }
        field(5796; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5902; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5904; "Service Order Type"; Code[10])
        {
            Caption = 'Service Order Type';
            TableRelation = "Service Order Type";

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Service Order Type", "Service Order Type",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Service Contract Header", "Contract No.");
            end;
        }
        field(5905; "Link Service to Service Item"; Boolean)
        {
            Caption = 'Link Service to Service Item';

            trigger OnValidate()
            begin
                if "Link Service to Service Item" <> xRec."Link Service to Service Item" then begin
                    ServLine.Reset();
                    ServLine.SetRange("Document Type", "Document Type");
                    ServLine.SetRange("Document No.", "No.");
                    ServLine.SetFilter(Type, '<>%1', ServLine.Type::Cost);
                    if ServLine.Find('-') then
                        Message(
                          Text001,
                          FieldCaption("Link Service to Service Item"),
                          "No.");
                end;
            end;
        }
        field(5907; Priority; Option)
        {
            Caption = 'Priority';
            Editable = false;
            OptionCaption = 'Low,Medium,High';
            OptionMembers = Low,Medium,High;
        }
        field(5911; "Allocated Hours"; Decimal)
        {
            CalcFormula = Sum ("Service Order Allocation"."Allocated Hours" WHERE("Document Type" = FIELD("Document Type"),
                                                                                  "Document No." = FIELD("No."),
                                                                                  "Allocation Date" = FIELD("Date Filter"),
                                                                                  "Resource No." = FIELD("Resource Filter"),
                                                                                  Status = FILTER(Active | Finished),
                                                                                  "Resource Group No." = FIELD("Resource Group Filter")));
            Caption = 'Allocated Hours';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5915; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(5916; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(5917; "Phone No. 2"; Text[30])
        {
            Caption = 'Phone No. 2';
            ExtendedDatatype = PhoneNo;
        }
        field(5918; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(5921; "No. of Unallocated Items"; Integer)
        {
            CalcFormula = Count ("Service Item Line" WHERE("Document Type" = FIELD("Document Type"),
                                                           "Document No." = FIELD("No."),
                                                           "No. of Active/Finished Allocs" = CONST(0)));
            Caption = 'No. of Unallocated Items';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5923; "Order Time"; Time)
        {
            Caption = 'Order Time';
            NotBlank = true;

            trigger OnValidate()
            begin
                if "Order Time" <> xRec."Order Time" then begin
                    if ("Order Time" > "Starting Time") and
                       ("Starting Time" <> 0T) and
                       ("Order Date" = "Starting Date")
                    then
                        Error(Text007, FieldCaption("Order Time"), FieldCaption("Starting Time"));
                    if "Starting Time" <> 0T then
                        Validate("Starting Time");
                    ServItemLine.Reset();
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    if ServItemLine.Find('-') then
                        repeat
                            ServItemLine.CalculateResponseDateTime("Order Date", "Order Time");
                            ServItemLine.Modify();
                        until ServItemLine.Next = 0;
                end;
            end;
        }
        field(5924; "Default Response Time (Hours)"; Decimal)
        {
            Caption = 'Default Response Time (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5925; "Actual Response Time (Hours)"; Decimal)
        {
            Caption = 'Actual Response Time (Hours)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(5926; "Service Time (Hours)"; Decimal)
        {
            Caption = 'Service Time (Hours)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5927; "Response Date"; Date)
        {
            Caption = 'Response Date';
            Editable = false;
        }
        field(5928; "Response Time"; Time)
        {
            Caption = 'Response Time';
            Editable = false;
        }
        field(5929; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                if "Starting Date" <> 0D then begin
                    if "Starting Date" < "Order Date" then
                        Error(Text026, FieldCaption("Starting Date"), FieldCaption("Order Date"));

                    if ("Starting Date" > "Finishing Date") and
                       ("Finishing Date" <> 0D)
                    then
                        Error(Text007, FieldCaption("Starting Date"), FieldCaption("Finishing Time"));

                    ServItemLine.Reset();
                    ServItemLine.SetCurrentKey("Document Type", "Document No.", "Starting Date");
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    ServItemLine.SetFilter("Starting Date", '<>%1', 0D);
                    if ServItemLine.Find('-') then
                        repeat
                            if ServItemLine."Starting Date" < "Starting Date" then
                                Error(Text024, FieldCaption("Starting Date"));
                        until ServItemLine.Next = 0;

                    if Time < "Order Time" then
                        Validate("Starting Time", "Order Time")
                    else
                        Validate("Starting Time", Time);
                end else begin
                    "Starting Time" := 0T;
                    "Actual Response Time (Hours)" := 0;
                    "Finishing Date" := 0D;
                    "Finishing Time" := 0T;
                    "Service Time (Hours)" := 0;
                end;
            end;
        }
        field(5930; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                TestField("Starting Date");

                if ("Starting Date" = "Finishing Date") and
                   ("Starting Time" > "Finishing Time")
                then
                    Error(Text007, FieldCaption("Starting Time"), FieldCaption("Finishing Time"));

                if ("Starting Date" = "Order Date") and
                   ("Starting Time" < "Order Time")
                then
                    Error(Text026, FieldCaption("Starting Time"), FieldCaption("Order Time"));

                if ("Starting Time" = 0T) and (xRec."Starting Time" <> 0T) then begin
                    "Finishing Time" := 0T;
                    "Finishing Date" := 0D;
                    "Service Time (Hours)" := 0;
                end;

                if ("Starting Time" <> 0T) and
                   ("Starting Date" <> 0D)
                then begin
                    CalcFields("Contract Serv. Hours Exist");
                    "Actual Response Time (Hours)" :=
                      ServOrderMgt.CalcServTime(
                        "Order Date", "Order Time", "Starting Date", "Starting Time",
                        "Contract No.", "Contract Serv. Hours Exist");
                end else
                    "Actual Response Time (Hours)" := 0;
                if "Finishing Time" <> 0T then
                    Validate("Finishing Time");
            end;
        }
        field(5931; "Finishing Date"; Date)
        {
            Caption = 'Finishing Date';

            trigger OnValidate()
            begin
                if "Finishing Date" <> 0D then begin
                    if "Finishing Date" < "Starting Date" then
                        Error(Text026, FieldCaption("Finishing Date"), FieldCaption("Starting Date"));

                    if "Finishing Date" < "Order Date" then
                        Error(
                          Text026,
                          FieldCaption("Finishing Date"),
                          FieldCaption("Order Date"));

                    if "Starting Date" = 0D then begin
                        "Starting Date" := "Finishing Date";
                        "Starting Time" := Time;
                        CalcFields("Contract Serv. Hours Exist");
                        "Actual Response Time (Hours)" :=
                          ServOrderMgt.CalcServTime(
                            "Order Date", "Order Time", "Starting Date", "Starting Time",
                            "Contract No.", "Contract Serv. Hours Exist");
                    end;

                    if "Finishing Date" <> xRec."Finishing Date" then begin
                        if Time < "Starting Time" then
                            "Finishing Time" := "Starting Time"
                        else
                            "Finishing Time" := Time;
                        Validate("Finishing Time");
                    end;

                    ServItemLine.Reset();
                    ServItemLine.SetCurrentKey("Document Type", "Document No.", "Finishing Date");
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    ServItemLine.SetFilter("Finishing Date", '<>%1', 0D);
                    if ServItemLine.Find('-') then
                        repeat
                            if ServItemLine."Finishing Date" > "Finishing Date" then
                                Error(Text025, FieldCaption("Finishing Date"));
                        until ServItemLine.Next = 0;
                end else begin
                    "Finishing Time" := 0T;
                    "Service Time (Hours)" := 0;
                end;
            end;
        }
        field(5932; "Finishing Time"; Time)
        {
            Caption = 'Finishing Time';

            trigger OnValidate()
            begin
                TestField("Finishing Date");
                if "Finishing Time" <> 0T then begin
                    if ("Starting Date" = "Finishing Date") and
                       ("Finishing Time" < "Starting Time")
                    then
                        Error(
                          Text026, FieldCaption("Finishing Time"),
                          FieldCaption("Starting Time"));

                    if ("Finishing Date" = "Order Date") and
                       ("Finishing Time" < "Order Time")
                    then
                        Error(
                          Text026, FieldCaption("Finishing Time"),
                          FieldCaption("Order Time"));

                    ServItemLine.Reset();
                    ServItemLine.SetCurrentKey("Document Type", "Document No.", "Finishing Date");
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    ServItemLine.SetFilter("Finishing Date", '<>%1', 0D);
                    if ServItemLine.Find('-') then
                        repeat
                            if (ServItemLine."Finishing Date" = "Finishing Date") and
                               (ServItemLine."Finishing Time" > "Finishing Time")
                            then
                                Error(Text025, FieldCaption("Finishing Time"));
                        until ServItemLine.Next = 0;

                    CalcFields("Contract Serv. Hours Exist");
                    "Service Time (Hours)" :=
                      ServOrderMgt.CalcServTime(
                        "Starting Date", "Starting Time", "Finishing Date", "Finishing Time",
                        "Contract No.", "Contract Serv. Hours Exist");
                end else
                    "Service Time (Hours)" := 0;
            end;
        }
        field(5933; "Contract Serv. Hours Exist"; Boolean)
        {
            CalcFormula = Exist ("Service Hour" WHERE("Service Contract No." = FIELD("Contract No.")));
            Caption = 'Contract Serv. Hours Exist';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5934; "Reallocation Needed"; Boolean)
        {
            CalcFormula = Exist ("Service Order Allocation" WHERE(Status = CONST("Reallocation Needed"),
                                                                  "Resource No." = FIELD("Resource Filter"),
                                                                  "Document Type" = FIELD("Document Type"),
                                                                  "Document No." = FIELD("No."),
                                                                  "Resource Group No." = FIELD("Resource Group Filter")));
            Caption = 'Reallocation Needed';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5936; "Notify Customer"; Option)
        {
            Caption = 'Notify Customer';
            OptionCaption = 'No,By Phone 1,By Phone 2,By Fax,By Email';
            OptionMembers = No,"By Phone 1","By Phone 2","By Fax","By Email";
        }
        field(5937; "Max. Labor Unit Price"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Max. Labor Unit Price';

            trigger OnValidate()
            begin
                if ServLineExists then
                    Message(
                      Text001,
                      FieldCaption("Max. Labor Unit Price"),
                      "No.");
            end;
        }
        field(5938; "Warning Status"; Option)
        {
            Caption = 'Warning Status';
            OptionCaption = ' ,First Warning,Second Warning,Third Warning';
            OptionMembers = " ","First Warning","Second Warning","Third Warning";
        }
        field(5939; "No. of Allocations"; Integer)
        {
            CalcFormula = Count ("Service Order Allocation" WHERE("Document Type" = FIELD("Document Type"),
                                                                  "Document No." = FIELD("No."),
                                                                  "Resource No." = FIELD("Resource Filter"),
                                                                  "Resource Group No." = FIELD("Resource Group Filter"),
                                                                  "Allocation Date" = FIELD("Date Filter"),
                                                                  Status = FILTER(Active | Finished)));
            Caption = 'No. of Allocations';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5940; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Service Contract Header"."Contract No." WHERE("Contract Type" = CONST(Contract),
                                                                            "Customer No." = FIELD("Customer No."),
                                                                            "Ship-to Code" = FIELD("Ship-to Code"),
                                                                            "Bill-to Customer No." = FIELD("Bill-to Customer No."));

            trigger OnLookup()
            var
                ServContractHeader: Record "Service Contract Header";
                ServContractList: Page "Service Contract List";
            begin
                if "Contract No." <> '' then
                    if ServContractHeader.Get(ServContractHeader."Contract Type"::Contract, "Contract No.") then
                        ServContractList.SetRecord(ServContractHeader);

                ServContractHeader.Reset();
                ServContractHeader.FilterGroup(2);
                ServContractHeader.SetCurrentKey("Customer No.", "Ship-to Code");
                ServContractHeader.SetRange("Customer No.", "Customer No.");
                ServContractHeader.SetRange("Ship-to Code", "Ship-to Code");
                ServContractHeader.SetRange("Contract Type", ServContractHeader."Contract Type"::Contract);
                ServContractHeader.SetRange("Bill-to Customer No.", "Bill-to Customer No.");
                ServContractHeader.SetRange(Status, ServContractHeader.Status::Signed);
                ServContractHeader.SetFilter("Starting Date", '<=%1', "Order Date");
                ServContractHeader.SetFilter("Expiration Date", '>=%1 | =%2', "Order Date", 0D);
                ServContractHeader.FilterGroup(0);
                Clear(ServContractList);
                ServContractList.SetTableView(ServContractHeader);
                ServContractList.LookupMode(true);
                if ServContractList.RunModal = ACTION::LookupOK then begin
                    ServContractList.GetRecord(ServContractHeader);
                    Validate("Contract No.", ServContractHeader."Contract No.");
                end;
            end;

            trigger OnValidate()
            var
                ServContractHeader: Record "Service Contract Header";
            begin
                if "Contract No." <> xRec."Contract No." then begin
                    if "Contract No." <> '' then begin
                        TestField("Order Date");
                        ServContractHeader.Get(ServContractHeader."Contract Type"::Contract, "Contract No.");
                        if ServContractHeader.Status <> ServContractHeader.Status::Signed then
                            Error(Text041, "Contract No.");
                        if ServContractHeader."Starting Date" > "Order Date" then
                            Error(Text042, "Contract No.");
                        if (ServContractHeader."Expiration Date" <> 0D) and
                           (ServContractHeader."Expiration Date" < "Order Date")
                        then
                            Error(Text043, "Contract No.");
                    end;
                    ServItemLine.Reset();
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    if ServItemLine.Find('-') then
                        Error(Text028,
                          FieldCaption("Contract No."), ServItemLine.TableCaption);

                    if not ConfirmChangeContractNo then begin
                        "Contract No." := xRec."Contract No.";
                        exit;
                    end;

                    if "Contract No." <> '' then begin
                        TestField("Customer No.");
                        TestField("Bill-to Customer No.");
                        "Default Response Time (Hours)" := ServContractHeader."Response Time (Hours)";
                        TestField("Ship-to Code", ServContractHeader."Ship-to Code");
                        "Service Order Type" := ServContractHeader."Service Order Type";
                        Validate("Currency Code", ServContractHeader."Currency Code");
                        "Max. Labor Unit Price" := ServContractHeader."Max. Labor Unit Price";
                        "Your Reference" := ServContractHeader."Your Reference";
                        "Service Zone Code" := ServContractHeader."Service Zone Code";
                    end;
                end;

                if "Contract No." <> '' then
                    CreateDim(
                      DATABASE::"Service Contract Header", "Contract No.",
                      DATABASE::"Service Order Type", "Service Order Type",
                      DATABASE::Customer, "Bill-to Customer No.",
                      DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                      DATABASE::"Responsibility Center", "Responsibility Center");
            end;
        }
        field(5951; "Type Filter"; Option)
        {
            Caption = 'Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,Resource,Item,Service Cost,Service Contract';
            OptionMembers = " ",Resource,Item,"Service Cost","Service Contract";
        }
        field(5952; "Customer Filter"; Code[20])
        {
            Caption = 'Customer Filter';
            FieldClass = FlowFilter;
            TableRelation = Customer."No.";
        }
        field(5953; "Resource Filter"; Code[20])
        {
            Caption = 'Resource Filter';
            FieldClass = FlowFilter;
            TableRelation = Resource;
        }
        field(5954; "Contract Filter"; Code[20])
        {
            Caption = 'Contract Filter';
            FieldClass = FlowFilter;
            TableRelation = "Service Contract Header"."Contract No." WHERE("Contract Type" = CONST(Contract));
        }
        field(5955; "Ship-to Fax No."; Text[30])
        {
            Caption = 'Ship-to Fax No.';
        }
        field(5956; "Ship-to E-Mail"; Text[80])
        {
            Caption = 'Ship-to Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("Ship-to E-Mail");
            end;
        }
        field(5957; "Resource Group Filter"; Code[20])
        {
            Caption = 'Resource Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Resource Group";
        }
        field(5958; "Ship-to Phone"; Text[30])
        {
            Caption = 'Ship-to Phone';
            ExtendedDatatype = PhoneNo;
        }
        field(5959; "Ship-to Phone 2"; Text[30])
        {
            Caption = 'Ship-to Phone 2';
            ExtendedDatatype = PhoneNo;
        }
        field(5966; "Service Zone Filter"; Code[10])
        {
            Caption = 'Service Zone Filter';
            FieldClass = FlowFilter;
            TableRelation = "Service Zone".Code;
        }
        field(5968; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            Editable = false;
            TableRelation = "Service Zone".Code;

            trigger OnValidate()
            var
                ShipToAddr: Record "Ship-to Address";
            begin
                if ShipToAddr.Get("Customer No.", "Ship-to Code") then
                    "Service Zone Code" := ShipToAddr."Service Zone Code"
                else
                    if Cust.Get("Customer No.") then
                        "Service Zone Code" := Cust."Service Zone Code"
                    else
                        "Service Zone Code" := '';
            end;
        }
        field(5981; "Expected Finishing Date"; Date)
        {
            Caption = 'Expected Finishing Date';
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
                MessageIfServLinesExist(FieldCaption("Allow Line Disc."));
            end;
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";

            trigger OnValidate()
            begin
                if not UserSetupMgt.CheckRespCenter(2, "Responsibility Center", "Assigned User ID") then
                    Error(Text060, "Assigned User ID", UserSetupMgt.GetServiceFilter("Assigned User ID"));
            end;
        }
        field(9001; "Quote No."; Code[20])
        {
            Caption = 'Quote No.';
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
        key(Key3; "Customer No.", "Order Date")
        {
        }
        key(Key4; "Contract No.", Status, "Posting Date")
        {
        }
        key(Key5; Status, "Response Date", "Response Time", Priority, "Responsibility Center")
        {
        }
        key(Key6; Status, Priority, "Response Date", "Response Time")
        {
        }
        key(Key7; "Document Type", "Customer No.", "Order Date")
        {
            MaintainSQLIndex = false;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Document Type", "No.", "Customer No.", "Posting Date", Status)
        {
        }
    }

    trigger OnDelete()
    var
        ServDocRegister: Record "Service Document Register";
        ServDocLog: Record "Service Document Log";
        ServOrderAlloc: Record "Service Order Allocation";
        ServCommentLine: Record "Service Comment Line";
        WhseRequest: Record "Warehouse Request";
        Loaner: Record Loaner;
        LoanerEntry: Record "Loaner Entry";
        ServAllocMgt: Codeunit ServAllocationManagement;
        ReservMgt: Codeunit "Reservation Management";
    begin
        if not UserSetupMgt.CheckRespCenter(2, "Responsibility Center") then
            Error(Text000, UserSetupMgt.GetServiceFilter);

        if "Document Type" = "Document Type"::Invoice then begin
            ServLine.Reset();
            ServLine.SetRange("Document Type", ServLine."Document Type"::Invoice);
            ServLine.SetRange("Document No.", "No.");
            ServLine.SetFilter("Appl.-to Service Entry", '>%1', 0);
            if not ServLine.IsEmpty then
                Error(Text046, "No.");
        end;

        ServPost.DeleteHeader(Rec, ServShptHeader, ServInvHeader, ServCrMemoHeader);
        Validate("Applies-to ID", '');

        ServLine.Reset();
        ServLine.LockTable();

        ReservMgt.DeleteDocumentReservation(DATABASE::"Service Line", "Document Type", "No.", HideValidationDialog);

        WhseRequest.DeleteRequest(DATABASE::"Service Line", "Document Type", "No.");

        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "No.");
        ServLine.SuspendStatusCheck(true);
        ServLine.DeleteAll(true);

        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Header");
        ServCommentLine.SetRange("Table Subtype", "Document Type");
        ServCommentLine.SetRange("No.", "No.");
        ServCommentLine.DeleteAll();

        ServDocRegister.SetCurrentKey("Destination Document Type", "Destination Document No.");
        case "Document Type" of
            "Document Type"::Invoice:
                begin
                    ServDocRegister.SetRange("Destination Document Type", ServDocRegister."Destination Document Type"::Invoice);
                    ServDocRegister.SetRange("Destination Document No.", "No.");
                    ServDocRegister.DeleteAll();
                end;
            "Document Type"::"Credit Memo":
                begin
                    ServDocRegister.SetRange("Destination Document Type", ServDocRegister."Destination Document Type"::"Credit Memo");
                    ServDocRegister.SetRange("Destination Document No.", "No.");
                    ServDocRegister.DeleteAll();
                end;
        end;

        ServOrderAlloc.Reset();
        ServOrderAlloc.SetCurrentKey("Document Type");
        ServOrderAlloc.SetRange("Document Type", "Document Type");
        ServOrderAlloc.SetRange("Document No.", "No.");
        ServOrderAlloc.SetRange(Posted, false);
        ServOrderAlloc.DeleteAll();
        ServAllocMgt.SetServOrderAllocStatus(Rec);

        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        if ServItemLine.Find('-') then
            repeat
                if ServItemLine."Loaner No." <> '' then begin
                    Loaner.Get(ServItemLine."Loaner No.");
                    LoanerEntry.SetRange("Document Type", "Document Type" + 1);
                    LoanerEntry.SetRange("Document No.", "No.");
                    LoanerEntry.SetRange("Loaner No.", ServItemLine."Loaner No.");
                    LoanerEntry.SetRange(Lent, true);
                    if not LoanerEntry.IsEmpty then
                        Error(
                          Text040,
                          TableCaption,
                          ServItemLine."Document No.",
                          ServItemLine."Line No.",
                          ServItemLine.FieldCaption("Loaner No."),
                          ServItemLine."Loaner No.");

                    LoanerEntry.SetRange(Lent, true);
                    LoanerEntry.DeleteAll();
                end;

                Clear(ServLogMgt);
                ServLogMgt.ServItemOffServOrder(ServItemLine);
                ServItemLine.Delete();
            until ServItemLine.Next = 0;

        ServDocLog.Reset();
        ServDocLog.SetRange("Document Type", "Document Type");
        ServDocLog.SetRange("Document No.", "No.");
        ServDocLog.DeleteAll();

        ServDocLog.Reset();
        ServDocLog.SetRange(Before, "No.");
        ServDocLog.SetFilter("Document Type", '%1|%2|%3',
          ServDocLog."Document Type"::Shipment, ServDocLog."Document Type"::"Posted Invoice",
          ServDocLog."Document Type"::"Posted Credit Memo");
        ServDocLog.DeleteAll();

        if (ServShptHeader."No." <> '') or
           (ServInvHeader."No." <> '') or
           (ServCrMemoHeader."No." <> '')
        then
            Message(PostedDocsToPrintCreatedMsg);
    end;

    trigger OnInsert()
    var
        ServShptHeader: Record "Service Shipment Header";
    begin
        ServSetup.Get();
        if "No." = '' then begin
            TestNoSeries;
            NoSeriesMgt.InitSeries(GetNoSeriesCode, xRec."No. Series", 0D, "No.", "No. Series");
        end;

        if "Document Type" = "Document Type"::Order then begin
            ServShptHeader.SetRange("Order No.", "No.");
            if not ServShptHeader.IsEmpty then
                Error(Text008, Format("Document Type"), FieldCaption("No."), "No.");
        end;

        InitRecord;

        Clear(ServLogMgt);
        ServLogMgt.ServHeaderCreate(Rec);

        if "Salesperson Code" = '' then
            SetDefaultSalesperson;

        if GetFilter("Customer No.") <> '' then begin
            Clear(xRec."Ship-to Code");
            if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then
                Validate("Customer No.", GetRangeMin("Customer No."));
        end;

        if GetFilter("Contact No.") <> '' then
            if GetRangeMin("Contact No.") = GetRangeMax("Contact No.") then
                Validate("Contact No.", GetRangeMin("Contact No."));
    end;

    trigger OnModify()
    begin
        UpdateServiceOrderChangeLog(xRec);
    end;

    trigger OnRename()
    begin
        Error(Text044, TableCaption);
    end;

    var
        Text000: Label 'You cannot delete this document. Your identification is set up to process from Responsibility Center %1 only.', Comment = '%1=User management service filter;';
        Text001: Label 'Changing %1 in service header %2 will not update the existing service lines.\You must update the existing service lines manually.';
        Text003: Label 'You cannot change the %1 because the %2 %3 %4 is associated with a %5 %6.', Comment = '%1=Customer number field caption;%2=Document type;%3=Number field caption;%4=Number;%5=Contract number field caption;%6=Contract number; ';
        Text004: Label 'When you change the %1 the existing Service item line and service line will be deleted.\Do you want to change the %1?';
        Text005: Label 'Do you want to change the %1?';
        Text007: Label '%1 cannot be greater than %2.';
        Text008: Label 'You cannot create Service %1 with %2=%3 because this number has already been used in the system.', Comment = '%1=Document type format;%2=Number field caption;%3=Number;';
        Text010: Label 'Your identification is set up to process from %1 %2 only.', Comment = '%1=Resposibility center table caption;%2=User management service filter;';
        Text011: Label '%1 cannot be greater than %2 in the %3 table.';
        Text012: Label 'If you change %1, the existing service lines will be deleted and the program will create new service lines based on the new information on the header.\Do you want to change the %1?';
        Text013: Label 'Deleting this document will cause a gap in the number series for posted credit memos. An empty posted credit memo %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text015: Label 'Do you want to update the exchange rate?';
        Text016: Label 'You have modified %1.\Do you want to update the service lines?';
        Text018: Label 'You have not specified the %1 for %2 %3=%4, %5=%6.', Comment = '%1=Service order type field caption;%2=table caption;%3=Document type field caption;%4=Document type format;%5=Number field caption;%6=Number format;';
        Text019: Label 'You have changed %1 on the service header, but it has not been changed on the existing service lines.\The change may affect the exchange rate used in the price calculation of the service lines.';
        Text021: Label 'You have changed %1 on the %2, but it has not been changed on the existing service lines.\You must update the existing service lines manually.';
        ServSetup: Record "Service Mgt. Setup";
        Cust: Record Customer;
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        ServItemLine: Record "Service Item Line";
        PostCode: Record "Post Code";
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        ServShptHeader: Record "Service Shipment Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        Salesperson: Record "Salesperson/Purchaser";
        ServOrderMgt: Codeunit ServOrderManagement;
        DimMgt: Codeunit DimensionManagement;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ServLogMgt: Codeunit ServLogManagement;
        UserSetupMgt: Codeunit "User Setup Management";
        NotifyCust: Codeunit "Customer-Notify by Email";
        ServPost: Codeunit "Service-Post";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        CurrencyDate: Date;
        TempLinkToServItem: Boolean;
        HideValidationDialog: Boolean;
        Text024: Label 'The %1 cannot be greater than the minimum %1 of the\ Service Item Lines.';
        Text025: Label 'The %1 cannot be less than the maximum %1 of the related\ Service Item Lines.';
        Text026: Label '%1 cannot be earlier than the %2.';
        Text027: Label 'The %1 cannot be greater than the minimum %2 of the related\ Service Item Lines.';
        ValidatingFromLines: Boolean;
        LinesExist: Boolean;
        Text028: Label 'You cannot change the %1 because %2 exists.';
        Text029: Label 'The %1 field on the %2 will be updated if you change %3 manually.\Do you want to continue?';
        Text031: Label 'You cannot change %1 to %2 in %3 %4.\\%5 %6 in %7 %8 line is preventing it.', Comment = '%1=Status field caption;%2=Status format;%3=table caption;%4=Number;%5=ServItemLine repair status code field caption;%6=ServItemLine repair status code;%7=ServItemLine table caption;%8=ServItemLine line number;';
        Text037: Label 'Contact %1 %2 is not related to customer %3.', Comment = '%1=Contact number;%2=Contact name;%3=Customer number;';
        Text038: Label 'Contact %1 %2 is related to a different company than customer %3.', Comment = '%1=Contact number;%2=Contact name;%3=Customer number;';
        Text039: Label 'Contact %1 %2 is not related to a customer.', Comment = '%1=Contact number;%2=Contact name;';
        ContactNo: Code[20];
        Text040: Label 'You cannot delete %1 %2 because the %4 %5 for Service Item Line %3 has not been received.', Comment = '%1=table caption;%2=ServItemLine document number;%3=ServItemLine line number;%4=ServItemLine loaner number field caption;%5=ServItemLine loaner number;';
        SkipContact: Boolean;
        SkipBillToContact: Boolean;
        Text041: Label 'Contract %1 is not signed.';
        Text042: Label 'The service period for contract %1 has not yet started.';
        Text043: Label 'The service period for contract %1 has expired.';
        Text044: Label 'You cannot rename a %1.';
        Confirmed: Boolean;
        Text045: Label 'You can not change the %1 field because %2 %3 has %4 = %5 and the %6 has already been assigned %7 %8.', Comment = '%1=Posting date field caption;%2=Posting number series field caption;%3=Posting number series;%4=NoSeries date order field caption;%5=NoSeries date order;%6=Document type;%7=posting number field caption;%8=Posting number;';
        Text046: Label 'You cannot delete invoice %1 because one or more service ledger entries exist for this invoice.';
        Text047: Label 'You cannot change %1 because reservation, item tracking, or order tracking exists on the sales order.';
        Text050: Label 'You cannot reset %1 because the document still has one or more lines.';
        Text051: Label 'The service %1 %2 already exists.', Comment = '%1=Document type format;%2=Number;';
        Text053: Label 'Deleting this document will cause a gap in the number series for shipments. An empty shipment %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text054: Label 'Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text055: Label 'You have modified the %1 field. Note that the recalculation of VAT may cause penny differences, so you must check the amounts afterwards. Do you want to update the %2 field on the lines to reflect the new value of %1?';
        Text057: Label 'When you change the %1 the existing service line will be deleted.\Do you want to change the %1?';
        Text058: Label 'You cannot change %1 because %2 %3 is linked to Contract %4.', Comment = '%1=Currency code field caption;%2=Document type;%3=Number;%4=Contract number;';
        Text060: Label 'Responsibility Center is set up to process from %1 %2 only.', Comment = '%1=Assigned user ID;%2=User management service filter assigned user id;';
        Text061: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        Text062: Label 'An open inventory pick exists for the %1 and because %2 is %3.\\You must first post or delete the inventory pick or change %2 to Partial.';
        Text063: Label 'An open warehouse shipment exists for the %1 and %2 is %3.\\You must add the item(s) as new line(s) to the existing warehouse shipment or change %2 to Partial.';
        Text064: Label 'You cannot change %1 to %2 because an open inventory pick on the %3.';
        Text065: Label 'You cannot change %1  to %2 because an open warehouse shipment exists for the %3.';
        Text066: Label 'You cannot change the dimension because there are service entries connected to this line.';
        PostedDocsToPrintCreatedMsg: Label 'One or more related posted documents have been generated during deletion to fill gaps in the posting number series. You can view or print the documents from the respective document archive.';
        DocumentNotPostedClosePageQst: Label 'The document has been saved but is not yet posted.\\Are you sure you want to exit?';
        MissingExchangeRatesQst: Label 'There are no exchange rates for currency %1 and date %2. Do you want to add them now? Otherwise, the last change you made will be reverted.', Comment = '%1 - currency code, %2 - posting date';
        FullServiceTypesTxt: Label 'Service Quote,Service Order,Service Invoice,Service Credit Memo';

    [Scope('OnPrem')]
    procedure AssistEdit(OldServHeader: Record "Service Header"): Boolean
    var
        ServHeader2: Record "Service Header";
    begin
        with ServHeader do begin
            Copy(Rec);
            ServSetup.Get();
            TestNoSeries;
            if NoSeriesMgt.SelectSeries(GetNoSeriesCode, OldServHeader."No. Series", "No. Series") then begin
                if ("Customer No." = '') and ("Contact No." = '') then
                    CheckCreditMaxBeforeInsert(false);

                NoSeriesMgt.SetSeries("No.");
                if ServHeader2.Get("Document Type", "No.") then
                    Error(Text051, LowerCase(Format("Document Type")), "No.");
                Rec := ServHeader;
                exit(true);
            end;
        end;
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20]; Type5: Integer; No5: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        ServiceContractHeader: Record "Service Contract Header";
        No: array[10] of Code[20];
        TableID: array[10] of Integer;
        ContractDimensionSetID: Integer;
        OldDimSetID: Integer;
    begin
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

        if "Contract No." <> '' then begin
            ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, "Contract No.");
            ContractDimensionSetID := ServiceContractHeader."Dimension Set ID";
        end;

        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup."Service Management",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", ContractDimensionSetID, DATABASE::"Service Contract Header");

        OnCreateDimOnBeforeUpdateLines(Rec, xRec, CurrFieldNo);

        if "Dimension Set ID" <> OldDimSetID then begin
            DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            if ServItemLineExists or ServLineExists then begin
                Modify;
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
            end;
        end;
    end;

    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        NewDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAllLineDim(Rec, NewParentDimSetID, OldParentDimSetID, IsHandled);
        if IsHandled then
            exit;

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not (HideValidationDialog or ConfirmManagement.GetResponseOrDefault(Text061, true)) then
            exit;

        ServLine.Reset();
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "No.");
        ServLine.LockTable();
        if ServLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(ServLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if ServLine."Dimension Set ID" <> NewDimSetID then begin
                    ServLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ServLine."Dimension Set ID", ServLine."Shortcut Dimension 1 Code", ServLine."Shortcut Dimension 2 Code");
                    ServLine.Modify();
                end;
            until ServLine.Next = 0;

        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        ServItemLine.LockTable();
        if ServItemLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(ServItemLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if ServItemLine."Dimension Set ID" <> NewDimSetID then begin
                    ServItemLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ServItemLine."Dimension Set ID", ServItemLine."Shortcut Dimension 1 Code", ServItemLine."Shortcut Dimension 2 Code");
                    ServItemLine.Modify();
                end;
            until ServItemLine.Next = 0;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        if ServItemLineExists or ServLineExists then
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    local procedure UpdateCurrencyFactor()
    var
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if "Currency Code" <> '' then begin
            CurrencyDate := "Posting Date";
            if UpdateCurrencyExchangeRates.ExchangeRatesForCurrencyExist(CurrencyDate, "Currency Code") then begin
                "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
                if "Currency Code" <> xRec."Currency Code" then
                    RecreateServLines(FieldCaption("Currency Code"));
            end else begin
                if ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(MissingExchangeRatesQst, "Currency Code", CurrencyDate), true)
                then begin
                    UpdateCurrencyExchangeRates.OpenExchangeRatesPage("Currency Code");
                    UpdateCurrencyFactor;
                end else
                    RevertCurrencyCodeAndPostingDate;
            end;
        end else begin
            "Currency Factor" := 0;
            if "Currency Code" <> xRec."Currency Code" then
                RecreateServLines(FieldCaption("Currency Code"));
        end;
    end;

    procedure RecreateServLines(ChangedFieldName: Text[100])
    var
        TempServLine: Record "Service Line" temporary;
        ServDocReg: Record "Service Document Register";
        TempServDocReg: Record "Service Document Register" temporary;
        TempServiceCommentLine: Record "Service Comment Line" temporary;
        ConfirmManagement: Codeunit "Confirm Management";
        ExtendedTextAdded: Boolean;
        IsHandled: Boolean;
    begin
        if ServLineExists() then begin
            if HideValidationDialog then
                Confirmed := true
            else
                Confirmed :=
                  ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text012, ChangedFieldName), true);

            if Confirmed then begin
                ServLine.LockTable();
                ReservEntry.LockTable();
                Modify();

                IsHandled := false;
                OnRecreateServLinesOnBeforeUpdateLines(Rec, IsHandled);
                if IsHandled then
                    exit;

                ServLine.Reset();
                ServLine.SetRange("Document Type", "Document Type");
                ServLine.SetRange("Document No.", "No.");
                if ServLine.Find('-') then begin
                    repeat
                        ServLine.TestField("Quantity Shipped", 0);
                        ServLine.TestField("Quantity Invoiced", 0);
                        ServLine.TestField("Shipment No.", '');
                        TempServLine := ServLine;
                        if ServLine.Nonstock then begin
                            ServLine.Nonstock := false;
                            ServLine.Modify();
                        end;
                        TempServLine.Insert();
                        CopyReservEntryToTemp(ServLine);
                    until ServLine.Next() = 0;

                    if "Location Code" <> xRec."Location Code" then
                        if not TempReservEntry.IsEmpty then
                            Error(Text047, FieldCaption("Location Code"));

                    if "Document Type" = "Document Type"::Invoice then begin
                        ServDocReg.SetCurrentKey("Destination Document Type", "Destination Document No.");
                        ServDocReg.SetRange("Destination Document Type", ServDocReg."Destination Document Type"::Invoice);
                        ServDocReg.SetRange("Destination Document No.", TempServLine."Document No.");
                        if ServDocReg.Find('-') then
                            repeat
                                TempServDocReg := ServDocReg;
                                TempServDocReg.Insert();
                            until ServDocReg.Next() = 0;
                    end;
                    StoreServiceCommentLineToTemp(TempServiceCommentLine);
                    ServLine.DeleteAll(true);

                    if "Document Type" = "Document Type"::Invoice then begin
                        if TempServDocReg.Find('-') then
                            repeat
                                ServDocReg := TempServDocReg;
                                ServDocReg.Insert();
                            until TempServDocReg.Next() = 0;
                    end;

                    CreateServiceLines(TempServLine, ExtendedTextAdded);
                    RestoreServiceCommentLineFromTemp(TempServiceCommentLine);
                    TempServLine.SetRange(Type);
                    TempServLine.DeleteAll();
                end;
            end else
                Error('');
        end;
    end;

    local procedure StoreServiceCommentLineToTemp(var TempServiceCommentLine: Record "Service Comment Line" temporary)
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Header");
        ServiceCommentLine.SetRange("Table Subtype", "Document Type");
        ServiceCommentLine.SetRange("No.", "No.");
        if ServiceCommentLine.FindSet() then
            repeat
                TempServiceCommentLine := ServiceCommentLine;
                TempServiceCommentLine.Insert();
            until ServiceCommentLine.Next() = 0;
    end;

    local procedure RestoreServiceCommentLineFromTemp(var TempServiceCommentLine: Record "Service Comment Line" temporary)
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        TempServiceCommentLine.SetRange("Table Name", TempServiceCommentLine."Table Name"::"Service Header");
        TempServiceCommentLine.SetRange("Table Subtype", "Document Type");
        TempServiceCommentLine.SetRange("No.", "No.");
        if TempServiceCommentLine.FindSet() then
            repeat
                ServiceCommentLine := TempServiceCommentLine;
                ServiceCommentLine.Insert();
            until TempServiceCommentLine.Next() = 0;
    end;

    local procedure ConfirmUpdateCurrencyFactor()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ConfirmManagement.GetResponseOrDefault(Text015, true) then
            Validate("Currency Factor")
        else
            "Currency Factor" := xRec."Currency Factor";
    end;

    local procedure UpdateServLinesByFieldNo(ChangedFieldNo: Integer; AskQuestion: Boolean)
    var
        "Field": Record "Field";
        ConfirmManagement: Codeunit "Confirm Management";
        Question: Text[250];
    begin
        Field.Get(DATABASE::"Service Header", ChangedFieldNo);

        if ServLineExists and AskQuestion then begin
            Question := StrSubstNo(
                Text016,
                Field."Field Caption");
            if not ConfirmManagement.GetResponseOrDefault(Question, true) then
                exit
        end;

        if ServLineExists then begin
            ServLine.LockTable();
            ServLine.Reset();
            ServLine.SetRange("Document Type", "Document Type");
            ServLine.SetRange("Document No.", "No.");

            ServLine.SetRange("Quantity Shipped", 0);
            ServLine.SetRange("Quantity Invoiced", 0);
            ServLine.SetRange("Quantity Consumed", 0);
            ServLine.SetRange("Shipment No.", '');

            if ServLine.Find('-') then
                repeat
                    case ChangedFieldNo of
                        FieldNo("Currency Factor"):
                            if (ServLine."Posting Date" = "Posting Date") and (ServLine.Type <> ServLine.Type::" ") then begin
                                ServLine.Validate("Unit Price");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Posting Date"):
                            begin
                                ServLine.Validate("Posting Date", "Posting Date");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Responsibility Center"):
                            begin
                                ServLine.Validate("Responsibility Center", "Responsibility Center");
                                ServLine.Modify(true);
                                ServItemLine.Reset();
                                ServItemLine.SetRange("Document Type", "Document Type");
                                ServItemLine.SetRange("Document No.", "No.");
                                if ServItemLine.Find('-') then
                                    repeat
                                        ServItemLine.Validate("Responsibility Center", "Responsibility Center");
                                        ServItemLine.Modify(true);
                                    until ServItemLine.Next = 0;
                            end;
                        FieldNo("Order Date"):
                            begin
                                ServLine."Order Date" := "Order Date";
                                ServLine.Modify(true);
                            end;
                        FieldNo("Transaction Type"):
                            begin
                                ServLine.Validate("Transaction Type", "Transaction Type");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Transport Method"):
                            begin
                                ServLine.Validate("Transport Method", "Transport Method");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Exit Point"):
                            begin
                                ServLine.Validate("Exit Point", "Exit Point");
                                ServLine.Modify(true);
                            end;
                        FieldNo(Area):
                            begin
                                ServLine.Validate(Area, Area);
                                ServLine.Modify(true);
                            end;
                        FieldNo("Transaction Specification"):
                            begin
                                ServLine.Validate("Transaction Specification", "Transaction Specification");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Shipping Agent Code"):
                            begin
                                ServLine.Validate("Shipping Agent Code", "Shipping Agent Code");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Shipping Time"):
                            begin
                                ServLine.Validate("Shipping Time", "Shipping Time");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Shipping Agent Service Code"):
                            begin
                                ServLine.Validate("Shipping Agent Service Code", "Shipping Agent Service Code");
                                ServLine.Modify(true);
                            end;
                        else
                            OnUpdateServLineByChangedFieldName(Rec, ServLine, Field."Field Caption");
                    end;
                until ServLine.Next = 0;
        end;
    end;

    procedure TestMandatoryFields(var PassedServLine: Record "Service Line")
    begin
        OnBeforeTestMandatoryFields(Rec, PassedServLine);

        ServSetup.Get();
        CheckMandSalesPersonOrderData(ServSetup);
        PassedServLine.Reset();
        ServLine.Reset();
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "No.");

        if PassedServLine.Find('-') then
            repeat
                if (PassedServLine."Qty. to Ship" <> 0) or
                   (PassedServLine."Qty. to Invoice" <> 0) or
                   (PassedServLine."Qty. to Consume" <> 0)
                then begin
                    if ("Document Type" = "Document Type"::Order) and
                       "Link Service to Service Item" and
                       (PassedServLine.Type in [PassedServLine.Type::Item, PassedServLine.Type::Resource])
                    then
                        PassedServLine.TestField("Service Item Line No.");

                    case PassedServLine.Type of
                        PassedServLine.Type::Item:
                            begin
                                if ServSetup."Unit of Measure Mandatory" then
                                    PassedServLine.TestField("Unit of Measure Code");
                            end;
                        PassedServLine.Type::Resource:
                            begin
                                if ServSetup."Work Type Code Mandatory" then
                                    PassedServLine.TestField("Work Type Code");
                                if ServSetup."Unit of Measure Mandatory" then
                                    PassedServLine.TestField("Unit of Measure Code");
                            end;
                        PassedServLine.Type::Cost:
                            if ServSetup."Unit of Measure Mandatory" then
                                PassedServLine.TestField("Unit of Measure Code");
                    end;

                    if PassedServLine."Job No." <> '' then
                        PassedServLine.TestField("Qty. to Consume", PassedServLine."Qty. to Ship");
                end;
            until PassedServLine.Next = 0
        else
            if ServLine.Find('-') then
                repeat
                    if (ServLine."Qty. to Ship" <> 0) or
                       (ServLine."Qty. to Invoice" <> 0) or
                       (ServLine."Qty. to Consume" <> 0)
                    then begin
                        if ("Document Type" = "Document Type"::Order) and
                           "Link Service to Service Item" and
                           (ServLine.Type in [ServLine.Type::Item, ServLine.Type::Resource])
                        then
                            ServLine.TestField("Service Item Line No.");

                        case ServLine.Type of
                            ServLine.Type::Item:
                                begin
                                    if ServSetup."Unit of Measure Mandatory" then
                                        ServLine.TestField("Unit of Measure Code");
                                end;
                            ServLine.Type::Resource:
                                begin
                                    if ServSetup."Work Type Code Mandatory" then
                                        ServLine.TestField("Work Type Code");
                                    if ServSetup."Unit of Measure Mandatory" then
                                        ServLine.TestField("Unit of Measure Code");
                                end;
                            ServLine.Type::Cost:
                                if ServSetup."Unit of Measure Mandatory" then
                                    ServLine.TestField("Unit of Measure Code");
                        end;

                        if ServLine."Job No." <> '' then
                            ServLine.TestField("Qty. to Consume", ServLine."Qty. to Ship");
                    end;
                until ServLine.Next = 0;
    end;

    procedure UpdateResponseDateTime()
    begin
        ServItemLine.Reset();
        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Response Date");
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        if ServItemLine.Find('-') then begin
            "Response Date" := ServItemLine."Response Date";
            "Response Time" := ServItemLine."Response Time";
            Modify(true);
        end;
    end;

    local procedure UpdateStartingDateTime()
    begin
        if ValidatingFromLines then
            exit;
        ServItemLine.Reset();
        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Starting Date");
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        ServItemLine.SetFilter("Starting Date", '<>%1', 0D);
        if ServItemLine.Find('-') then begin
            "Starting Date" := ServItemLine."Starting Date";
            "Starting Time" := ServItemLine."Starting Time";
            Modify(true);
        end else begin
            "Starting Date" := 0D;
            "Starting Time" := 0T;
        end;
    end;

    local procedure UpdateFinishingDateTime()
    begin
        if ValidatingFromLines then
            exit;
        ServItemLine.Reset();
        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Finishing Date");
        ServItemLine.Ascending := false;
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        ServItemLine.SetFilter("Finishing Date", '<>%1', 0D);
        if ServItemLine.Find('-') then begin
            "Finishing Date" := ServItemLine."Finishing Date";
            "Finishing Time" := ServItemLine."Finishing Time";
            Modify(true);
        end else begin
            "Finishing Date" := 0D;
            "Finishing Time" := 0T;
        end;
    end;

    local procedure PriceMsgIfServLinesExist(ChangedFieldName: Text[100])
    begin
        if ServLineExists then
            Message(
              Text019,
              ChangedFieldName);
    end;

    procedure ServItemLineExists(): Boolean
    var
        ServItemLine: Record "Service Item Line";
    begin
        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        exit(not ServItemLine.IsEmpty);
    end;

    procedure ServLineExists(): Boolean
    begin
        ServLine.Reset();
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "No.");
        exit(not ServLine.IsEmpty);
    end;

    local procedure MessageIfServLinesExist(ChangedFieldName: Text[100])
    begin
        if ServLineExists and not HideValidationDialog then
            Message(
              Text021,
              ChangedFieldName, TableCaption);
    end;

    local procedure ValidateServPriceGrOnServItem()
    begin
        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        if ServItemLine.Find('-') then begin
            ServItemLine.SetServHeader(Rec);
            repeat
                if ServItemLine."Service Price Group Code" <> '' then begin
                    ServItemLine.Validate("Service Price Group Code");
                    ServItemLine.Modify();
                end;
            until ServItemLine.Next = 0
        end;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure SetValidatingFromLines(NewValidatingFromLines: Boolean)
    begin
        ValidatingFromLines := NewValidatingFromLines;
    end;

    local procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Document Type" of
            "Document Type"::Quote:
                ServSetup.TestField("Service Quote Nos.");
            "Document Type"::Order:
                ServSetup.TestField("Service Order Nos.");
        end;
    end;

    local procedure GetNoSeriesCode(): Code[20]
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNoSeries(Rec, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        case "Document Type" of
            "Document Type"::Quote:
                exit(ServSetup."Service Quote Nos.");
            "Document Type"::Order:
                exit(ServSetup."Service Order Nos.");
            "Document Type"::Invoice:
                exit(ServSetup."Service Invoice Nos.");
            "Document Type"::"Credit Memo":
                exit(ServSetup."Service Credit Memo Nos.");
        end;
    end;

    local procedure TestNoSeriesManual()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestNoSeriesManual(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Document Type" of
            "Document Type"::Quote:
                NoSeriesMgt.TestManual(ServSetup."Service Quote Nos.");
            "Document Type"::Order:
                NoSeriesMgt.TestManual(ServSetup."Service Order Nos.");
            "Document Type"::Invoice:
                NoSeriesMgt.TestManual(ServSetup."Service Invoice Nos.");
            "Document Type"::"Credit Memo":
                NoSeriesMgt.TestManual(ServSetup."Service Credit Memo Nos.");
        end;
    end;

    local procedure UpdateCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
        Cust: Record Customer;
    begin
        if Cust.Get(CustomerNo) then begin
            Clear(ServOrderMgt);
            ContactNo := ServOrderMgt.FindContactInformation(Cust."No.");
            if Cont.Get(ContactNo) then begin
                "Contact No." := Cont."No.";
                "Contact Name" := Cont.Name;
                "Phone No." := Cont."Phone No.";
                "E-Mail" := Cont."E-Mail";
            end else begin
                if Cust."Primary Contact No." <> '' then
                    "Contact No." := Cust."Primary Contact No."
                else
                    if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, "Customer No.") then
                        "Contact No." := ContBusRel."Contact No."
                    else
                        "Contact No." := '';
                "Contact Name" := Cust.Contact;
            end;
        end;
    end;

    local procedure UpdateBillToCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
        Cust: Record Customer;
    begin
        if Cust.Get(CustomerNo) then begin
            Clear(ServOrderMgt);
            ContactNo := ServOrderMgt.FindContactInformation("Bill-to Customer No.");
            if Cont.Get(ContactNo) then begin
                "Bill-to Contact No." := Cont."No.";
                "Bill-to Contact" := Cont.Name;
            end else begin
                if Cust."Primary Contact No." <> '' then
                    "Bill-to Contact No." := Cust."Primary Contact No."
                else
                    if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, "Bill-to Customer No.") then
                        "Bill-to Contact No." := ContBusRel."Contact No."
                    else
                        "Bill-to Contact No." := '';
                "Bill-to Contact" := Cust.Contact;
            end;
        end;
    end;

    local procedure UpdateCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Cust: Record Customer;
        Cont: Record Contact;
    begin
        if Cont.Get(ContactNo) then begin
            "Contact No." := Cont."No.";
            "Phone No." := Cont."Phone No.";
            "E-Mail" := Cont."E-Mail";
        end else begin
            "Phone No." := '';
            "E-Mail" := '';
            "Contact Name" := '';
            exit;
        end;

        if Cont.Type = Cont.Type::Person then
            "Contact Name" := Cont.Name
        else
            if Cust.Get("Customer No.") then
                "Contact Name" := Cust.Contact
            else
                "Contact Name" := '';

        if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.") then begin
            if ("Customer No." <> '') and
               ("Customer No." <> ContBusinessRelation."No.")
            then
                Error(Text037, Cont."No.", Cont.Name, "Customer No.");

            if "Customer No." = '' then begin
                SkipContact := true;
                Validate("Customer No.", ContBusinessRelation."No.");
                SkipContact := false;
            end;
        end else
            Error(Text039, Cont."No.", Cont.Name);

        if ("Customer No." = "Bill-to Customer No.") or
           ("Bill-to Customer No." = '')
        then
            Validate("Bill-to Contact No.", "Contact No.");

        OnAfterUpdateCust(Rec);
    end;

    local procedure UpdateBillToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Cust: Record Customer;
        Cont: Record Contact;
    begin
        if Cont.Get(ContactNo) then begin
            "Bill-to Contact No." := Cont."No.";
            if Cont.Type = Cont.Type::Person then
                "Bill-to Contact" := Cont.Name
            else
                if Cust.Get("Bill-to Customer No.") then
                    "Bill-to Contact" := Cust.Contact
                else
                    "Bill-to Contact" := '';
        end else begin
            "Bill-to Contact" := '';
            exit;
        end;

        if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.") then begin
            if "Bill-to Customer No." = '' then begin
                SkipBillToContact := true;
                Validate("Bill-to Customer No.", ContBusinessRelation."No.");
                SkipBillToContact := false;
            end else
                if "Bill-to Customer No." <> ContBusinessRelation."No." then
                    Error(Text037, Cont."No.", Cont.Name, "Bill-to Customer No.");
        end else
            Error(Text039, Cont."No.", Cont.Name);
    end;

    [Scope('OnPrem')]
    procedure CheckCreditMaxBeforeInsert(HideCreditCheckDialogue: Boolean)
    var
        ServHeader: Record "Service Header";
        ContBusinessRelation: Record "Contact Business Relation";
        Cont: Record Contact;
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        if HideCreditCheckDialogue then
            exit;
        if GetFilter("Customer No.") <> '' then begin
            if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then begin
                ServHeader."Bill-to Customer No." := GetRangeMin("Customer No.");
                CustCheckCreditLimit.ServiceHeaderCheck(ServHeader);
            end
        end else
            if GetFilter("Contact No.") <> '' then
                if GetRangeMin("Contact No.") = GetRangeMax("Contact No.") then begin
                    Cont.Get(GetRangeMin("Contact No."));
                    if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.") then begin
                        ServHeader."Bill-to Customer No." := ContBusinessRelation."No.";
                        CustCheckCreditLimit.ServiceHeaderCheck(ServHeader);
                    end;
                end;
    end;

    procedure UpdateServiceOrderChangeLog(var OldServHeader: Record "Service Header")
    begin
        if Status <> OldServHeader.Status then
            ServLogMgt.ServHeaderStatusChange(Rec, OldServHeader);

        if "Customer No." <> OldServHeader."Customer No." then
            ServLogMgt.ServHeaderCustomerChange(Rec, OldServHeader);

        if "Ship-to Code" <> OldServHeader."Ship-to Code" then
            ServLogMgt.ServHeaderShiptoChange(Rec, OldServHeader);

        if "Contract No." <> OldServHeader."Contract No." then
            ServLogMgt.ServHeaderContractNoChanged(Rec, OldServHeader);
    end;

    local procedure GetPostingNoSeriesCode() PostingNos: Code[20]
    var
        IsHandled: Boolean;
    begin
        ServSetup.Get();
        IsHandled := false;
        OnBeforeGetPostingNoSeriesCode(Rec, ServSetup, PostingNos, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" in ["Document Type"::"Credit Memo"] then
            PostingNos := ServSetup."Posted Serv. Credit Memo Nos."
        else
            PostingNos := ServSetup."Posted Service Invoice Nos.";

        OnAfterGetPostingNoSeriesCode(Rec, PostingNos);
    end;

    procedure InitRecord()
    begin
        case "Document Type" of
            "Document Type"::Quote, "Document Type"::Order:
                begin
                    NoSeriesMgt.SetDefaultSeries("Posting No. Series", ServSetup."Posted Service Invoice Nos.");
                    NoSeriesMgt.SetDefaultSeries("Shipping No. Series", ServSetup."Posted Service Shipment Nos.");
                end;
            "Document Type"::Invoice:
                begin
                    if ("No. Series" <> '') and
                       (ServSetup."Service Invoice Nos." = ServSetup."Posted Service Invoice Nos.")
                    then
                        "Posting No. Series" := "No. Series"
                    else
                        NoSeriesMgt.SetDefaultSeries("Posting No. Series", ServSetup."Posted Service Invoice Nos.");
                    if ServSetup."Shipment on Invoice" then
                        NoSeriesMgt.SetDefaultSeries("Shipping No. Series", ServSetup."Posted Service Shipment Nos.");
                end;
            "Document Type"::"Credit Memo":
                begin
                    if ("No. Series" <> '') and
                       (ServSetup."Service Credit Memo Nos." = ServSetup."Posted Serv. Credit Memo Nos.")
                    then
                        "Posting No. Series" := "No. Series"
                    else
                        NoSeriesMgt.SetDefaultSeries("Posting No. Series", ServSetup."Posted Serv. Credit Memo Nos.");
                end;
        end;

        if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice, "Document Type"::Quote]
        then begin
            "Order Date" := WorkDate;
            "Order Time" := Time;
        end;

        "Posting Date" := WorkDate;
        "Document Date" := WorkDate;
        "Default Response Time (Hours)" := ServSetup."Default Response Time (Hours)";
        "Link Service to Service Item" := ServSetup."Link Service to Service Item";

        if Cust.Get("Customer No.") then
            Validate("Location Code", UserSetupMgt.GetLocation(2, Cust."Location Code", "Responsibility Center"));

        if "Document Type" in ["Document Type"::"Credit Memo"] then begin
            GLSetup.Get();
            Correction := GLSetup."Mark Cr. Memos as Corrections";
        end;

        "Posting Description" := Format("Document Type") + ' ' + "No.";

        Reserve := Reserve::Optional;

        if Cust.Get("Customer No.") then
            if Cust."Responsibility Center" <> '' then
                "Responsibility Center" := UserSetupMgt.GetRespCenter(2, Cust."Responsibility Center")
            else
                "Responsibility Center" := UserSetupMgt.GetRespCenter(2, "Responsibility Center")
        else
            "Responsibility Center" := UserSetupMgt.GetServiceFilter;

        OnAfterInitRecord(Rec);
    end;

    local procedure InitRecordFromContact()
    begin
        Init;
        ServSetup.Get();
        InitRecord;
        "No. Series" := xRec."No. Series";
        if xRec."Shipping No." <> '' then begin
            "Shipping No. Series" := xRec."Shipping No. Series";
            "Shipping No." := xRec."Shipping No.";
        end;
        if xRec."Posting No." <> '' then begin
            "Posting No. Series" := xRec."Posting No. Series";
            "Posting No." := xRec."Posting No.";
        end;
    end;

    local procedure GetCust(CustNo: Code[20])
    begin
        if not (("Document Type" = "Document Type"::Quote) and (CustNo = '')) then begin
            if CustNo <> Cust."No." then
                Cust.Get(CustNo);
        end else
            Clear(Cust);
    end;

    local procedure ShippedServLinesExist(): Boolean
    begin
        ServLine.Reset();
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "No.");
        ServLine.SetFilter("Quantity Shipped", '<>0');
        exit(ServLine.Find('-'));
    end;

    local procedure UpdateShipToAddress()
    var
        Location: Record Location;
        CompanyInfo: Record "Company Information";
    begin
        if "Document Type" = "Document Type"::"Credit Memo" then begin
            if "Location Code" <> '' then begin
                Location.Get("Location Code");
                SetShipToAddress(
                  Location.Name, Location."Name 2", Location.Address, Location."Address 2",
                  Location.City, Location."Post Code", Location.County, Location."Country/Region Code");
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
            "VAT Country/Region Code" := "Country/Region Code";
        end;

        OnAfterUpdateShipToAddress(Rec);
    end;

    procedure SetShipToAddress(ShipToName: Text[100]; ShipToName2: Text[50]; ShipToAddress: Text[100]; ShipToAddress2: Text[50]; ShipToCity: Text[30]; ShipToPostCode: Code[20]; ShipToCounty: Text[30]; ShipToCountryRegionCode: Code[10])
    begin
        "Ship-to Name" := ShipToName;
        "Ship-to Name 2" := ShipToName2;
        "Ship-to Address" := ShipToAddress;
        "Ship-to Address 2" := ShipToAddress2;
        Validate("Ship-to Country/Region Code", ShipToCountryRegionCode);
        "Ship-to City" := ShipToCity;
        "Ship-to Post Code" := ShipToPostCode;
        "Ship-to County" := ShipToCounty;
    end;

    procedure ConfirmDeletion(): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ServPost.TestDeleteHeader(Rec, ServShptHeader, ServInvHeader, ServCrMemoHeader);
        if ServShptHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text053, ServShptHeader."No."), true)
            then
                exit;
        if ServInvHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text054, ServInvHeader."No."), true)
            then
                exit;
        if ServCrMemoHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text013, ServCrMemoHeader."No."), true)
            then
                exit;
        exit(true);
    end;

    local procedure CopyReservEntryToTemp(OldServLine: Record "Service Line")
    begin
        ReservEntry.Reset();
        ReservEntry.SetSourceFilter(
          DATABASE::"Service Line", OldServLine."Document Type", OldServLine."Document No.", OldServLine."Line No.", false);
        if ReservEntry.FindSet then
            repeat
                TempReservEntry := ReservEntry;
                TempReservEntry.Insert();
            until ReservEntry.Next = 0;
        ReservEntry.DeleteAll();
    end;

    local procedure CopyReservEntryFromTemp(OldServLine: Record "Service Line"; NewSourceRefNo: Integer)
    begin
        TempReservEntry.Reset();
        TempReservEntry.SetSourceFilter(
          DATABASE::"Service Line", OldServLine."Document Type", OldServLine."Document No.", OldServLine."Line No.", false);
        if TempReservEntry.FindSet then
            repeat
                ReservEntry := TempReservEntry;
                ReservEntry."Source Ref. No." := NewSourceRefNo;
                if not ReservEntry.Insert() then;
            until TempReservEntry.Next = 0;
        TempReservEntry.DeleteAll();
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if ServItemLineExists or ServLineExists then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure LookupAdjmtValueEntries(QtyType: Option General,Invoicing)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ServiceLine: Record "Service Line";
        ServiceShptLine: Record "Service Shipment Line";
        TempValueEntry: Record "Value Entry" temporary;
    begin
        ServiceLine.SetRange("Document Type", "Document Type");
        ServiceLine.SetRange("Document No.", "No.");
        TempValueEntry.Reset();
        TempValueEntry.DeleteAll();

        case "Document Type" of
            "Document Type"::Order, "Document Type"::Invoice:
                begin
                    if ServiceLine.FindSet then
                        repeat
                            if (ServiceLine.Type = ServiceLine.Type::Item) and (ServiceLine.Quantity <> 0) then
                                if ServiceLine."Shipment No." <> '' then begin
                                    ServiceShptLine.SetRange("Document No.", ServiceLine."Shipment No.");
                                    ServiceShptLine.SetRange("Line No.", ServiceLine."Shipment Line No.");
                                end else begin
                                    ServiceShptLine.SetCurrentKey("Order No.", "Order Line No.");
                                    ServiceShptLine.SetRange("Order No.", ServiceLine."Document No.");
                                    ServiceShptLine.SetRange("Order Line No.", ServiceLine."Line No.");
                                end;
                            ServiceShptLine.SetRange(Correction, false);
                            if QtyType = QtyType::Invoicing then
                                ServiceShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');

                            if ServiceShptLine.FindSet then
                                repeat
                                    ServiceShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                                    if ItemLedgEntry.FindSet then
                                        repeat
                                            CreateTempAdjmtValueEntries(TempValueEntry, ItemLedgEntry."Entry No.");
                                        until ItemLedgEntry.Next = 0;
                                until ServiceShptLine.Next = 0;
                        until ServiceLine.Next = 0;
                end;
        end;
        PAGE.RunModal(0, TempValueEntry);
    end;

    local procedure CreateTempAdjmtValueEntries(var TempValueEntry: Record "Value Entry" temporary; ItemLedgEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        if ValueEntry.FindSet then
            repeat
                if ValueEntry.Adjustment then begin
                    TempValueEntry := ValueEntry;
                    if TempValueEntry.Insert() then;
                end;
            until ValueEntry.Next = 0;
    end;

    procedure CalcInvDiscForHeader()
    var
        ServiceInvDisc: Codeunit "Service-Calc. Discount";
    begin
        ServiceInvDisc.CalculateIncDiscForHeader(Rec);
    end;

    procedure SetSecurityFilterOnRespCenter()
    begin
        if UserSetupMgt.GetServiceFilter <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetServiceFilter);
            FilterGroup(0);
        end;

        SetRange("Date Filter", 0D, WorkDate - 1);
    end;

    local procedure CheckMandSalesPersonOrderData(ServiceMgtSetup: Record "Service Mgt. Setup")
    begin
        if ServiceMgtSetup."Salesperson Mandatory" then
            TestField("Salesperson Code");

        if "Document Type" = "Document Type"::Order then begin
            if ServiceMgtSetup."Service Order Type Mandatory" and ("Service Order Type" = '') then
                Error(Text018,
                  FieldCaption("Service Order Type"), TableCaption,
                  FieldCaption("Document Type"), Format("Document Type"),
                  FieldCaption("No."), Format("No."));
            if ServiceMgtSetup."Service Order Start Mandatory" then begin
                TestField("Starting Date");
                TestField("Starting Time");
            end;
            if ServiceMgtSetup."Service Order Finish Mandatory" then begin
                TestField("Finishing Date");
                TestField("Finishing Time");
            end;
            if ServiceMgtSetup."Fault Reason Code Mandatory" and not ValidatingFromLines then begin
                ServItemLine.Reset();
                ServItemLine.SetRange("Document Type", "Document Type");
                ServItemLine.SetRange("Document No.", "No.");
                if ServItemLine.Find('-') then
                    repeat
                        ServItemLine.TestField("Fault Reason Code");
                    until ServItemLine.Next = 0;
            end;
        end;
    end;

    procedure InventoryPickConflict(DocType: Option Quote,"Order",Invoice,"Credit Memo"; DocNo: Code[20]; ShippingAdvice: Option Partial,Complete): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ServiceLine: Record "Service Line";
    begin
        if ShippingAdvice <> ShippingAdvice::Complete then
            exit(false);
        WarehouseActivityLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseActivityLine.SetRange("Source Subtype", DocType);
        WarehouseActivityLine.SetRange("Source No.", DocNo);
        if WarehouseActivityLine.IsEmpty then
            exit(false);
        ServiceLine.SetRange("Document Type", DocType);
        ServiceLine.SetRange("Document No.", DocNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        if ServiceLine.IsEmpty then
            exit(false);
        exit(true);
    end;

    procedure InvPickConflictResolutionTxt(): Text[500]
    begin
        exit(StrSubstNo(Text062, TableCaption, FieldCaption("Shipping Advice"), Format("Shipping Advice")));
    end;

    procedure WhseShpmntConflict(DocType: Option Quote,"Order",Invoice,"Credit Memo"; DocNo: Code[20]; ShippingAdvice: Option Partial,Complete): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if ShippingAdvice <> ShippingAdvice::Complete then
            exit(false);
        WarehouseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseShipmentLine.SetRange("Source Subtype", DocType);
        WarehouseShipmentLine.SetRange("Source No.", DocNo);
        if WarehouseShipmentLine.IsEmpty then
            exit(false);
        exit(true);
    end;

    procedure WhseShpmtConflictResolutionTxt(): Text[500]
    begin
        exit(StrSubstNo(Text063, TableCaption, FieldCaption("Shipping Advice"), Format("Shipping Advice")));
    end;

    local procedure GetShippingTime(CalledByFieldNo: Integer)
    var
        ShippingAgentServices: Record "Shipping Agent Services";
    begin
        if (CalledByFieldNo <> CurrFieldNo) and (CurrFieldNo <> 0) then
            exit;

        if ShippingAgentServices.Get("Shipping Agent Code", "Shipping Agent Service Code") then
            "Shipping Time" := ShippingAgentServices."Shipping Time"
        else begin
            GetCust("Customer No.");
            "Shipping Time" := Cust."Shipping Time"
        end;
        if not (CalledByFieldNo in [FieldNo("Shipping Agent Code"), FieldNo("Shipping Agent Service Code")]) then
            Validate("Shipping Time");
    end;

    local procedure CheckHeaderDimension()
    begin
        if ("Contract No." <> '') and ("Document Type" = "Document Type"::Invoice) then
            Error(Text066);
    end;

    local procedure CreateServiceLines(var TempServLine: Record "Service Line" temporary; var ExtendedTextAdded: Boolean)
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        ServLine.Init();
        ServLine."Line No." := 0;
        TempServLine.Find('-');
        ExtendedTextAdded := false;

        repeat
            if TempServLine."Attached to Line No." = 0 then begin
                ServLine.Init();
                ServLine.SetHideReplacementDialog(true);
                ServLine.SetHideCostWarning(true);
                ServLine."Line No." := ServLine."Line No." + 10000;
                ServLine."Price Calculation Method" := "Price Calculation Method";
                ServLine.Validate(Type, TempServLine.Type);
                if TempServLine."No." <> '' then begin
                    ServLine.Validate("No.", TempServLine."No.");
                    if ServLine.Type <> ServLine.Type::" " then begin
                        ServLine.Validate("Unit of Measure Code", TempServLine."Unit of Measure Code");
                        ServLine.Validate("Variant Code", TempServLine."Variant Code");
                        if TempServLine.Quantity <> 0 then
                            ServLine.Validate(Quantity, TempServLine.Quantity);
                    end;
                end;

                ServLine."Serv. Price Adjmt. Gr. Code" := TempServLine."Serv. Price Adjmt. Gr. Code";
                ServLine."Document No." := TempServLine."Document No.";
                ServLine."Service Item No." := TempServLine."Service Item No.";
                ServLine."Appl.-to Service Entry" := TempServLine."Appl.-to Service Entry";
                ServLine."Service Item Line No." := TempServLine."Service Item Line No.";
                ServLine.Validate(Description, TempServLine.Description);
                ServLine.Validate("Description 2", TempServLine."Description 2");

                if TempServLine."No." <> '' then begin
                    TempLinkToServItem := "Link Service to Service Item";
                    if "Link Service to Service Item" then begin
                        "Link Service to Service Item" := false;
                        Modify(true);
                    end;
                    ServLine."Spare Part Action" := TempServLine."Spare Part Action";
                    ServLine."Component Line No." := TempServLine."Component Line No.";
                    ServLine."Replaced Item No." := TempServLine."Replaced Item No.";
                    ServLine.Validate("Work Type Code", TempServLine."Work Type Code");

                    ServLine."Location Code" := TempServLine."Location Code";
                    if ServLine.Type <> ServLine.Type::" " then begin
                        if ServLine.Type = ServLine.Type::Item then begin
                            ServLine.Validate("Variant Code", TempServLine."Variant Code");
                            if ServLine."Location Code" <> '' then
                                ServLine."Bin Code" := TempServLine."Bin Code";
                        end;
                        ServLine."Fault Reason Code" := TempServLine."Fault Reason Code";
                        ServLine."Exclude Warranty" := TempServLine."Exclude Warranty";
                        ServLine."Exclude Contract Discount" := TempServLine."Exclude Contract Discount";
                        ServLine.Validate("Contract No.", TempServLine."Contract No.");
                        ServLine.Validate(Warranty, TempServLine.Warranty);
                    end;
                    ServLine."Fault Area Code" := TempServLine."Fault Area Code";
                    ServLine."Symptom Code" := TempServLine."Symptom Code";
                    ServLine."Resolution Code" := TempServLine."Resolution Code";
                    ServLine."Fault Code" := TempServLine."Fault Code";
                    ServLine.Validate("Dimension Set ID", TempServLine."Dimension Set ID");
                end;
                "Link Service to Service Item" := TempLinkToServItem;

                OnBeforeInsertServLineOnServLineRecreation(ServLine, TempServLine);
                ServLine.Insert();
                ExtendedTextAdded := false;
            end else
                if not ExtendedTextAdded then begin
                    TransferExtendedText.ServCheckIfAnyExtText(ServLine, true);
                    TransferExtendedText.InsertServExtText(ServLine);
                    OnAfterTransferExtendedTextForServLineRecreation(ServLine);
                    ServLine.Find('+');
                    ExtendedTextAdded := true;
                end;
            CopyReservEntryFromTemp(TempServLine, ServLine."Line No.");
        until TempServLine.Next = 0;
    end;

    procedure SetCustomerFromFilter()
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := GetFilterCustNo;
        if CustomerNo = '' then begin
            FilterGroup(2);
            CustomerNo := GetFilterCustNo;
            FilterGroup(0);
        end;
        if CustomerNo <> '' then
            Validate("Customer No.", CustomerNo);
    end;

    local procedure GetFilterCustNo(): Code[20]
    begin
        if GetFilter("Customer No.") <> '' then
            if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then
                exit(GetRangeMax("Customer No."));
    end;

    local procedure UpdateShipToAddressFromGeneralAddress(FieldNumber: Integer)
    begin
        if ("Ship-to Code" = '') and (not ShipToAddressModified) then
            case FieldNumber of
                FieldNo("Ship-to Address"):
                    if xRec.Address = "Ship-to Address" then
                        "Ship-to Address" := Address;
                FieldNo("Ship-to Address 2"):
                    if xRec."Address 2" = "Ship-to Address 2" then
                        "Ship-to Address 2" := "Address 2";
                FieldNo("Ship-to City"), FieldNo("Ship-to Post Code"):
                    begin
                        if xRec.City = "Ship-to City" then
                            "Ship-to City" := City;
                        if xRec."Post Code" = "Ship-to Post Code" then
                            "Ship-to Post Code" := "Post Code";
                        if xRec.County = "Ship-to County" then
                            "Ship-to County" := County;
                        if xRec."Country/Region Code" = "Ship-to Country/Region Code" then
                            "Ship-to Country/Region Code" := "Country/Region Code";
                    end;
                FieldNo("Ship-to County"):
                    if xRec.County = "Ship-to County" then
                        "Ship-to County" := County;
                FieldNo("Ship-to Country/Region Code"):
                    if xRec."Country/Region Code" = "Ship-to Country/Region Code" then
                        "Ship-to Country/Region Code" := "Country/Region Code";
            end;
    end;

    procedure CopyCustomerFilter()
    var
        CustomerFilter: Text;
    begin
        CustomerFilter := GetFilter("Customer No.");
        if CustomerFilter <> '' then begin
            FilterGroup(2);
            SetFilter("Customer No.", CustomerFilter);
            FilterGroup(0)
        end;
    end;

    local procedure CopyCustomerFields(Cust: Record Customer)
    begin
        Name := Cust.Name;
        "Name 2" := Cust."Name 2";
        Address := Cust.Address;
        "Address 2" := Cust."Address 2";
        City := Cust.City;
        "Post Code" := Cust."Post Code";
        County := Cust.County;
        "Country/Region Code" := Cust."Country/Region Code";
        if not SkipContact then begin
            "Contact Name" := Cust.Contact;
            "Phone No." := Cust."Phone No.";
            "E-Mail" := Cust."E-Mail";
        end;
        "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
        "Tax Area Code" := Cust."Tax Area Code";
        "Tax Liable" := Cust."Tax Liable";
        "VAT Registration No." := Cust."VAT Registration No.";
        "Shipping Advice" := Cust."Shipping Advice";
        "Responsibility Center" := UserSetupMgt.GetRespCenter(2, Cust."Responsibility Center");
        Validate("Location Code", UserSetupMgt.GetLocation(2, Cust."Location Code", "Responsibility Center"));

        OnAfterCopyCustomerFields(Rec, Cust);
    end;

    local procedure CopyBillToCustomerFields(Cust: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        "Bill-to Name" := Cust.Name;
        "Bill-to Name 2" := Cust."Name 2";
        "Bill-to Address" := Cust.Address;
        "Bill-to Address 2" := Cust."Address 2";
        "Bill-to City" := Cust.City;
        "Bill-to Post Code" := Cust."Post Code";
        "Bill-to County" := Cust.County;
        "Bill-to Country/Region Code" := Cust."Country/Region Code";
        if not SkipBillToContact then
            "Bill-to Contact" := Cust.Contact;
        "Payment Terms Code" := Cust."Payment Terms Code";
        if "Document Type" = "Document Type"::"Credit Memo" then begin
            "Payment Method Code" := '';
            if PaymentTerms.Get("Payment Terms Code") then
                if PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then
                    "Payment Method Code" := Cust."Payment Method Code"
        end else
            "Payment Method Code" := Cust."Payment Method Code";
        GLSetup.Get();
        if GLSetup."Bill-to/Sell-to VAT Calc." = GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." then begin
            "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
            "VAT Registration No." := Cust."VAT Registration No.";
            "VAT Country/Region Code" := Cust."Country/Region Code";
            "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
        end;
        "Customer Posting Group" := Cust."Customer Posting Group";
        "Currency Code" := Cust."Currency Code";
        "Customer Price Group" := Cust."Customer Price Group";
        "Prices Including VAT" := Cust."Prices Including VAT";
        "Price Calculation Method" := Cust.GetPriceCalculationMethod();
        "Allow Line Disc." := Cust."Allow Line Disc.";
        "Invoice Disc. Code" := Cust."Invoice Disc. Code";
        "Customer Disc. Group" := Cust."Customer Disc. Group";
        "Language Code" := Cust."Language Code";
        SetSalespersonCode(Cust."Salesperson Code", "Salesperson Code");
        Reserve := Cust.Reserve;

        OnAfterCopyBillToCustomerFields(Rec, Cust);
    end;

    local procedure ShipToAddressModified(): Boolean
    begin
        if (xRec.Address <> "Ship-to Address") or
           (xRec."Address 2" <> "Ship-to Address 2") or
           (xRec.City <> "Ship-to City") or
           (xRec.County <> "Ship-to County") or
           (xRec."Post Code" <> "Ship-to Post Code") or
           (xRec."Country/Region Code" <> "Ship-to Country/Region Code")
        then
            exit(true);
        exit(false);
    end;

    procedure ConfirmCloseUnposted(): Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if ServLineExists or ServItemLineExists then
            if InstructionMgt.IsUnpostedEnabledForRecord(Rec) then
                exit(InstructionMgt.ShowConfirm(DocumentNotPostedClosePageQst, InstructionMgt.QueryPostOnCloseCode));
        exit(true)
    end;

    local procedure ConfirmChangeContractNo(): Boolean
    var
        ServContractLine: Record "Service Contract Line";
        ConfirmManagement: Codeunit "Confirm Management";
        Confirmed: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmUpdateContractNo(Rec, Confirmed, HideValidationDialog, IsHandled);
        if IsHandled then
            exit(Confirmed);

        Confirmed :=
          ConfirmManagement.GetResponseOrDefault(
            StrSubstNo(
              Text029, ServContractLine.FieldCaption("Next Planned Service Date"),
              ServContractLine.TableCaption, FieldCaption("Contract No.")), true);

        exit(Confirmed);
    end;

    local procedure SetDefaultSalesperson()
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit;

        if UserSetup."Salespers./Purch. Code" <> '' then
            Validate("Salesperson Code", UserSetup."Salespers./Purch. Code");
    end;

    procedure ValidateSalesPersonOnServiceHeader(ServiceHeader2: Record "Service Header"; IsTransaction: Boolean; IsPostAction: Boolean)
    begin
        if ServiceHeader2."Salesperson Code" <> '' then
            if Salesperson.Get(ServiceHeader2."Salesperson Code") then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then begin
                    if IsTransaction then
                        Error(Salesperson.GetPrivacyBlockedTransactionText(Salesperson, IsPostAction, true));
                    if not IsTransaction then
                        Error(Salesperson.GetPrivacyBlockedGenericText(Salesperson, true));
                end;
    end;

    local procedure SetSalespersonCode(SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20])
    begin
        if SalesPersonCodeToCheck <> '' then
            if Salesperson.Get(SalesPersonCodeToCheck) then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then
                    SalesPersonCodeToAssign := ''
                else
                    SalesPersonCodeToAssign := SalesPersonCodeToCheck;
    end;

    local procedure RevertCurrencyCodeAndPostingDate()
    begin
        "Currency Code" := xRec."Currency Code";
        "Posting Date" := xRec."Posting Date";
        Modify;
    end;

    procedure GetFullDocTypeTxt() FullDocTypeTxt: Text
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetFullDocTypeTxt(Rec, FullDocTypeTxt, IsHandled);

        if IsHandled then
            exit;

        FullDocTypeTxt := SelectStr("Document Type" + 1, FullServiceTypesTxt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFullDocTypeTxt(var ServiceHeader: Record "Service Header"; var FullDocTypeTxt: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyBillToCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPostingNoSeriesCode(var ServiceHeader: Record "Service Header"; var PostingNos: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateShipToAddress(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateServLineByChangedFieldName(ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ChangedFieldName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var ServiceHeader: Record "Service Header"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCust(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferExtendedTextForServLineRecreation(var ServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlockedCustomer(Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmUpdateContractNo(var ServiceHeader: Record "Service Header"; var Confirmed: Boolean; var HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeries(var ServiceHeader: Record "Service Header"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostingNoSeriesCode(var ServiceHeader: Record "Service Header"; ServiceMgtSetup: Record "Service Mgt. Setup"; var PostingNos: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServLineOnServLineRecreation(var ServiceLine: Record "Service Line"; var TempServiceLine: Record "Service Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestMandatoryFields(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeriesManual(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ServiceHeader: Record "Service Header"; var xServiceHeader: Record "Service Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAllLineDim(var ServiceHeader: Record "Service Header"; NewParentDimSetID: Integer; OldParentDimSetID: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnBeforeUpdateLines(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateServLinesOnBeforeUpdateLines(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCustomerNoOnBeforeDeleteLines(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATBaseDiscountPctOnBeforeUpdateLineAmounts(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeValidateDueDate(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipToCodeOnBeforeDleereLines(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
}

