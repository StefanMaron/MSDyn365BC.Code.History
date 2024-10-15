table 31020 "Purch. Advance Letter Header"
{
    Caption = 'Purch. Advance Letter Header';
    DataCaptionFields = "No.", "Pay-to Name";
    DrillDownPageID = "Purchase Adv. Letters";
    LookupPageID = "Purchase Adv. Letters";

    fields
    {
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            TableRelation = Vendor;

            trigger OnValidate()
            var
                VendBankAcc: Record "Vendor Bank Account";
            begin
                if "No." = '' then
                    InitRecord;
                TestField(Status, Status::Open);

                if xRec."Pay-to Vendor No." <> "Pay-to Vendor No." then begin
                    if not HideValidationDialog and GuiAllowed then
                        if "Pay-to Vendor No." <> '' then begin
                            Vend.Get("Pay-to Vendor No.");
                            if (Vend."Pay-to Vendor No." <> '') and (Vend."Pay-to Vendor No." <> Vend."No.") then
                                if Confirm(Text013Qst, true, "Pay-to Vendor No.", Vend."Pay-to Vendor No.") then
                                    "Pay-to Vendor No." := Vend."Pay-to Vendor No.";
                        end;
                    if LetterLinesExist then
                        Error(Text005Err, FieldCaption("Pay-to Vendor No."));
                end;

                if (xRec."Pay-to Vendor No." <> "Pay-to Vendor No.") and
                   (xRec."Pay-to Vendor No." <> '')
                then begin
                    if HideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(Text002Qst, false, FieldCaption("Pay-to Vendor No."));
                    if not Confirmed then
                        "Pay-to Vendor No." := xRec."Pay-to Vendor No.";
                end;

                GetVend("Pay-to Vendor No.");
                Vend.CheckBlockedVendOnDocs(Vend, false);
                Vend.TestField("Vendor Posting Group");

                "Pay-to Name" := Vend.Name;
                "Pay-to Name 2" := Vend."Name 2";
                "Pay-to Address" := Vend.Address;
                "Pay-to Address 2" := Vend."Address 2";
                "Pay-to City" := Vend.City;
                "Pay-to Post Code" := Vend."Post Code";
                "Pay-to County" := Vend.County;
                "Pay-to Country/Region Code" := Vend."Country/Region Code";
                "VAT Country/Region Code" := Vend."Country/Region Code";
                "Pay-to Contact" := Vend.Contact;

                "Gen. Bus. Posting Group" := Vend."Gen. Bus. Posting Group";
                "VAT Bus. Posting Group" := Vend."VAT Bus. Posting Group";

                "Responsibility Center" := UserSetupMgt.GetRespCenter(1, Vend."Responsibility Center");

                if "Template Code" <> '' then begin
                    PurchAdvPmtTemplate.Get("Template Code");
                    if PurchAdvPmtTemplate."Vendor Posting Group" <> '' then
                        Validate("Vendor Posting Group", PurchAdvPmtTemplate."Vendor Posting Group")
                    else
                        "Vendor Posting Group" := Vend."Vendor Posting Group";
                    if PurchAdvPmtTemplate."VAT Bus. Posting Group" <> '' then
                        "VAT Bus. Posting Group" := PurchAdvPmtTemplate."VAT Bus. Posting Group"
                    else
                        "VAT Bus. Posting Group" := Vend."VAT Bus. Posting Group";
                    "Post Advance VAT Option" := PurchAdvPmtTemplate."Post Advance VAT Option";
                    "Amounts Including VAT" := PurchAdvPmtTemplate."Amounts Including VAT";
                end else
                    "Vendor Posting Group" := Vend."Vendor Posting Group";

                "Currency Code" := Vend."Currency Code";
                "Language Code" := Vend."Language Code";

                "Payment Terms Code" := Vend."Payment Terms Code";
                "Payment Method Code" := Vend."Payment Method Code";
                "VAT Registration No." := Vend."VAT Registration No.";
                "Registration No." := Vend."Registration No.";
                "Tax Registration No." := Vend."Tax Registration No.";

                Validate("VAT Country/Region Code");
                VendBankAcc.SetRange("Vendor No.", "Pay-to Vendor No.");
                if VendBankAcc.SetCurrentKey("Vendor No.", Priority) then
                    VendBankAcc.SetFilter(Priority, '%1..', 1);
                if not VendBankAcc.FindFirst then begin
                    VendBankAcc.SetRange(Priority);
                    if VendBankAcc.FindFirst then;
                end;
                Validate("Bank Account Code", VendBankAcc.Code);

                CreateDim(
                  DATABASE::Vendor, "Pay-to Vendor No.",
                  DATABASE::"Salesperson/Purchaser", "Purchaser Code",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center");

                Validate("Currency Code");
                Validate("Payment Terms Code");

                if (xRec."Pay-to Vendor No." <> '') and (xRec."Pay-to Vendor No." <> "Pay-to Vendor No.") then
                    RecallModifyAddressNotification(GetModifyPayToVendorAddressNotificationId);
            end;
        }
        field(5; "Pay-to Name"; Text[100])
        {
            Caption = 'Pay-to Name';
            TableRelation = Vendor.Name;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Vendor: Record Vendor;
            begin
                if ShouldLookForVendorByName("Pay-to Vendor No.") then
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
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
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

            trigger OnValidate()
            begin
                ModifyPayToVendorAddress();
            end;
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            var
                PurchSetup: Record "Purchases & Payables Setup";
            begin
                PurchSetup.Get();
                if PurchSetup."Default VAT Date" = PurchSetup."Default VAT Date"::"Posting Date" then
                    Validate("VAT Date", "Posting Date");
                if PurchSetup."Default Orig. Doc. VAT Date" = PurchSetup."Default Orig. Doc. VAT Date"::"Posting Date" then
                    Validate("Original Document VAT Date", "Posting Date");
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
            begin
                if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                    PaymentTerms.Get("Payment Terms Code");
                    Validate("Advance Due Date", CalcDate(PaymentTerms."Due Date Calculation", "Document Date"));
                end else
                    Validate("Advance Due Date", "Document Date");
            end;
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

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

            trigger OnValidate()
            var
                PostingGroupManagement: Codeunit "Posting Group Management";
            begin
                if CurrFieldNo = FieldNo("Vendor Posting Group") then
                    PostingGroupManagement.CheckPostingGroupChange("Vendor Posting Group", xRec."Vendor Posting Group", Rec);
            end;
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                case true of
                    CurrFieldNo <> FieldNo("Currency Code"):
                        begin
                            UpdateCurrencyFactor;
                            UpdateVATCurrencyFactor;
                        end;
                    "Currency Code" <> xRec."Currency Code":
                        begin
                            if LetterLinesExist then
                                Error(Text005Err, FieldCaption("Currency Code"));
                            UpdateCurrencyFactor;
                            UpdateVATCurrencyFactor;
                            RecreateLines(FieldCaption("Currency Code"));
                        end;
                    "Currency Code" <> '':
                        begin
                            UpdateCurrencyFactor;
                            UpdateVATCurrencyFactor;
                            if "Currency Factor" <> xRec."Currency Factor" then
                                ConfirmUpdateCurrencyFactor;
                        end;
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
                if xRec."Currency Factor" = "VAT Currency Factor" then
                    Validate("VAT Currency Factor", "Currency Factor")
                else
                    if Confirm(Text011Qst, true, FieldCaption("Currency Factor"), FieldCaption("VAT Currency Factor")) then
                        Validate("VAT Currency Factor", "Currency Factor");

                ClearVATCorrection;
            end;
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(43; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Salesperson/Purchaser", "Purchaser Code",
                  DATABASE::Vendor, "Pay-to Vendor No.",
                  DATABASE::Campaign, "Campaign No.",
                  DATABASE::"Responsibility Center", "Responsibility Center");
            end;
        }
        field(44; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            TableRelation = "Purchase Header"."No." WHERE("Document Type" = CONST(Order));
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = Exist("Purch. Comment Line" WHERE("Document Type" = CONST("Advance Letter"),
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

            trigger OnValidate()
            begin
                CalcFields(Status);
                if Status = Status::Open then
                    Release;
            end;
        }
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            CalcFormula = Sum("Purch. Advance Letter Line"."Amount Including VAT" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(68; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
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

            trigger OnValidate()
            var
                NewVATRegNo: Text[20];
            begin
                if "Pay-to Vendor No." <> '' then begin
                    GetVend("Pay-to Vendor No.");
                    NewVATRegNo := Vend."VAT Registration No.";
                end;
                "VAT Registration No." := NewVATRegNo;
            end;
        }
        field(85; "Pay-to Post Code"; Code[20])
        {
            Caption = 'Pay-to Post Code';
            TableRelation = IF ("Pay-to Country/Region Code" = CONST('')) "Post Code"
            ELSE
            IF ("Pay-to Country/Region Code" = FILTER(<> '')) "Post Code" WHERE("Country/Region Code" = FIELD("Pay-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Pay-to City", "Pay-to Post Code", "Pay-to County", "Pay-to Country/Region Code");
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
            Caption = 'Pay-to County';
            CaptionClass = '5,1,' + "Pay-to Country/Region Code";

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
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                Validate("Payment Terms Code");

                PurchSetup.Get();
                if PurchSetup."Default VAT Date" = PurchSetup."Default VAT Date"::"Document Date" then
                    Validate("VAT Date", "Document Date");
                if PurchSetup."Default Orig. Doc. VAT Date" = PurchSetup."Default Orig. Doc. VAT Date"::"Document Date" then
                    Validate("Original Document VAT Date", "Document Date");
            end;
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

            trigger OnValidate()
            begin
                if xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group" then
                    RecreateLines(FieldCaption("VAT Bus. Posting Group"));
            end;
        }
        field(120; Status; Option)
        {
            CalcFormula = Min("Purch. Advance Letter Line".Status WHERE("Letter No." = FIELD("No."),
                                                                         "Amount Including VAT" = FILTER(<> 0)));
            Caption = 'Status';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Open,Pending Payment,Pending Invoice,Pending Final Invoice,Closed,Pending Approval';
            OptionMembers = Open,"Pending Payment","Pending Invoice","Pending Final Invoice",Closed,"Pending Approval";
        }
        field(137; "Advance Due Date"; Date)
        {
            Caption = 'Advance Due Date';

            trigger OnValidate()
            var
                PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
            begin
                if "Advance Due Date" <> xRec."Advance Due Date" then begin
                    if not "Due Date from Line" then begin
                        PurchAdvanceLetterLine.SetRange("Letter No.", "No.");
                        PurchAdvanceLetterLine.ModifyAll("Advance Due Date", "Advance Due Date");
                        exit;
                    end;
                    UpdatePurchAdvLines(FieldCaption("Advance Due Date"), CurrFieldNo <> 0);
                end;
            end;
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
                    IncomingDocument.SetPurchAdvLetterDoc(Rec);
            end;
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
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            begin
                if not UserSetupMgt.CheckRespCenter(1, "Responsibility Center") then
                    Error(
                      RespCenterErr,
                      RespCenter.TableCaption, UserSetupMgt.GetPurchasesFilter);

                CreateDim(
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::Vendor, "Pay-to Vendor No.",
                  DATABASE::"Salesperson/Purchaser", "Purchaser Code",
                  DATABASE::Campaign, "Campaign No.");
            end;
        }
        field(11700; "Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
            TableRelation = "Vendor Bank Account".Code WHERE("Vendor No." = FIELD("Pay-to Vendor No."));

            trigger OnValidate()
            var
                VendBankAcc: Record "Vendor Bank Account";
            begin
                if "Bank Account Code" = '' then begin
                    "Bank Account No." := '';
                    "Specific Symbol" := '';
                    "Transit No." := '';
                    IBAN := '';
                    "SWIFT Code" := '';
                    exit;
                end;

                TestField("Pay-to Vendor No.");
                VendBankAcc.Get("Pay-to Vendor No.", "Bank Account Code");
                "Bank Account No." := VendBankAcc."Bank Account No.";
                "Specific Symbol" := VendBankAcc."Specific Symbol";
                "Transit No." := VendBankAcc."Transit No.";
                IBAN := VendBankAcc.IBAN;
                "SWIFT Code" := VendBankAcc."SWIFT Code";
            end;
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
            TableRelation = "Constant Symbol";
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

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                CompanyInfo.CheckIBAN(IBAN);
            end;
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
        field(11710; "Amount on Payment Order (LCY)"; Decimal)
        {
            CalcFormula = Sum("Issued Payment Order Line"."Amount (LCY)" WHERE("Letter Type" = CONST(Purchase),
                                                                                "Letter No." = FIELD("No."),
                                                                                Status = CONST(" ")));
            Caption = 'Amount on Payment Order (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11760; "VAT Date"; Date)
        {
            Caption = 'VAT Date';

            trigger OnValidate()
            begin
                GLSetup.Get();
                if not GLSetup."Use VAT Date" then
                    TestField("VAT Date", "Posting Date");
                PurchSetup.Get();
                if PurchSetup."Default Orig. Doc. VAT Date" = PurchSetup."Default Orig. Doc. VAT Date"::"VAT Date" then
                    Validate("Original Document VAT Date", "VAT Date");
            end;
        }
        field(11761; "VAT Currency Factor"; Decimal)
        {
            Caption = 'VAT Currency Factor';
            DecimalPlaces = 0 : 15;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestField("Currency Code");
            end;
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

            trigger OnValidate()
            begin
                if "Amounts Including VAT" <> xRec."Amounts Including VAT" then begin
                    CalcFields(Status);
                    TestField(Status, Status::Open);
                    if LetterLinesExist then
                        Error(Text005Err, FieldCaption("Amounts Including VAT"));
                end;
            end;
        }
        field(31012; "Template Code"; Code[10])
        {
            Caption = 'Template Code';
            Editable = false;
            TableRelation = "Purchase Adv. Payment Template";
        }
        field(31013; "Amount To Link"; Decimal)
        {
            CalcFormula = Sum("Purch. Advance Letter Line"."Amount To Link" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount To Link';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31014; "Amount To Invoice"; Decimal)
        {
            CalcFormula = Sum("Purch. Advance Letter Line"."Amount To Invoice" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount To Invoice';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31015; "Amount To Deduct"; Decimal)
        {
            CalcFormula = Sum("Purch. Advance Letter Line"."Amount To Deduct" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount To Deduct';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31016; "Document Linked Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Advance Letter Line Relation".Amount WHERE(Type = CONST(Purchase),
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
            TableRelation = "Purchase Header"."No.";
        }
        field(31018; "Document Linked Inv. Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = Sum("Advance Letter Line Relation"."Invoiced Amount" WHERE(Type = CONST(Purchase),
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
            CalcFormula = Sum("Advance Letter Line Relation"."Deducted Amount" WHERE(Type = CONST(Purchase),
                                                                                      "Letter No." = FIELD("No."),
                                                                                      "Document No." = FIELD("Doc. No. Filter")));
            Caption = 'Document Linked Ded. Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31020; "Amount Linked"; Decimal)
        {
            CalcFormula = Sum("Purch. Advance Letter Line"."Amount Linked" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount Linked';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31021; "Amount Invoiced"; Decimal)
        {
            CalcFormula = Sum("Purch. Advance Letter Line"."Amount Invoiced" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31022; "Amount Deducted"; Decimal)
        {
            CalcFormula = Sum("Purch. Advance Letter Line"."Amount Deducted" WHERE("Letter No." = FIELD("No.")));
            Caption = 'Amount Deducted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31023; "Vendor Adv. Payment No."; Code[20])
        {
            Caption = 'Vendor Adv. Payment No.';
        }
        field(31024; "Due Date from Line"; Boolean)
        {
            Caption = 'Due Date from Line';

            trigger OnValidate()
            begin
                if xRec."Due Date from Line" and (not "Due Date from Line") then
                    CheckLinesForDueDates;
            end;
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
        field(31100; "Original Document VAT Date"; Date)
        {
            Caption = 'Original Document VAT Date';
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
        key(Key3; "Pay-to Vendor No.", "Currency Code", Closed)
        {
        }
        key(Key4; "Order No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        PurchHeader: Record "Purchase Header";
        PurchAdvanceLetterHeader2: Record "Purch. Advance Letter Header";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if not UserSetupMgt.CheckRespCenter(1, "Responsibility Center") then
            Error(
              RespCenterDeleteErr,
              RespCenter.TableCaption, UserSetupMgt.GetPurchasesFilter);

        Validate("Incoming Document Entry No.", 0);

        if "Order No." <> '' then begin
            PurchAdvanceLetterHeader2.SetRange("Order No.", "Order No.");
            PurchAdvanceLetterHeader2.SetFilter("No.", '<>%1', "No.");
            if PurchAdvanceLetterHeader2.IsEmpty() then begin
                if PurchHeader.Get(PurchHeader."Document Type"::Order, "Order No.") then
                    ReleasePurchDoc.Reopen(PurchHeader)
                else
                    if PurchHeader.Get(PurchHeader."Document Type"::Invoice, "Order No.") then
                        ReleasePurchDoc.Reopen(PurchHeader);
            end;
        end;

        AdvanceLetterLineRelation.Reset();
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
        AdvanceLetterLineRelation.SetRange("Letter No.", "No.");
        if AdvanceLetterLineRelation.FindSet(true, false) then begin
            repeat
                AdvanceLetterLineRelation.CancelRelation(AdvanceLetterLineRelation, true, false, true);
            until AdvanceLetterLineRelation.Next() = 0;
        end;

        DeleteLetterLines;

        PurchCommentLine.SetRange("Document Type", PurchCommentLine."Document Type"::"Advance Letter");
        PurchCommentLine.SetRange("No.", "No.");
        PurchCommentLine.DeleteAll();

        ApprovalsMgmt.DeleteApprovalEntryForRecord(Rec);
    end;

    trigger OnInsert()
    begin
        PurchSetup.Get();

        if "Template Code" <> '' then
            PurchAdvPmtTemplate.Get("Template Code");

        if "Document Date" = 0D then
            "Document Date" := WorkDate;

        if "No." = '' then
            if "Template Code" <> '' then begin
                PurchAdvPmtTemplate.TestField("Advance Letter Nos.");
                NoSeriesMgt.InitSeries(PurchAdvPmtTemplate."Advance Letter Nos.", xRec."No. Series", "Document Date", "No.", "No. Series");
                "Post Advance VAT Option" := PurchAdvPmtTemplate."Post Advance VAT Option";
                "Amounts Including VAT" := PurchAdvPmtTemplate."Amounts Including VAT";
            end else begin
                PurchSetup.TestField("Advance Letter Nos.");
                NoSeriesMgt.InitSeries(PurchSetup."Advance Letter Nos.", xRec."No. Series", "Document Date", "No.", "No. Series");
            end;

        InitRecord;

        if GetFilter("Pay-to Vendor No.") <> '' then
            if GetRangeMin("Pay-to Vendor No.") = GetRangeMax("Pay-to Vendor No.") then
                Validate("Pay-to Vendor No.", GetRangeMin("Pay-to Vendor No."));
    end;

    trigger OnRename()
    begin
        Error(Text003Err, TableCaption);
    end;

    var
        PurchSetup: Record "Purchases & Payables Setup";
        GLSetup: Record "General Ledger Setup";
        PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header";
        Vend: Record Vendor;
        CurrExchRate: Record "Currency Exchange Rate";
        PurchCommentLine: Record "Purch. Comment Line";
        PurchAdvPmtTemplate: Record "Purchase Adv. Payment Template";
        PaymentTerms: Record "Payment Terms";
        PurchAdvanceLetterLinegre: Record "Purch. Advance Letter Line";
        PostCode: Record "Post Code";
        RespCenter: Record "Responsibility Center";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        UserSetupMgt: Codeunit "User Setup Management";
        HideValidationDialog: Boolean;
        Confirmed: Boolean;
        CurrencyDate: Date;
        Text001Err: Label 'Purchase Advance Letter %1 already exists.';
        Text002Qst: Label 'Do you want to change %1?';
        Text003Err: Label 'You cannot rename a %1.';
        Text004Err: Label 'You cannot delete this document. There are posted Advance Invoices.';
        Text005Err: Label 'You must delete the existing lines before you can change %1.';
        Text008Qst: Label 'If you change %1, the existing advance lines will be deleted and new advance lines based on the new information on the header will be created. Do you want to change it?';
        Text009Err: Label 'You must delete the existing sales lines before you can change %1.';
        Text010Qst: Label 'You may have changed a dimension. Do you want to update the lines?';
        Text011Qst: Label 'You have changed %1. Do you want to update %2?';
        Text012Err: Label 'You cannot change the %1 to %2 because same lines have been amount on Payment Order.';
        Text013Qst: Label 'Vendor No. %1 has set Pay-to Vendor No. %2. To use Pay-to Vendor No.?';
        Text014Qst: Label 'Do you want to update the exchange rate?';
        ApprovalProcessReleaseErr: Label 'This document can only be released when the approval process is complete.';
        ApprovalProcessReopenErr: Label 'The approval process must be cancelled or completed to reopen this document.';
        PositiveAmountErr: Label 'must be positive';
        RespCenterErr: Label 'Your identification is set up to process from %1 %2 only.', Comment = '%1 = fieldcaption of Responsibility Center; %2 = Responsibility Center';
        RespCenterDeleteErr: Label 'You cannot delete this document. Your identification is set up to process from %1 %2 only.', Comment = '%1 = fieldcaption of Responsibility Center; %2 = Responsibility Center';
        LinesModifiedTxt: Label 'You have modified %1.\\', Comment = '%1 = fieldcaption modified field';
        UpdateLinesQst: Label 'Do you want to update the lines?';
        ModifyVendorAddressNotificationLbl: Label 'Update the address';
        DontShowAgainActionLbl: Label 'Don''t show again';
        ModifyVendorAddressNotificationMsg: Label 'The address you entered for %1 is different from the Vendor''s existing address.', Comment = '%1 = Vendor name';

    [Scope('OnPrem')]
    procedure AssistEdit(PurchAdvanceLetterHeaderOld: Record "Purch. Advance Letter Header"): Boolean
    var
        PurchAdvanceLetterHeader2: Record "Purch. Advance Letter Header";
    begin
        with PurchAdvanceLetterHeader do begin
            Copy(Rec);
            if "Template Code" <> '' then begin
                PurchAdvPmtTemplate.Get("Template Code");
                PurchAdvPmtTemplate.TestField("Advance Letter Nos.");
                if NoSeriesMgt.SelectSeries(PurchAdvPmtTemplate."Advance Letter Nos.", PurchAdvanceLetterHeaderOld."No. Series", "No. Series") then begin
                    NoSeriesMgt.SetSeries("No.");
                    if PurchAdvanceLetterHeader2.Get("No.") then
                        Error(Text001Err, "No.");
                    "Post Advance VAT Option" := PurchAdvPmtTemplate."Post Advance VAT Option";
                    "Amounts Including VAT" := PurchAdvPmtTemplate."Amounts Including VAT";
                    Rec := PurchAdvanceLetterHeader;
                    exit(true);
                end;
            end else begin
                PurchSetup.Get();
                PurchSetup.TestField("Advance Letter Nos.");
                if NoSeriesMgt.SelectSeries(PurchSetup."Advance Letter Nos.", PurchAdvanceLetterHeaderOld."No. Series", "No. Series") then begin
                    NoSeriesMgt.SetSeries("No.");
                    if PurchAdvanceLetterHeader2.Get("No.") then
                        Error(Text001Err, "No.");
                    Rec := PurchAdvanceLetterHeader;
                    exit(true);
                end;
            end;
        end;
    end;

    local procedure GetVend(VendNo: Code[20])
    begin
        if VendNo <> Vend."No." then
            Vend.Get(VendNo);
    end;

    [Scope('OnPrem')]
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(GlobalDimNo: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(GlobalDimNo, ShortcutDimCode, "Dimension Set ID");
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
        if not Confirm(Text010Qst) then
            exit;

        PurchAdvanceLetterLinegre.Reset();
        PurchAdvanceLetterLinegre.SetRange("Letter No.", "No.");

        PurchAdvanceLetterLinegre.LockTable();
        if PurchAdvanceLetterLinegre.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(PurchAdvanceLetterLinegre."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if PurchAdvanceLetterLinegre."Dimension Set ID" <> NewDimSetID then begin
                    PurchAdvanceLetterLinegre."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      PurchAdvanceLetterLinegre."Dimension Set ID",
                      PurchAdvanceLetterLinegre."Shortcut Dimension 1 Code",
                      PurchAdvanceLetterLinegre."Shortcut Dimension 2 Code");
                    PurchAdvanceLetterLinegre.Modify();
                end;
            until PurchAdvanceLetterLinegre.Next() = 0;
        PurchAdvanceLetterLinegre.Reset();
    end;

    [Scope('OnPrem')]
    procedure InitRecord()
    begin
        if "Document Date" = 0D then
            "Document Date" := WorkDate;

        "Posting Description" := TableCaption + ' ' + "No.";

        InitVATDate(PurchSetup."Default VAT Date");
        InitOriginalDocumentVATDate(PurchSetup."Default Orig. Doc. VAT Date");
        "Responsibility Center" := UserSetupMgt.GetRespCenter(1, "Responsibility Center");
    end;

    local procedure InitVATDate(DefaultVATDate: Option)
    begin
        case DefaultVATDate of
            PurchSetup."Default VAT Date"::"Posting Date":
                "VAT Date" := "Posting Date";
            PurchSetup."Default VAT Date"::"Document Date":
                "VAT Date" := "Document Date";
            PurchSetup."Default VAT Date"::Blank:
                "VAT Date" := 0D;
        end;
    end;

    local procedure InitOriginalDocumentVATDate(DefaultOrigDocVATDate: Option)
    begin
        case DefaultOrigDocVATDate of
            PurchSetup."Default Orig. Doc. VAT Date"::Blank:
                "Original Document VAT Date" := 0D;
            PurchSetup."Default Orig. Doc. VAT Date"::"Posting Date":
                "Original Document VAT Date" := "Posting Date";
            PurchSetup."Default Orig. Doc. VAT Date"::"VAT Date":
                "Original Document VAT Date" := "VAT Date";
            PurchSetup."Default Orig. Doc. VAT Date"::"Document Date":
                "Original Document VAT Date" := "Document Date";
        end;
    end;

    [Scope('OnPrem')]
    procedure ConfirmDeletion(): Boolean
    begin
        exit(true);
    end;

    local procedure DeleteLetterLines()
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        PurchAdvanceLetterLine.SetRange("Letter No.", "No.");
        if PurchAdvanceLetterLine.FindSet(true) then begin
            repeat
                PurchAdvanceLetterLine.TestField("Amount Linked", 0);
                if PurchAdvanceLetterLine."Amount Invoiced" <> 0 then
                    Error(Text004Err);

                PurchAdvanceLetterLine.Delete(true);
            until PurchAdvanceLetterLine.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20])
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
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';

        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
              Rec, CurrFieldNo, TableID, No, SourceCodeSetup.Purchases,
              "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        if (OldDimSetID <> "Dimension Set ID") and LetterLinesExist then begin
            Modify;
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    [Scope('OnPrem')]
    procedure LetterLinesExist(): Boolean
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        PurchAdvanceLetterLine.Reset();
        PurchAdvanceLetterLine.SetRange("Letter No.", "No.");
        exit(PurchAdvanceLetterLine.FindFirst);
    end;

    [Scope('OnPrem')]
    procedure ShowLinkedAdvances()
    var
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        PurchPostAdvances: Codeunit "Purchase-Post Advances";
        LinkedPrepayments: Page "Linked Prepayments";
    begin
        PurchAdvanceLetterLine.Reset();
        PurchAdvanceLetterLine.SetRange("Letter No.", "No.");
        if PurchAdvanceLetterLine.FindSet then
            repeat
                PurchPostAdvances.CalcLinkedAmount(PurchAdvanceLetterLine, TempVendLedgEntry);
            until PurchAdvanceLetterLine.Next() = 0;
        LinkedPrepayments.InsertVendEntries(TempVendLedgEntry);
        LinkedPrepayments.RunModal;
    end;

    [Scope('OnPrem')]
    procedure Release()
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        BankAccount: Record "Bank Account";
        VATPostingSetup: Record "VAT Posting Setup";
        BankOperationsFunctions: Codeunit "Bank Operations Functions";
    begin
        OnBeforeReleasePurchaseAdvanceLetter(Rec);
        OnCheckPurchaseAdvanceLetterReleaseRestrictions;

        if ("Variable Symbol" = '') and (not BankAccount.IsEmpty) then begin
            "Variable Symbol" := BankOperationsFunctions.CreateVariableSymbol("Vendor Adv. Payment No.");
            Modify;
        end;

        TestField("Post Advance VAT Option");
        PurchAdvanceLetterLine.RecalcVATOnLines(Rec);

        PurchAdvanceLetterLine.SetRange("Letter No.", "No.");
        PurchAdvanceLetterLine.SetFilter(Status, '%1|%2',
          PurchAdvanceLetterLine.Status::Open,
          PurchAdvanceLetterLine.Status::"Pending Approval");
        if PurchAdvanceLetterLine.FindSet then
            repeat
                if PurchAdvanceLetterLine."Amount Including VAT" < 0 then
                    PurchAdvanceLetterLine.FieldError("Amount Including VAT", PositiveAmountErr);
                if PurchAdvanceLetterLine.Amount > 0 then
                    VATPostingSetup.Get(PurchAdvanceLetterLine."VAT Bus. Posting Group", PurchAdvanceLetterLine."VAT Prod. Posting Group");
                PurchAdvanceLetterLine."Amount To Link" := PurchAdvanceLetterLine."Amount Including VAT";
                PurchAdvanceLetterLine.SuspendStatusCheck(true);
                PurchAdvanceLetterLine.Modify(true);
            until PurchAdvanceLetterLine.Next() = 0;

        OnAfterReleasePurchaseAdvanceLetter(Rec);
    end;

    [Scope('OnPrem')]
    procedure Reopen()
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        OnBeforeReopenPurchaseAdvanceLetter(Rec);

        PurchAdvanceLetterLine.SetRange("Letter No.", "No.");
        PurchAdvanceLetterLine.SetFilter(Status, '%1|%2',
          PurchAdvanceLetterLine.Status::"Pending Advance Payment",
          PurchAdvanceLetterLine.Status::"Pending Approval");
        if PurchAdvanceLetterLine.FindSet then
            repeat
                if (PurchAdvanceLetterLine."Amount To Link" = PurchAdvanceLetterLine."Amount Including VAT") or
                   (PurchAdvanceLetterLine.Status = PurchAdvanceLetterLine.Status::"Pending Approval")
                then begin
                    PurchAdvanceLetterLine."Amount To Link" := 0;
                    PurchAdvanceLetterLine.SuspendStatusCheck(true);
                    PurchAdvanceLetterLine.Modify(true);
                end;
            until PurchAdvanceLetterLine.Next() = 0;

        OnAfterReopenPurchaseAdvanceLetter(Rec);
    end;

    [Scope('OnPrem')]
    procedure PerformManualRelease()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsPurchaseAdvanceLetterApprovalsWorkflowEnabled(Rec) and
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
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        PurchAdvanceLetterLine.SetRange("Letter No.", "No.");
        PurchAdvanceLetterLine.SetFilter("Amount Deducted", '<>%1', 0);
        if PurchAdvanceLetterLine.FindFirst then
            PurchAdvanceLetterLine.TestField("Amount Deducted", 0);
    end;

    [Scope('OnPrem')]
    procedure CheckAmountToInvoice()
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        PurchAdvanceLetterLine.SetRange("Letter No.", "No.");
        PurchAdvanceLetterLine.CalcSums("Amount To Invoice");
        if PurchAdvanceLetterLine."Amount To Invoice" = 0 then begin
            PurchAdvanceLetterLine.SetRange("Amount To Invoice", 0);
            PurchAdvanceLetterLine.FindFirst;
            PurchAdvanceLetterLine.TestField("Amount To Invoice");
        end;
    end;

    [Scope('OnPrem')]
    procedure GetRemAmount() RemAmount: Decimal
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        PurchAdvanceLetterLine.SetRange("Letter No.", "No.");
        if PurchAdvanceLetterLine.FindSet(false, false) then begin
            repeat
                RemAmount += PurchAdvanceLetterLine."Amount To Link";
            until PurchAdvanceLetterLine.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
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
    procedure UpdateClosing(IsModify: Boolean)
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
        IsClosed: Boolean;
    begin
        PurchAdvanceLetterLine.SetRange("Letter No.", "No.");
        PurchAdvanceLetterLine.SetFilter("No.", '<>''''');
        PurchAdvanceLetterLine.SetFilter(Status, '<>%1', PurchAdvanceLetterLine.Status::Closed);
        IsClosed := not PurchAdvanceLetterLine.FindFirst;
        if IsClosed <> Closed then begin
            Closed := IsClosed;
            if IsModify then
                Modify;
        end;
    end;

    local procedure UpdateCurrencyFactor()
    begin
        if "Currency Code" <> '' then begin
            CurrencyDate := "Posting Date";
            if CurrencyDate = 0D then
                CurrencyDate := WorkDate;
            "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
        end else
            "Currency Factor" := 0;
        ClearVATCorrection;
    end;

    local procedure UpdateVATCurrencyFactor()
    begin
        if "Currency Code" = '' then
            "VAT Currency Factor" := 0
        else
            if "Currency Factor" <> xRec."Currency Factor" then begin
                if xRec."Currency Factor" = "VAT Currency Factor" then
                    "VAT Currency Factor" := "Currency Factor"
                else
                    if Confirm(Text011Qst, true, FieldCaption("Currency Factor"), FieldCaption("VAT Currency Factor")) then
                        "VAT Currency Factor" := "Currency Factor";
            end;
    end;

    local procedure ConfirmUpdateCurrencyFactor()
    begin
        if Confirm(Text014Qst, false) then
            Validate("Currency Factor")
        else
            "Currency Factor" := xRec."Currency Factor";
    end;

    [Scope('OnPrem')]
    procedure ShowDocs()
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
        PurchHeader: Record "Purchase Header";
    begin
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
        AdvanceLetterLineRelation.SetRange("Letter No.", "No.");

        if AdvanceLetterLineRelation.FindSet(false, false) then begin
            repeat
                if PurchHeader.Get(AdvanceLetterLineRelation."Document Type", AdvanceLetterLineRelation."Document No.") then
                    PurchHeader.Mark(true);
            until AdvanceLetterLineRelation.Next() = 0;
        end;

        PurchHeader.MarkedOnly(true);
        PAGE.Run(0, PurchHeader);
    end;

    [Scope('OnPrem')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        ReportSelections: Record "Report Selections";
    begin
        with PurchAdvanceLetterHeader do begin
            Copy(Rec);
            ReportSelections.PrintWithDialogForVend(
              ReportSelections.Usage::"P.Adv.Let", PurchAdvanceLetterHeader, ShowRequestForm, FieldNo("Pay-to Vendor No."));
        end;
    end;

    local procedure RecreateLines(ChangedFieldName: Text[100])
    var
        TempPurchAdvanceLetterLine: Record "Purch. Advance Letter Line" temporary;
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        if LetterLinesExist then begin
            if HideValidationDialog or not GuiAllowed then
                Confirmed := true
            else
                Confirmed :=
                  Confirm(
                    Text008Qst, false, ChangedFieldName);
            if Confirmed then begin
                PurchAdvanceLetterLinegre.LockTable();
                xRecRef.GetTable(xRec);
                Modify;
                RecRef.GetTable(Rec);

                PurchAdvanceLetterLinegre.Reset();
                PurchAdvanceLetterLinegre.SetRange("Letter No.", "No.");
                if PurchAdvanceLetterLinegre.FindSet then
                    repeat
                        PurchAdvanceLetterLinegre.TestField(Status, PurchAdvanceLetterLinegre.Status::Open);

                        TempPurchAdvanceLetterLine := PurchAdvanceLetterLinegre;
                        TempPurchAdvanceLetterLine.Insert();
                    until PurchAdvanceLetterLinegre.Next() = 0;

                PurchAdvanceLetterLinegre.DeleteAll(true);
                PurchAdvanceLetterLinegre.Init();
                PurchAdvanceLetterLinegre."Line No." := 0;
                TempPurchAdvanceLetterLine.FindSet();

                repeat
                    PurchAdvanceLetterLinegre.Init();
                    PurchAdvanceLetterLinegre."Line No." := PurchAdvanceLetterLinegre."Line No." + 10000;
                    PurchAdvanceLetterLinegre.Validate("VAT Prod. Posting Group", TempPurchAdvanceLetterLine."VAT Prod. Posting Group");
                    PurchAdvanceLetterLinegre.Validate("Job No.", TempPurchAdvanceLetterLine."Job No.");
                    if "Amounts Including VAT" then
                        PurchAdvanceLetterLinegre.Validate("Amount Including VAT", TempPurchAdvanceLetterLine."Amount Including VAT")
                    else
                        PurchAdvanceLetterLinegre.Validate(Amount, TempPurchAdvanceLetterLine.Amount);
                    PurchAdvanceLetterLinegre.Insert(true);
                until TempPurchAdvanceLetterLine.Next() = 0;
            end else
                Error(
                  Text009Err, ChangedFieldName);
        end;
    end;

    local procedure UpdatePurchAdvLines(ChangedFieldName: Text[100]; AskQuestion: Boolean)
    var
        Question: Text;
    begin
        if not LetterLinesExist then
            exit;

        if AskQuestion then begin
            Question := StrSubstNo(LinesModifiedTxt, ChangedFieldName) + UpdateLinesQst;
            if GuiAllowed then
                if not DIALOG.Confirm(Question, true) then
                    exit;
        end;

        PurchAdvanceLetterLinegre.LockTable();
        Modify;

        PurchAdvanceLetterLinegre.Reset();
        PurchAdvanceLetterLinegre.SetRange("Letter No.", "No.");
        if PurchAdvanceLetterLinegre.FindSet then
            repeat
                case ChangedFieldName of
                    FieldCaption("Advance Due Date"):
                        PurchAdvanceLetterLinegre.Validate("Advance Due Date", "Advance Due Date");
                end;
                PurchAdvanceLetterLinegre.Modify();
            until PurchAdvanceLetterLinegre.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ClearVATCorrection()
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        PurchAdvanceLetterLine.Reset();
        PurchAdvanceLetterLine.SetRange("Letter No.", "No.");
        PurchAdvanceLetterLine.ModifyAll("VAT Difference Inv.", 0);
        PurchAdvanceLetterLine.ModifyAll("VAT Difference Inv. (LCY)", 0);
        PurchAdvanceLetterLine.ModifyAll("VAT Correction Inv.", false);
        PurchAdvanceLetterLine.ModifyAll("VAT Amount Inv.", 0);
    end;

    [Scope('OnPrem')]
    procedure CancelAllRelations()
    var
        AdvanceLetterLineRelation: Record "Advance Letter Line Relation";
    begin
        AdvanceLetterLineRelation.SetCurrentKey(Type, "Letter No.");
        AdvanceLetterLineRelation.SetRange(Type, AdvanceLetterLineRelation.Type::Purchase);
        AdvanceLetterLineRelation.SetRange("Letter No.", "No.");
        if AdvanceLetterLineRelation.FindSet then
            repeat
                AdvanceLetterLineRelation.CancelRelation(AdvanceLetterLineRelation, true, true, true);
            until AdvanceLetterLineRelation.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckLinesForDueDates()
    begin
        PurchAdvanceLetterLinegre.Reset();
        PurchAdvanceLetterLinegre.SetRange("Letter No.", "No.");
        if PurchAdvanceLetterLinegre.FindSet then
            repeat
                PurchAdvanceLetterLinegre.CalcFields("Amount on Payment Order (LCY)");
                if PurchAdvanceLetterLinegre."Amount on Payment Order (LCY)" <> 0 then
                    Error(Text012Err, FieldCaption("Due Date from Line"), "Due Date from Line");
            until PurchAdvanceLetterLinegre.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure SetStatus(NewStatus: Option)
    var
        PurchAdvanceLetterLine: Record "Purch. Advance Letter Line";
    begin
        PurchAdvanceLetterLine.SetRange("Letter No.", "No.");
        PurchAdvanceLetterLine.ModifyAll(Status, NewStatus, false);
    end;

    [Scope('OnPrem')]
    procedure SetSecurityFilterOnRespCenter()
    begin
        if UserSetupMgt.GetPurchasesFilter <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetPurchasesFilter);
            FilterGroup(0);
        end;
    end;

    local procedure ShouldLookForVendorByName(VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if VendorNo = '' then
            exit(true);

        if not Vendor.Get(VendorNo) then
            exit(true);

        exit(not Vendor."Disable Search by Name");
    end;

    local procedure ModifyPayToVendorAddress()
    var
        Vendor: Record Vendor;
    begin
        PurchSetup.Get();
        if PurchSetup."Ignore Updated Addresses" then
            exit;

        if Vendor.Get("Pay-to Vendor No.") then
            if HasPayToAddress and HasDifferentPayToAddress(Vendor) then
                ShowModifyAddressNotification(GetModifyPayToVendorAddressNotificationId,
                    ModifyVendorAddressNotificationLbl, ModifyVendorAddressNotificationMsg,
                    'CopyPayToVendorAddressFieldsFromSalesAdvDocument', "Pay-to Vendor No.",
                    "Pay-to Name", FieldName("Pay-to Vendor No."));
    end;

    procedure HasPayToAddress(): Boolean
    begin
        exit(("Pay-to Address" <> '') or
            ("Pay-to Address 2" <> '') or
            ("Pay-to City" <> '') or
            ("Pay-to Country/Region Code" <> '') or
            ("Pay-to County" <> '') or
            ("Pay-to Post Code" <> '') or
            ("Pay-to Contact" <> ''));
    end;

    procedure HasDifferentPayToAddress(Vendor: Record Vendor): Boolean
    begin
        exit(("Pay-to Address" <> Vendor.Address) or
            ("Pay-to Address 2" <> Vendor."Address 2") or
            ("Pay-to City" <> Vendor.City) or
            ("Pay-to Country/Region Code" <> Vendor."Country/Region Code") or
            ("Pay-to County" <> Vendor.County) or
            ("Pay-to Post Code" <> Vendor."Post Code") or
            ("Pay-to Contact" <> Vendor.Contact));
    end;

    local procedure ShowModifyAddressNotification(NotificationID: Guid; NotificationLbl: Text; NotificationMsg: Text; NotificationFunctionTok: Text; VendorNumber: Code[20]; VendorName: Text[50]; VendorNumberFieldName: Text)
    var
        MyNotifications: Record "My Notifications";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PageMyNotifications: Page "My Notifications";
        ModifyVendorAddressNotification: Notification;
    begin
        if not MyNotifications.Get(UserId, NotificationID) then
            PageMyNotifications.InitializeNotificationsWithDefaultState;

        if not MyNotifications.IsEnabled(NotificationID) then
            exit;

        ModifyVendorAddressNotification.Id := NotificationID;
        ModifyVendorAddressNotification.Message := StrSubstNo(NotificationMsg, VendorName);
        ModifyVendorAddressNotification.AddAction(NotificationLbl, Codeunit::"Document Notifications", NotificationFunctionTok);
        ModifyVendorAddressNotification.AddAction(
            DontShowAgainActionLbl, Codeunit::"Document Notifications", 'HideNotificationForCurrentUser');
        ModifyVendorAddressNotification.Scope := NotificationScope::LocalScope;
        ModifyVendorAddressNotification.SetData(FieldName("No."), "No.");
        ModifyVendorAddressNotification.SetData(VendorNumberFieldName, VendorNumber);
        NotificationLifecycleMgt.SendNotification(ModifyVendorAddressNotification, RecordId);
    end;

    procedure RecallModifyAddressNotification(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
        ModifyVendorAddressNotification: Notification;
    begin
        if (not MyNotifications.IsEnabled(NotificationID)) then
            exit;

        ModifyVendorAddressNotification.Id := NotificationID;
        ModifyVendorAddressNotification.Recall();
    end;

    procedure GetModifyPayToVendorAddressNotificationId(): Guid
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        exit(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnCheckPurchaseAdvanceLetterReleaseRestrictions()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnCheckPurchaseAdvanceLetterPostRestrictions()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleasePurchaseAdvanceLetter(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleasePurchaseAdvanceLetter(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenPurchaseAdvanceLetter(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenPurchaseAdvanceLetter(var PurchAdvanceLetterHeader: Record "Purch. Advance Letter Header")
    begin
    end;
}

