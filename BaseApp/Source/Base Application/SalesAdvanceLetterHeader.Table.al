table 31000 "Sales Advance Letter Header"
{
    Caption = 'Sales Advance Letter Header';
    DataCaptionFields = "No.", "Bill-to Name";
#if not CLEAN19
    DrillDownPageID = "Sales Adv. Letters";
    LookupPageID = "Sales Adv. Letters";
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '22.0';
#endif
    ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';

    fields
    {
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            TableRelation = Customer;
#if not CLEAN19

            trigger OnValidate()
            var
                FieldValueDictionary: Dictionary of [Text[30], Text];
                RegistrationNoFldTok: Label 'Registration No. CZL', Locked = true;
                TaxRegistrationNoFldTok: Label 'Tax Registration No. CZL', Locked = true;
            begin
                if "No." = '' then
                    InitRecord;
                TestField(Status, Status::Open);
                if xRec."Bill-to Customer No." <> "Bill-to Customer No." then begin
                    if not HideValidationDialog and GuiAllowed then
                        if "Bill-to Customer No." <> '' then begin
                            Cust.Get("Bill-to Customer No.");
                            if (Cust."Bill-to Customer No." <> '') and (Cust."Bill-to Customer No." <> Cust."No.") then
                                if Confirm(Text012Qst, true, "Bill-to Customer No.", Cust."Bill-to Customer No.") then
                                    "Bill-to Customer No." := Cust."Bill-to Customer No.";
                        end;
                    if LetterLinesExist then
                        Error(Text006Err, FieldCaption("Bill-to Customer No."));
                end;

                if (xRec."Bill-to Customer No." <> "Bill-to Customer No.") and
                   (xRec."Bill-to Customer No." <> '')
                then begin
                    if HideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(Text004Qst, false, FieldCaption("Bill-to Customer No."));
                    if not Confirmed then
                        "Bill-to Customer No." := xRec."Bill-to Customer No.";
                end;

                GetCust("Bill-to Customer No.");
                Cust.CheckBlockedCustOnDocs(Cust, 0, false, false);
                Cust.TestField("Customer Posting Group");

                "Bill-to Name" := Cust.Name;
                "Bill-to Name 2" := Cust."Name 2";
                "Bill-to Address" := Cust.Address;
                "Bill-to Address 2" := Cust."Address 2";
                "Bill-to City" := Cust.City;
                "Bill-to Post Code" := Cust."Post Code";
                "Bill-to County" := Cust.County;
                "Bill-to Country/Region Code" := Cust."Country/Region Code";
                "VAT Country/Region Code" := Cust."Country/Region Code";
                "Bill-to Contact" := Cust.Contact;

                "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
                "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
                "Customer Posting Group" := Cust."Customer Posting Group";

                "Salesperson Code" := Cust."Salesperson Code";
                "Responsibility Center" := UserSetupMgt.GetRespCenter(0, Cust."Responsibility Center");

                if "Template Code" <> '' then begin
                    SalesAdvPmtTemplate.Get("Template Code");
                    if SalesAdvPmtTemplate."Customer Posting Group" <> '' then
                        Validate("Customer Posting Group", SalesAdvPmtTemplate."Customer Posting Group");
                    "Post Advance VAT Option" := SalesAdvPmtTemplate."Post Advance VAT Option";
                    "Amounts Including VAT" := SalesAdvPmtTemplate."Amounts Including VAT";
                end;

                "Currency Code" := Cust."Currency Code";
                "Language Code" := Cust."Language Code";
                "Payment Terms Code" := Cust."Payment Terms Code";
                "Payment Method Code" := Cust."Payment Method Code";
                "VAT Registration No." := Cust."VAT Registration No.";
                FieldValueDictionary.Add(RegistrationNoFldTok, '');
                FieldValueDictionary.Add(TaxRegistrationNoFldTok, '');
                ExtensionFieldsManagement.GetRecordExtensionFields(Cust.RecordId, FieldValueDictionary);
                "Registration No." := CopyStr(FieldValueDictionary.Get(RegistrationNoFldTok), 1, MaxStrlen("Registration No."));
                "Tax Registration No." := CopyStr(FieldValueDictionary.Get(TaxRegistrationNoFldTok), 1, MaxStrlen("Registration No."));

                Validate("VAT Country/Region Code");
                CreateDim(
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center",
#if CLEAN18
                  DATABASE::"Customer Templ.", "Bill-to Customer Template Code");
#else
                  DATABASE::"Customer Template", "Bill-to Customer Template Code");
#endif

                Validate("Currency Code");
                Validate("Payment Terms Code");

                if (xRec."Bill-to Customer No." <> '') AND (xRec."Bill-to Customer No." <> "Bill-to Customer No.") then
                    RecallModifyAddressNotification(GetModifyBillToCustomerAddressNotificationId);
            end;
#endif
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;
#if not CLEAN19

            trigger OnValidate()
            var
                Customer: Record Customer;
                id: Codeunit "Identity Management";
            begin
                if ShouldLookForCustomerByName("Bill-to Customer No.") then
                    Validate("Bill-to Customer No.", Customer.GetCustNo("Bill-to Name"));
            end;
#endif
        }
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
        }
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
#if not CLEAN19

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress();
            end;
#endif
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
#if not CLEAN19

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress();
            end;
#endif
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
#if not CLEAN19

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                ModifyBillToCustomerAddress();
            end;
#endif
        }
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
#if not CLEAN19

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress();
            end;
#endif
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
#if not CLEAN19

            trigger OnValidate()
            begin
                SalesSetup.Get();
                if SalesSetup."Default VAT Date" = SalesSetup."Default VAT Date"::"Posting Date" then
                    Validate("VAT Date", "Posting Date");
            end;
#endif
        }
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
#if not CLEAN19

            trigger OnValidate()
            begin
                if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                    PaymentTerms.Get("Payment Terms Code");
                    "Advance Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                end else
                    Validate("Advance Due Date", "Document Date");
            end;
#endif
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
#if not CLEAN19

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
#endif
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
#if not CLEAN19

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
#endif
        }
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            Editable = false;
            TableRelation = "Customer Posting Group";
#if not CLEAN18

            trigger OnValidate()
            var
                PostingGroupManagement: Codeunit "Posting Group Management";
            begin
                if CurrFieldNo = FieldNo("Customer Posting Group") then
                    PostingGroupManagement.CheckPostingGroupChange("Customer Posting Group", xRec."Customer Posting Group", Rec);
            end;
#endif
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
#if not CLEAN19

            trigger OnValidate()
            begin
                case true of
                    CurrFieldNo <> FieldNo("Currency Code"):
                        UpdateCurrencyFactor;
                    "Currency Code" <> xRec."Currency Code":
                        begin
                            if LetterLinesExist then
                                Error(Text006Err, FieldCaption("Currency Code"));
                            UpdateCurrencyFactor;
                            RecreateLines(FieldCaption("Currency Code"));
                        end;
                    "Currency Code" <> '':
                        begin
                            UpdateCurrencyFactor;
                            if "Currency Factor" <> xRec."Currency Factor" then
                                ConfirmUpdateCurrencyFactor;
                        end;
                end;
            end;
#endif
        }
        field(33; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
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
#if not CLEAN19

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center",
#if CLEAN18
                  DATABASE::"Customer Templ.", "Bill-to Customer Template Code");
#else
                  DATABASE::"Customer Template", "Bill-to Customer Template Code");
#endif
            end;
#endif
        }
        field(44; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            TableRelation = "Sales Header"."No." WHERE("Document Type" = CONST(Order));
        }
        field(46; Comment; Boolean)
        {
#if not CLEAN19
            CalcFormula = Exist("Sales Comment Line" WHERE("Document Type" = CONST("Advance Letter"),
                                                            "No." = FIELD("No."),
                                                            "Document Line No." = CONST(0)));
#endif
            Caption = 'Comment';
            Editable = false;
#if not CLEAN19
            FieldClass = FlowField;
#endif
        }
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
#if not CLEAN19

            trigger OnValidate()
            begin
                CalcFields(Status);
                if Status = Status::Open then
                    Release;
            end;
#endif
        }
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            CalcFormula = Sum("Sales Advance Letter Line"."Amount Including VAT" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
#if not CLEAN19

            trigger OnValidate()
            var
                Customer: Record Customer;
                VATRegistrationLog: Record "VAT Registration Log";
                VATRegistrationNoFormat: Record "VAT Registration No. Format";
                VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                ResultRecRef: RecordRef;
                ApplicableCountryCode: Code[10];
            begin
                "VAT Registration No." := UpperCase("VAT Registration No.");
                if "VAT Registration No." = xRec."VAT Registration No." then
                    exit;

                if not Customer.Get("Bill-to Customer No.") then
                    exit;

                if "VAT Registration No." = Customer."VAT Registration No." then
                    exit;

                if not VATRegistrationNoFormat.Test("VAT Registration No.", Customer."Country/Region Code", Customer."No.", Database::Customer) then
                    exit;

                Customer."VAT Registration No." := "VAT Registration No.";
                ApplicableCountryCode := Customer."Country/Region Code";
                if ApplicableCountryCode = '' then
                    ApplicableCountryCode := VATRegistrationNoFormat."Country/Region Code";

                VATRegistrationLogMgt.CheckVIESForVATNo(ResultRecRef, VATRegistrationLog, Customer, Customer."No.",
                ApplicableCountryCode, VATRegistrationLog."Account Type"::Customer);

                if VATRegistrationLog.Status = VATRegistrationLog.Status::Valid then begin
                    Message(ValidVATNoMsg);
                    Customer.Modify(true);
                end else
                    Message(InvalidVatRegNoMsg);
            end;
#endif
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
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";
#if not CLEAN19

            trigger OnValidate()
            var
                NewVATRegNo: Text[20];
                OldCustNo: Code[20];
            begin
                if "Bill-to Customer No." <> '' then begin
                    OldCustNo := Cust."No.";
                    GetCust("Bill-to Customer No.");
                    NewVATRegNo := Cust."VAT Registration No.";
                    if OldCustNo <> '' then
                        GetCust(OldCustNo)
                    else
                        Clear(Cust);
                end;
                "VAT Registration No." := NewVATRegNo;
            end;
#endif
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;
#if not CLEAN19

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                ModifyBillToCustomerAddress();
            end;
#endif
        }
        field(86; "Bill-to County"; Text[30])
        {
            Caption = 'Bill-to County';
            CaptionClass = '5,1,' + "Bill-to Country/Region Code";
#if not CLEAN19

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress();
            end;
#endif
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            TableRelation = "Country/Region";
#if not CLEAN19

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress();
            end;
#endif
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
#if not CLEAN19

            trigger OnValidate()
            begin
                Validate("Payment Terms Code");

                SalesSetup.Get();
                if SalesSetup."Default VAT Date" = SalesSetup."Default VAT Date"::"Document Date" then
                    Validate("VAT Date", "Document Date");
            end;
#endif
        }
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
#if not CLEAN19

            trigger OnValidate()
            begin
                if xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group" then
                    RecreateLines(FieldCaption("VAT Bus. Posting Group"));
            end;
#endif
        }
        field(120; Status; Option)
        {
            CalcFormula = Min("Sales Advance Letter Line".Status WHERE("Letter No." = FIELD("No."),
                                                                        "Amount Including VAT" = FILTER(<> 0)));
            Caption = 'Status';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Open,Pending Payment,Pending Invoice,Pending Final Invoice,Closed,Pending Approval';
            OptionMembers = Open,"Pending Payment","Pending Invoice","Pending Final Invoice",Closed,"Pending Approval";
        }
        field(133; "Advance Due Date"; Date)
        {
            Caption = 'Advance Due Date';
#if not CLEAN19

            trigger OnValidate()
            var
                SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
            begin
                if "Advance Due Date" <> xRec."Advance Due Date" then begin
                    SalesAdvanceLetterLine.SetRange("Letter No.", "No.");
                    SalesAdvanceLetterLine.ModifyAll("Advance Due Date", "Advance Due Date");
                end;
            end;
#endif
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";
#if not CLEAN19

            trigger OnValidate()
            var
                IncomingDocument: Record "Incoming Document";
            begin
                if "Incoming Document Entry No." = xRec."Incoming Document Entry No." then
                    exit;
                if "Incoming Document Entry No." = 0 then
                    IncomingDocument.RemoveReferenceToWorkingDocument(xRec."Incoming Document Entry No.")
                else
                    IncomingDocument.SetSalesAdvLetterDoc(Rec);
            end;
#endif
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
#if not CLEAN19

            trigger OnLookup()
            begin
                ShowDocDim;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
#endif
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
#if not CLEAN19

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::"Responsibility Center", "Responsibility Center",
#if CLEAN18
                  DATABASE::"Customer Templ.", "Bill-to Customer Template Code");
#else
                  DATABASE::"Customer Template", "Bill-to Customer Template Code");
#endif
            end;
#endif
        }
        field(5054; "Bill-to Customer Template Code"; Code[10])
        {
            Caption = 'Bill-to Customer Template Code';
#if CLEAN18
            TableRelation = "Customer Templ.";
#else
            TableRelation = "Customer Template";
#endif
#if not CLEAN19

            trigger OnValidate()
            begin
                CreateDim(
#if CLEAN18
                  DATABASE::"Customer Templ.", "Bill-to Customer Template Code",
#else
                  DATABASE::"Customer Template", "Bill-to Customer Template Code",
#endif
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center");
            end;
#endif
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
#if not CLEAN19

            trigger OnValidate()
            begin
                if not UserSetupMgt.CheckRespCenter(0, "Responsibility Center") then
                    Error(
                      RespCenterErr,
                      RespCenter.TableCaption, UserSetupMgt.GetSalesFilter);

#if CLEAN18
                GetBankInfoFromRespCenter();
#else
                if RespCenter.Get("Responsibility Center") then begin
                    "Bank Account Code" := RespCenter."Bank Account Code";
                    "Bank Account No." := RespCenter."Bank Account No.";
                    "Bank Branch No." := RespCenter."Bank Branch No.";
                    "Bank Name" := RespCenter."Bank Name";
                    "Transit No." := RespCenter."Transit No.";
                    IBAN := RespCenter.IBAN;
                    "SWIFT Code" := RespCenter."SWIFT Code";
                end;
#endif

                CreateDim(
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::Customer, "Bill-to Customer No.",
                  DATABASE::"Salesperson/Purchaser", "Salesperson Code",
                  DATABASE::Campaign, "Campaign No.",
#if CLEAN18
                  DATABASE::"Customer Templ.", "Bill-to Customer Template Code");
#else
                  DATABASE::"Customer Template", "Bill-to Customer Template Code");
#endif
            end;
#endif
        }
        field(11700; "Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
            TableRelation = "Bank Account";
#if not CLEAN19

            trigger OnValidate()
            var
                BankAcc: Record "Bank Account";
            begin
                if "Bank Account Code" = '' then begin
                    "Bank Account No." := '';
                    "Bank Branch No." := '';
                    "Bank Name" := '';
                    "Specific Symbol" := '';
                    "Transit No." := '';
                    IBAN := '';
                    "SWIFT Code" := '';
                    exit;
                end;

                TestField("Bill-to Customer No.");
                BankAcc.Get("Bank Account Code");
                "Bank Account No." := BankAcc."Bank Account No.";
                "Bank Branch No." := BankAcc."Bank Branch No.";
                "Bank Name" := BankAcc.Name;
#if not CLEAN18
                "Specific Symbol" := BankAcc."Specific Symbol";
#endif
                "Transit No." := BankAcc."Transit No.";
                IBAN := BankAcc.IBAN;
                "SWIFT Code" := BankAcc."SWIFT Code";
            end;
#endif
        }
        field(11701; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
            Editable = false;
        }
        field(11702; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';
        }
        field(11703; "Specific Symbol"; Code[10])
        {
            Caption = 'Specific Symbol';
            CharAllowed = '09';
        }
        field(11704; "Variable Symbol"; Code[10])
        {
            Caption = 'Variable Symbol';
            CharAllowed = '09';
        }
        field(11705; "Constant Symbol"; Code[10])
        {
            Caption = 'Constant Symbol';
            CharAllowed = '09';
#if not CLEAN18
            TableRelation = "Constant Symbol";
#endif
        }
        field(11706; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
            Editable = false;
        }
        field(11707; IBAN; Code[50])
        {
            Caption = 'IBAN';
            Editable = false;
#if not CLEAN19

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
#endif
        }
        field(11708; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            Editable = false;
        }
        field(11709; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
        }
        field(11760; "VAT Date"; Date)
        {
            Caption = 'VAT Date';
#if not CLEAN19

            trigger OnValidate()
            begin
                GLSetup.Get();
                if not GLSetup."Use VAT Date" then
                    TestField("VAT Date", "Posting Date");
            end;
#endif
        }
        field(11790; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
        }
        field(11791; "Tax Registration No."; Text[20])
        {
            Caption = 'Tax Registration No.';
        }
        field(31008; Closed; Boolean)
        {
            Caption = 'Closed';
            Editable = false;
        }
        field(31009; "Semifinished Linked Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Semifinished Linked Amount';
        }
        field(31010; "Amounts Including VAT"; Boolean)
        {
            Caption = 'Amounts Including VAT';
#if not CLEAN19

            trigger OnValidate()
            begin
                if "Amounts Including VAT" <> xRec."Amounts Including VAT" then begin
                    CalcFields(Status);
                    TestField(Status, Status::Open);
                    if LetterLinesExist then
                        Error(Text006Err, FieldCaption("Amounts Including VAT"));
                end;
            end;
#endif
        }
        field(31012; "Template Code"; Code[10])
        {
            Caption = 'Template Code';
            Editable = false;
#if not CLEAN19
            TableRelation = "Sales Adv. Payment Template";
#endif
        }
        field(31013; "Amount To Link"; Decimal)
        {
            CalcFormula = Sum("Sales Advance Letter Line"."Amount To Link" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount To Link';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31014; "Amount To Invoice"; Decimal)
        {
            CalcFormula = Sum("Sales Advance Letter Line"."Amount To Invoice" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount To Invoice';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31015; "Amount To Deduct"; Decimal)
        {
            CalcFormula = Sum("Sales Advance Letter Line"."Amount To Deduct" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount To Deduct';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31016; "Document Linked Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Advance Letter Line Relation".Amount WHERE(Type = CONST(Sale),
                                                                           "Letter No." = FIELD("No."),
                                                                           "Document No." = FIELD("Doc. No. Filter")));
            Caption = 'Document Linked Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31017; "Doc. No. Filter"; Code[20])
        {
            Caption = 'Doc. No. Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Header"."No.";
        }
        field(31018; "Document Linked Inv. Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Advance Letter Line Relation"."Invoiced Amount" WHERE(Type = CONST(Sale),
                                                                                      "Letter No." = FIELD("No."),
                                                                                      "Document No." = FIELD("Doc. No. Filter")));
            Caption = 'Document Linked Inv. Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31019; "Document Linked Ded. Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Advance Letter Line Relation"."Deducted Amount" WHERE(Type = CONST(Sale),
                                                                                      "Letter No." = FIELD("No."),
                                                                                      "Document No." = FIELD("Doc. No. Filter")));
            Caption = 'Document Linked Ded. Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31020; "Amount Linked"; Decimal)
        {
            CalcFormula = Sum("Sales Advance Letter Line"."Amount Linked" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount Linked';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31021; "Amount Invoiced"; Decimal)
        {
            CalcFormula = Sum("Sales Advance Letter Line"."Amount Invoiced" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31022; "Amount Deducted"; Decimal)
        {
            CalcFormula = Sum("Sales Advance Letter Line"."Amount Deducted" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount Deducted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31025; "Post Advance VAT Option"; Option)
        {
            Caption = 'Post Advance VAT Option';
            InitValue = Always;
            OptionCaption = ' ,Never,Optional,Always';
            OptionMembers = " ",Never,Optional,Always;
        }
        field(31060; "Perform. Country/Region Code"; Code[10])
        {
            Caption = 'Perform. Country/Region Code';
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of VAT Registration in Other Countries hase been removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31061; "Perf. Country Currency Factor"; Decimal)
        {
            Caption = 'Perf. Country Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of VAT Registration in Other Countries hase been removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Template Code")
        {
        }
        key(Key3; "Bill-to Customer No.", "Currency Code", Closed)
        {
        }
        key(Key4; "Order No.")
        {
        }
    }

    fieldgroups
    {
    }
#if not CLEAN19

    trigger OnDelete()
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        SalesHeader: Record "Sales Header";
        SalesAdvanceLetterHeader2: Record "Sales Advance Letter Header";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if not UserSetupMgt.CheckRespCenter(0, "Responsibility Center") then
            Error(
              RespCenterDeleteErr,
              RespCenter.TableCaption, UserSetupMgt.GetSalesFilter);

        Validate("Incoming Document Entry No.", 0);

        if "Order No." <> '' then begin
            SalesAdvanceLetterHeader2.SetRange("Order No.", "Order No.");
            SalesAdvanceLetterHeader2.SetFilter("No.", '<>%1', "No.");
            if SalesAdvanceLetterHeader2.IsEmpty() then begin
                if SalesHeader.Get(SalesHeader."Document Type"::Order, "Order No.") then
                    ReleaseSalesDoc.Reopen(SalesHeader)
                else
                    if SalesHeader.Get(SalesHeader."Document Type"::Invoice, "Order No.") then
                        ReleaseSalesDoc.Reopen(SalesHeader);
            end;
        end;

        AdvanceLetterLineRelation.Reset();
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
        AdvanceLetterLineRelation.SetRange("Letter No.", "No.");
        if AdvanceLetterLineRelation.FindSet(true, false) then begin
            repeat
                AdvanceLetterLineRelation.CancelRelation(AdvanceLetterLineRelation, true, false, true);
            until AdvanceLetterLineRelation.Next() = 0;
        end;

        DeleteLetterLines;

        SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::"Advance Letter");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.DeleteAll();

        ApprovalsMgmt.DeleteApprovalEntryForRecord(Rec);
    end;

    trigger OnInsert()
    begin
        SalesSetup.Get();
        if "Template Code" <> '' then
            SalesAdvPmtTemplate.Get("Template Code");
        if "Document Date" = 0D then
            "Document Date" := WorkDate;

        if "No." = '' then
            if "Template Code" <> '' then begin
                SalesAdvPmtTemplate.TestField("Advance Letter Nos.");
                NoSeriesMgt.InitSeries(SalesAdvPmtTemplate."Advance Letter Nos.", xRec."No. Series", "Document Date", "No.", "No. Series");
                "Post Advance VAT Option" := SalesAdvPmtTemplate."Post Advance VAT Option";
                "Amounts Including VAT" := SalesAdvPmtTemplate."Amounts Including VAT";
            end else begin
                SalesSetup.TestField("Advance Letter Nos.");
                NoSeriesMgt.InitSeries(SalesSetup."Advance Letter Nos.", xRec."No. Series", "Document Date", "No.", "No. Series");
            end;

        InitRecord;

        if GetFilter("Bill-to Customer No.") <> '' then
            if GetRangeMin("Bill-to Customer No.") = GetRangeMax("Bill-to Customer No.") then
                Validate("Bill-to Customer No.", GetRangeMin("Bill-to Customer No."));
    end;

    trigger OnRename()
    begin
        Error(Text003Err, TableCaption);
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        SalesAdvanceLetterHeader: Record "Sales Advance Letter Header";
        Cust: Record Customer;
        CurrExchRate: Record "Currency Exchange Rate";
        SalesCommentLine: Record "Sales Comment Line";
        SalesAdvPmtTemplate: Record "Sales Adv. Payment Template";
        PaymentTerms: Record "Payment Terms";
        RespCenter: Record "Responsibility Center";
        CompanyInfo: Record "Company Information";
        SalesAdvanceLetterLinegre: Record "Sales Advance Letter Line";
        PostCode: Record "Post Code";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        UserSetupMgt: Codeunit "User Setup Management";
        ExtensionFieldsManagement: Codeunit "Extension Fields Management";
        HideValidationDialog: Boolean;
        Confirmed: Boolean;
        CurrencyDate: Date;
        Text001Err: Label 'Sales Advance Letter %1 already exists.';
        Text004Qst: Label 'Do you want to change %1?';
        Text003Err: Label 'You cannot rename a %1.';
        Text005Err: Label 'You cannot delete this document. There are posted Advance Invoices.';
        Text006Err: Label 'You must delete the existing lines before you can change %1.';
        Text009Qst: Label 'If you change %1, the existing advance lines will be deleted and new advance lines based on the new information on the header will be created. Do you want to change it?';
        Text010Err: Label 'You must delete the existing sales lines before you can change %1.';
        Text011Qst: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        Text012Qst: Label 'Customer No. %1 has set Bill-to Customer No. %2. To use Bill-to Customer No.?';
        Text013Qst: Label 'Do you want to update the exchange rate?';
        ApprovalProcessReleaseErr: Label 'This document can only be released when the approval process is complete.';
        ApprovalProcessReopenErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        LetterTxt: Label 'Letter';
        PositiveAmountErr: Label 'must be positive';
        RespCenterErr: Label 'Your identification is set up to process from %1 %2 only.', Comment = '%1 = fieldcaption of Responsibility Center; %2 = Responsibility Center';
        RespCenterDeleteErr: Label 'You cannot delete this document. Your identification is set up to process from %1 %2 only.', Comment = '%1 = fieldcaption of Responsibility Center; %2 = Responsibility Center';
        ModifyCustomerAddressNotificationLbl: Label 'Update the address';
        ModifyCustomerAddressNotificationMsg: Label 'The address you entered for %1 is different from the customer''s existing address.', Comment = '%1 = customer name';
        DontShowAgainActionLbl: Label 'Don''t show again';
        ValidVATNoMsg: Label 'The specified VAT registration number is valid.';
        InvalidVatRegNoMsg: Label 'The VAT registration number is not valid. Try entering the number again.';

    [Scope('OnPrem')]
    procedure AssistEdit(SalesAdvanceLetterHeaderOld: Record "Sales Advance Letter Header"): Boolean
    var
        SalesAdvanceLetterHeader2: Record "Sales Advance Letter Header";
    begin
        with SalesAdvanceLetterHeader do begin
            Copy(Rec);
            if "Template Code" <> '' then begin
                SalesAdvPmtTemplate.Get("Template Code");
                SalesAdvPmtTemplate.TestField("Advance Letter Nos.");
                if NoSeriesMgt.SelectSeries(SalesAdvPmtTemplate."Advance Letter Nos.", SalesAdvanceLetterHeaderOld."No. Series", "No. Series") then begin
                    NoSeriesMgt.SetSeries("No.");
                    if SalesAdvanceLetterHeader2.Get("No.") then
                        Error(Text001Err, "No.");
                    "Post Advance VAT Option" := SalesAdvPmtTemplate."Post Advance VAT Option";
                    "Amounts Including VAT" := SalesAdvPmtTemplate."Amounts Including VAT";
                    Rec := SalesAdvanceLetterHeader;
                    exit(true);
                end;
            end else begin
                SalesSetup.Get();
                SalesSetup.TestField("Advance Letter Nos.");
                if NoSeriesMgt.SelectSeries(SalesSetup."Advance Letter Nos.", SalesAdvanceLetterHeaderOld."No. Series", "No. Series") then begin
                    NoSeriesMgt.SetSeries("No.");
                    if SalesAdvanceLetterHeader2.Get("No.") then
                        Error(Text001Err, "No.");
                    Rec := SalesAdvanceLetterHeader;
                    exit(true);
                end;
            end;
        end;
    end;

    local procedure GetCust(CustNo: Code[20])
    begin
        if CustNo <> Cust."No." then
            Cust.Get(CustNo);
    end;

    [Scope('OnPrem')]
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify;

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if LetterLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1', "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if LetterLinesExist then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        NewDimSetID: Integer;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not Confirm(Text011Qst) then
            exit;

        SalesAdvanceLetterLinegre.Reset();
        SalesAdvanceLetterLinegre.SetRange("Letter No.", "No.");
        SalesAdvanceLetterLinegre.LockTable();
        if SalesAdvanceLetterLinegre.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(SalesAdvanceLetterLinegre."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if SalesAdvanceLetterLinegre."Dimension Set ID" <> NewDimSetID then begin
                    SalesAdvanceLetterLinegre."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      SalesAdvanceLetterLinegre."Dimension Set ID", SalesAdvanceLetterLinegre."Shortcut Dimension 1 Code",
                      SalesAdvanceLetterLinegre."Shortcut Dimension 2 Code");
                    SalesAdvanceLetterLinegre.Modify();
                end;
            until SalesAdvanceLetterLinegre.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InitRecord()
    begin
        if "Document Date" = 0D then
            "Document Date" := WorkDate;
        SalesSetup.Get();
        if "Posting Date" = 0D then
            "Posting Date" := WorkDate;
        if SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" then
            "Posting Date" := 0D;
        "Posting Description" := TableCaption + ' ' + "No.";

        case SalesSetup."Default VAT Date" of
            SalesSetup."Default VAT Date"::"Posting Date":
                "VAT Date" := "Posting Date";
            SalesSetup."Default VAT Date"::"Document Date":
                "VAT Date" := "Document Date";
            SalesSetup."Default VAT Date"::Blank:
                "VAT Date" := 0D;
        end;
        "Responsibility Center" := UserSetupMgt.GetRespCenter(0, "Responsibility Center");

        UpdateBankInfo;
        OnAfterInitRecord(Rec);
    end;

    [Scope('OnPrem')]
    procedure ConfirmDeletion(): Boolean
    begin
        exit(true);
    end;

    local procedure DeleteLetterLines()
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        SalesAdvanceLetterLine.SetRange("Letter No.", "No.");
        if SalesAdvanceLetterLine.FindSet(true) then begin
            repeat
                SalesAdvanceLetterLine.TestField("Amount Linked", 0);
                if SalesAdvanceLetterLine."Amount Invoiced" <> 0 then
                    Error(Text005Err);

                SalesAdvanceLetterLine.Delete(true);
            until SalesAdvanceLetterLine.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20]; Type5: Integer; No5: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
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
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';

        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
              Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Sales,
              "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        if (OldDimSetID <> "Dimension Set ID") and LetterLinesExist then begin
            Modify;
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    [Scope('OnPrem')]
    procedure LetterLinesExist(): Boolean
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        SalesAdvanceLetterLine.Reset();
        SalesAdvanceLetterLine.SetRange("Letter No.", "No.");
        exit(SalesAdvanceLetterLine.FindFirst);
    end;

    [Scope('OnPrem')]
    procedure ShowLinkedAdvances()
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        SalesPostAdvances: Codeunit "Sales-Post Advances";
        LinkedPrepayments: Page "Linked Prepayments";
    begin
        SalesAdvanceLetterLine.Reset();
        SalesAdvanceLetterLine.SetRange("Letter No.", "No.");
        if SalesAdvanceLetterLine.FindSet() then
            repeat
                SalesPostAdvances.CalcLinkedAmount(SalesAdvanceLetterLine, TempCustLedgEntry);
            until SalesAdvanceLetterLine.Next() = 0;
        LinkedPrepayments.InsertCustEntries(TempCustLedgEntry);
        LinkedPrepayments.RunModal();
    end;

    [Scope('OnPrem')]
    procedure Release()
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        BankAccount: Record "Bank Account";
        VATPostingSetup: Record "VAT Posting Setup";
        BankOperationsFunctions: Codeunit "Bank Operations Functions";
    begin
        OnBeforeReleaseSalesAdvanceLetter(Rec);
        OnCheckSalesAdvanceLetterReleaseRestrictions;

        if ("Variable Symbol" = '') and (not BankAccount.IsEmpty) then begin
            "Variable Symbol" := BankOperationsFunctions.CreateVariableSymbol("No.");
            Modify;
        end;

        TestField("Post Advance VAT Option");
        SalesAdvanceLetterLine.RecalcVATOnLines(Rec);

        SalesAdvanceLetterLine.SetRange("Letter No.", "No.");
        SalesAdvanceLetterLine.SetFilter(Status, '%1|%2',
          SalesAdvanceLetterLine.Status::Open,
          SalesAdvanceLetterLine.Status::"Pending Approval");
        if SalesAdvanceLetterLine.FindSet() then
            repeat
                if SalesAdvanceLetterLine."Amount Including VAT" < 0 then
                    SalesAdvanceLetterLine.FieldError("Amount Including VAT", PositiveAmountErr);
                if SalesAdvanceLetterLine.Amount > 0 then
                    VATPostingSetup.Get(SalesAdvanceLetterLine."VAT Bus. Posting Group", SalesAdvanceLetterLine."VAT Prod. Posting Group");
                SalesAdvanceLetterLine."Amount To Link" := SalesAdvanceLetterLine."Amount Including VAT";
                SalesAdvanceLetterLine.SuspendStatusCheck(true);
                SalesAdvanceLetterLine.Modify(true);
            until SalesAdvanceLetterLine.Next() = 0;

        OnAfterReleaseSalesAdvanceLetter(Rec);
    end;

    [Scope('OnPrem')]
    procedure Reopen()
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        OnBeforeReopenSalesAdvanceLetter(Rec);

        SalesAdvanceLetterLine.SetRange("Letter No.", "No.");
        SalesAdvanceLetterLine.SetFilter(Status, '%1|%2',
          SalesAdvanceLetterLine.Status::"Pending Advance Payment",
          SalesAdvanceLetterLine.Status::"Pending Approval");
        if SalesAdvanceLetterLine.FindSet() then
            repeat
                if (SalesAdvanceLetterLine."Amount To Link" = SalesAdvanceLetterLine."Amount Including VAT") or
                   (SalesAdvanceLetterLine.Status = SalesAdvanceLetterLine.Status::"Pending Approval")
                then begin
                    SalesAdvanceLetterLine."Amount To Link" := 0;
                    SalesAdvanceLetterLine.SuspendStatusCheck(true);
                    SalesAdvanceLetterLine.Modify(true);
                end;
            until SalesAdvanceLetterLine.Next() = 0;

        OnAfterReopenSalesAdvanceLetter(Rec);
    end;

    [Scope('OnPrem')]
    procedure PerformManualRelease()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsSalesAdvanceLetterApprovalsWorkflowEnabled(Rec) and
           (Status = Status::Open)
        then
            Error(ApprovalProcessReleaseErr);

        Release;
    end;

    [Scope('OnPrem')]
    procedure PerformManualReopen()
    begin
        if Status = Status::"Pending Approval" then
            Error(ApprovalProcessReopenErr);

        Reopen;
    end;

    [Scope('OnPrem')]
    procedure CheckDeductedAmount()
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        SalesAdvanceLetterLine.SetRange("Letter No.", "No.");
        SalesAdvanceLetterLine.SetFilter("Amount Deducted", '<>%1', 0);
        if SalesAdvanceLetterLine.FindFirst() then
            SalesAdvanceLetterLine.TestField("Amount Deducted", 0);
    end;

    [Scope('OnPrem')]
    procedure CheckAmountToInvoice()
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        SalesAdvanceLetterLine.SetRange("Letter No.", "No.");
        SalesAdvanceLetterLine.CalcSums("Amount To Invoice");
        if SalesAdvanceLetterLine."Amount To Invoice" = 0 then begin
            SalesAdvanceLetterLine.SetRange("Amount To Invoice", 0);
            SalesAdvanceLetterLine.FindFirst();
            SalesAdvanceLetterLine.TestField("Amount To Invoice");
        end;
    end;

    procedure GetRemAmount() RemAmount: Decimal
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        SalesAdvanceLetterLine.SetRange("Letter No.", "No.");
        if SalesAdvanceLetterLine.FindSet(false, false) then begin
            repeat
                RemAmount += SalesAdvanceLetterLine."Amount To Link";
            until SalesAdvanceLetterLine.Next() = 0;
        end;
    end;

    procedure GetRemAmountLCY(): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        Date: Date;
    begin
        Date := "Document Date";
        if Date = 0D then
            Date := WorkDate;

        CalcFields("Amount To Link");
        exit(Round(CurrExchRate.ExchangeAmtFCYToLCY(Date,
              "Currency Code", "Amount To Link", "Currency Factor")));
    end;

    [Scope('OnPrem')]
    procedure UpdateClosing(ToModify: Boolean)
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
        IsClosed: Boolean;
    begin
        SalesAdvanceLetterLine.SetRange("Letter No.", "No.");
        SalesAdvanceLetterLine.SetFilter("No.", '<>''''');
        SalesAdvanceLetterLine.SetFilter(Status, '<>%1', SalesAdvanceLetterLine.Status::Closed);
        IsClosed := not SalesAdvanceLetterLine.FindFirst();
        if IsClosed <> Closed then begin
            Closed := IsClosed;
            if ToModify then
                Modify;
        end;
    end;

    procedure UpdateCurrencyFactor()
    begin
        if "Currency Code" <> '' then begin
            CurrencyDate := "Posting Date";
            if CurrencyDate = 0D then
                CurrencyDate := WorkDate;
            "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
        end else
            "Currency Factor" := 0;
    end;

    local procedure ConfirmUpdateCurrencyFactor()
    begin
        if Confirm(Text013Qst, false) then
            Validate("Currency Factor")
        else
            "Currency Factor" := xRec."Currency Factor";
    end;

    [Scope('OnPrem')]
    procedure ShowDocs()
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        SalesHeader: Record "Sales Header";
    begin
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
        AdvanceLetterLineRelation.SetRange("Letter No.", "No.");

        if AdvanceLetterLineRelation.FindSet(false, false) then begin
            repeat
                if SalesHeader.Get(AdvanceLetterLineRelation."Document Type", AdvanceLetterLineRelation."Document No.") then
                    SalesHeader.Mark(true);
            until AdvanceLetterLineRelation.Next() = 0;
        end;

        SalesHeader.MarkedOnly(true);
        PAGE.Run(0, SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure PrintRecord(ShowDialog: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        with SalesAdvanceLetterHeader do begin
            Copy(Rec);
            ReportSelections.PrintWithDialogForCust(
              ReportSelections.Usage::"S.Adv.Let", SalesAdvanceLetterHeader, ShowDialog, FieldNo("Bill-to Customer No."));
        end;
    end;

    [Scope('OnPrem')]
    procedure EmailRecords(ShowDialog: Boolean)
    var
        ReportSelections: Record "Report Selections";
        DocName: Text[10];
    begin
        DocName := LetterTxt;
        ReportSelections.SendEmailToCust(
          ReportSelections.Usage::"S.Adv.Let", Rec, "No.", DocName, ShowDialog, "Bill-to Customer No.");
    end;

    local procedure RecreateLines(ChangedFieldName: Text[100])
    var
        TempSalesAdvanceLetterLine: Record "Sales Advance Letter Line" temporary;
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        if LetterLinesExist then begin
            if HideValidationDialog or not GuiAllowed then
                Confirmed := true
            else
                Confirmed :=
                  Confirm(
                    Text009Qst, false, ChangedFieldName);
            if Confirmed then begin
                SalesAdvanceLetterLinegre.LockTable();
                xRecRef.GetTable(xRec);
                Modify;
                RecRef.GetTable(Rec);

                SalesAdvanceLetterLinegre.Reset();
                SalesAdvanceLetterLinegre.SetRange("Letter No.", "No.");
                if SalesAdvanceLetterLinegre.FindSet() then
                    repeat
                        SalesAdvanceLetterLinegre.TestField(Status, SalesAdvanceLetterLinegre.Status::Open);

                        TempSalesAdvanceLetterLine := SalesAdvanceLetterLinegre;
                        TempSalesAdvanceLetterLine.Insert();
                    until SalesAdvanceLetterLinegre.Next() = 0;

                SalesAdvanceLetterLinegre.DeleteAll(true);
                SalesAdvanceLetterLinegre.Init();
                SalesAdvanceLetterLinegre."Line No." := 0;
                TempSalesAdvanceLetterLine.FindSet();

                repeat
                    SalesAdvanceLetterLinegre.Init();
                    SalesAdvanceLetterLinegre."Line No." := SalesAdvanceLetterLinegre."Line No." + 10000;
                    SalesAdvanceLetterLinegre.Validate("VAT Prod. Posting Group", TempSalesAdvanceLetterLine."VAT Prod. Posting Group");
                    SalesAdvanceLetterLinegre.Validate("Job No.", TempSalesAdvanceLetterLine."Job No.");
                    if "Amounts Including VAT" then
                        SalesAdvanceLetterLinegre.Validate("Amount Including VAT", TempSalesAdvanceLetterLine."Amount Including VAT")
                    else
                        SalesAdvanceLetterLinegre.Validate(Amount, TempSalesAdvanceLetterLine.Amount);
                    SalesAdvanceLetterLinegre.Insert(true);
                until TempSalesAdvanceLetterLine.Next() = 0;
            end else
                Error(
                  Text010Err, ChangedFieldName);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateBankInfo()
    begin
#if CLEAN18
        if GetBankInfoFromRespCenter() then begin
#else
        if RespCenter.Get("Responsibility Center") then begin
            "Bank Account Code" := RespCenter."Bank Account Code";
            "Bank Account No." := RespCenter."Bank Account No.";
            "Bank Branch No." := RespCenter."Bank Branch No.";
            "Bank Name" := RespCenter."Bank Name";
            "Transit No." := RespCenter."Transit No.";
            IBAN := RespCenter.IBAN;
            "SWIFT Code" := RespCenter."SWIFT Code";
#endif
        end else begin
            CompanyInfo.Get();
            "Bank Account Code" := CompanyInfo."Default Bank Account Code";
            "Bank Account No." := CompanyInfo."Bank Account No.";
            "Bank Branch No." := CompanyInfo."Bank Branch No.";
            "Bank Name" := CompanyInfo."Bank Name";
            IBAN := CompanyInfo.IBAN;
            "SWIFT Code" := CompanyInfo."SWIFT Code";
        end;
    end;

#if CLEAN18
    local procedure GetBankInfoFromRespCenter(): Boolean
    var
        BankAcc: Record "Bank Account";
        FieldValueDictionary: Dictionary of [Text[30], Text];
        DefaultBankAccountCodeFldTok: Label 'Default Bank Account Code CZL', Locked = true;
        DefaultBankAccountCode: Code[20];
    begin
        if not RespCenter.Get("Responsibility Center") then
            exit(false);
        FieldValueDictionary.Add(DefaultBankAccountCodeFldTok, '');
        ExtensionFieldsManagement.GetRecordExtensionFields(Cust.RecordId, FieldValueDictionary);
        DefaultBankAccountCode := CopyStr(FieldValueDictionary.Get(DefaultBankAccountCodeFldTok), 1, MaxStrlen(DefaultBankAccountCode));
        if DefaultBankAccountCode = '' then
            exit(false);
        if not BankAcc.Get(DefaultBankAccountCode) then
            exit(false);
        "Bank Account Code" := BankAcc."No.";
        "Bank Account No." := BankAcc."Bank Account No.";
        "Bank Branch No." := BankAcc."Bank Branch No.";
        "Bank Name" := BankAcc.Name;
        "Transit No." := BankAcc."Transit No.";
        IBAN := BankAcc.IBAN;
        "SWIFT Code" := BankAcc."SWIFT Code";
        exit(true);
    end;

#endif
    [Scope('OnPrem')]
    procedure CancelAllRelations()
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        AdvanceLetterLineRelation.SetCurrentKey(Type, "Letter No.");
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Sale);
        AdvanceLetterLineRelation.SetRange("Letter No.", "No.");
        if AdvanceLetterLineRelation.FindSet() then
            repeat
                AdvanceLetterLineRelation.CancelRelation(AdvanceLetterLineRelation, true, true, true);
            until AdvanceLetterLineRelation.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure SetStatus(NewStatus: Option)
    var
        SalesAdvanceLetterLine: Record "Sales Advance Letter Line";
    begin
        SalesAdvanceLetterLine.SetRange("Letter No.", "No.");
        SalesAdvanceLetterLine.ModifyAll(Status, NewStatus, false);
    end;

    [Scope('OnPrem')]
    procedure SetSecurityFilterOnRespCenter()
    begin
        if UserSetupMgt.GetSalesFilter <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetSalesFilter);
            FilterGroup(0);
        end;
    end;

    local procedure ShouldLookForCustomerByName(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if CustomerNo = '' then
            exit(true);

        if not Customer.Get(CustomerNo) then
            exit(true);

        exit(not Customer."Disable Search by Name");
    end;

    local procedure ModifyBillToCustomerAddress()
    var
        Customer: Record Customer;
    begin
        SalesSetup.Get();
        if SalesSetup."Ignore Updated Addresses" then
            exit;

        if Customer.Get("Bill-to Customer No.") then
            if HasBillToAddress and HasDifferentBillToAddress(Customer) then
                ShowModifyAddressNotification(GetModifyBillToCustomerAddressNotificationId,
                    ModifyCustomerAddressNotificationLbl, ModifyCustomerAddressNotificationMsg,
                    'CopyBillToCustomerAddressFieldsFromSalesAdvDocument', "Bill-to Customer No.",
                    "Bill-to Name", FieldName("Bill-to Customer No."));
    end;

    procedure HasBillToAddress(): Boolean
    begin
        exit(("Bill-to Address" <> '') or
            ("Bill-to Address 2" <> '') or
            ("Bill-to City" <> '') or
            ("Bill-to Country/Region Code" <> '') or
            ("Bill-to County" <> '') or
            ("Bill-to Post Code" <> '') or
            ("Bill-to Contact" <> ''));
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

    local procedure ShowModifyAddressNotification(NotificationID: Guid; NotificationLbl: Text; NotificationMsg: Text; NotificationFunctionTok: Text; CustomerNumber: Code[20]; CustomerName: Text[50]; CustomerNumberFieldName: Text)
    var
        MyNotifications: Record "My Notifications";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PageMyNotifications: Page "My Notifications";
        ModifyCustomerAddressNotification: Notification;
    begin
        if not MyNotifications.Get(UserId, NotificationID) then
            PageMyNotifications.InitializeNotificationsWithDefaultState;

        if not MyNotifications.IsEnabled(NotificationID) then
            exit;

        ModifyCustomerAddressNotification.Id := NotificationID;
        ModifyCustomerAddressNotification.Message := StrSubstNo(NotificationMsg, CustomerName);
        ModifyCustomerAddressNotification.AddAction(NotificationLbl, Codeunit::"Document Notifications", NotificationFunctionTok);
        ModifyCustomerAddressNotification.AddAction(
            DontShowAgainActionLbl, Codeunit::"Document Notifications", 'HideNotificationForCurrentUser');
        ModifyCustomerAddressNotification.Scope := NotificationScope::LocalScope;
        ModifyCustomerAddressNotification.SetData(FieldName("No."), "No.");
        ModifyCustomerAddressNotification.SetData(CustomerNumberFieldName, CustomerNumber);
        NotificationLifecycleMgt.SendNotification(ModifyCustomerAddressNotification, RecordId);
    end;

    procedure RecallModifyAddressNotification(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
        ModifyCustomerAddressNotification: Notification;
    begin
        if (not MyNotifications.IsEnabled(NotificationID)) then
            exit;

        ModifyCustomerAddressNotification.Id := NotificationID;
        ModifyCustomerAddressNotification.Recall();
    end;

    procedure GetModifyBillToCustomerAddressNotificationId(): Guid
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnCheckSalesAdvanceLetterReleaseRestrictions()
    begin
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnCheckSalesAdvanceLetterPostRestrictions()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseSalesAdvanceLetter(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSalesAdvanceLetter(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenSalesAdvanceLetter(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenSalesAdvanceLetter(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var SalesAdvanceLetterHeader: Record "Sales Advance Letter Header")
    begin
    end;
#endif
}
