table 11731 "Cash Document Line"
{
    Caption = 'Cash Document Line';
    DrillDownPageID = "Cash Document Lines";

    fields
    {
        field(1; "Cash Desk No."; Code[20])
        {
            Caption = 'Cash Desk No.';
            TableRelation = "Bank Account" WHERE("Account Type" = CONST("Cash Desk"));
        }
        field(2; "Cash Document No."; Code[20])
        {
            Caption = 'Cash Document No.';
            TableRelation = "Cash Document Header"."No." WHERE("Cash Desk No." = FIELD("Cash Desk No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Editable = false;
            OptionCaption = ' ,Payment,,,,,Refund';
            OptionMembers = " ",Payment,,,,,Refund;
        }
        field(5; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = ' ,G/L Account,Customer,Vendor,Bank Account,Fixed Asset,Employee';
            OptionMembers = " ","G/L Account",Customer,Vendor,"Bank Account","Fixed Asset",Employee;

            trigger OnValidate()
            begin
                GetCashDeskEvent;
                if CashDeskEvent."Account Type" <> CashDeskEvent."Account Type"::" " then
                    CashDeskEvent.TestField("Account Type", "Account Type");

                GetDocHeader;

                TempCashDocLine := Rec;
                Init;
                "Cash Document Type" := CashDocHeader."Cash Document Type";
                "Account Type" := TempCashDocLine."Account Type";
                "Cash Desk Event" := TempCashDocLine."Cash Desk Event";
                UpdateAmounts;
                UpdateDocumentType;
            end;
        }
        field(6; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST(" ")) "Standard Text"
            ELSE
            IF ("Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Account Type" = CONST(Employee)) Employee
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account" WHERE("Account Type" = CONST("Bank Account"))
            ELSE
            IF ("Account Type" = CONST("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            var
                StdTxt: Record "Standard Text";
                GLAcc: Record "G/L Account";
                Customer: Record Customer;
                Vendor: Record Vendor;
                BankAcc: Record "Bank Account";
                Employee: Record Employee;
            begin
                if "Account No." <> xRec."Account No." then
                    TestField("Advance Letter Link Code", '');

                GetCashDeskEvent;
                if CashDeskEvent."Account No." <> '' then
                    CashDeskEvent.TestField("Account No.", "Account No.");

                GetDocHeader;

                if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) and ("Account No." <> '') then
                    if CashDocHeader."Partner No." = '' then begin
                        case "Account Type" of
                            "Account Type"::Customer:
                                CashDocHeader."Partner Type" := CashDocHeader."Partner Type"::Customer;
                            "Account Type"::Vendor:
                                CashDocHeader."Partner Type" := CashDocHeader."Partner Type"::Vendor;
                        end;
                        CashDocHeader.SetSkipLineNoToUpdateLine("Line No.");
                        CashDocHeader.Validate("Partner No.", "Account No.");
                        CashDocHeader.Modify();
                        CashDocHeader.SetSkipLineNoToUpdateLine(0);
                        CashDocHeader.Get("Cash Desk No.", "Cash Document No.");
                    end;

                TempCashDocLine := Rec;
                Init;
                "Cash Document Type" := CashDocHeader."Cash Document Type";
                "External Document No." := TempCashDocLine."External Document No.";
                "Cash Desk Event" := TempCashDocLine."Cash Desk Event";
                "Account Type" := TempCashDocLine."Account Type";
                "Account No." := TempCashDocLine."Account No.";
                "Document Type" := TempCashDocLine."Document Type";
                if "Account No." = '' then
                    exit;

                "Currency Code" := CashDocHeader."Currency Code";
                "Responsibility Center" := CashDocHeader."Responsibility Center";
                if "External Document No." = '' then
                    "External Document No." := CashDocHeader."External Document No.";
                "Reason Code" := CashDocHeader."Reason Code";

                case "Account Type" of
                    "Account Type"::" ":
                        begin
                            StdTxt.Get("Account No.");
                            Description := StdTxt.Description;
                        end;
                    "Account Type"::"G/L Account":
                        begin
                            GLAcc.Get("Account No.");
                            GLAcc.CheckGLAcc;
                            Description := GLAcc.Name;
                            if not "System-Created Entry" then
                                GLAcc.TestField("Direct Posting", true);
                            if (GLAcc."VAT Bus. Posting Group" <> '') or
                               (GLAcc."VAT Prod. Posting Group" <> '')
                            then
                                GLAcc.TestField("Gen. Posting Type");
                            Description := GLAcc.Name;
                            "Gen. Posting Type" := GLAcc."Gen. Posting Type";
                            "VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
                            "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
                        end;
                    "Account Type"::Customer:
                        begin
                            Customer.Get("Account No.");
                            Description := Customer.Name;
                            "Posting Group" := Customer."Customer Posting Group";
                            "Gen. Posting Type" := "Gen. Posting Type"::" ";
                            "VAT Bus. Posting Group" := '';
                            "VAT Prod. Posting Group" := '';
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vendor.Get("Account No.");
                            Description := Vendor.Name;
                            "Posting Group" := Vendor."Vendor Posting Group";
                            "Gen. Posting Type" := "Gen. Posting Type"::" ";
                            "VAT Bus. Posting Group" := '';
                            "VAT Prod. Posting Group" := '';
                        end;
                    "Account Type"::"Bank Account":
                        begin
                            BankAcc.Get("Account No.");
                            BankAcc.TestField(Blocked, false);
                            Description := BankAcc.Name;
                            "Gen. Posting Type" := "Gen. Posting Type"::" ";
                            "VAT Bus. Posting Group" := '';
                            "VAT Prod. Posting Group" := '';
                        end;
                    "Account Type"::"Fixed Asset":
                        begin
                            FixedAsset.Get("Account No.");
                            FixedAsset.TestField(Blocked, false);
                            FixedAsset.TestField(Inactive, false);
                            FixedAsset.TestField("Budgeted Asset", false);
                            GetFAPostingGroup;
                            Description := FixedAsset.Description;
                        end;
                    "Account Type"::Employee:
                        begin
                            CashDocHeader.TestField("Currency Code", '');
                            Employee.Get("Account No.");
                            Description := CopyStr(Employee.FullName, 1, MaxStrLen(Description));
                        end;
                end;

                if not ("Account Type" in ["Account Type"::" ", "Account Type"::"Fixed Asset"]) then
                    Validate("VAT Prod. Posting Group");

                CreateDim(
                  TypeToTableID("Account Type"), "Account No.",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Cash Desk Event", "Cash Desk Event");

                if ("Cash Document Type" = "Cash Document Type"::Withdrawal) and
                   VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group")
                then
                    "VAT % (Non Deductible)" := GetVATDeduction;
            end;
        }
        field(7; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            TableRelation = IF ("Account Type" = CONST("Fixed Asset")) "FA Posting Group"
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account Posting Group"
            ELSE
            IF ("Account Type" = CONST(Customer)) "Customer Posting Group"
            ELSE
            IF ("Account Type" = CONST(Vendor)) "Vendor Posting Group";

            trigger OnValidate()
            var
                PostingGroupManagement: Codeunit "Posting Group Management";
            begin
                if CurrFieldNo = FieldNo("Posting Group") then
                    PostingGroupManagement.CheckPostingGroupChange("Posting Group", xRec."Posting Group", Rec);
            end;
        }
        field(14; "Applies-To Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-To Doc. Type';

            trigger OnValidate()
            begin
                if "Applies-To Doc. Type" <> xRec."Applies-To Doc. Type" then
                    Validate("Applies-To Doc. No.", '');
            end;
        }
        field(15; "Applies-To Doc. No."; Code[20])
        {
            Caption = 'Applies-To Doc. No.';

            trigger OnLookup()
            var
                GenJnlLine: Record "Gen. Journal Line";
                CashDocPost: Codeunit "Cash Document-Post";
                PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
                AccNo: Code[20];
                AccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner",Employee;
                xAmount: Decimal;
            begin
                GetDocHeader;
                CashDocPost.InitGenJnlLine(CashDocHeader, Rec);
                CashDocPost.GetGenJnlLine(GenJnlLine);
                xAmount := GenJnlLine.Amount;

                if GenJnlLine."Bal. Account Type" in [GenJnlLine."Bal. Account Type"::Customer,
                                                      GenJnlLine."Bal. Account Type"::Vendor,
                                                      GenJnlLine."Bal. Account Type"::Employee]
                then begin
                    AccNo := GenJnlLine."Bal. Account No.";
                    AccType := GenJnlLine."Bal. Account Type";
                end else begin
                    AccNo := GenJnlLine."Account No.";
                    AccType := GenJnlLine."Account Type";
                end;

                if (AccType <> GenJnlLine."Account Type"::Customer) and
                   (AccType <> GenJnlLine."Account Type"::Vendor) and
                   (AccType <> GenJnlLine."Account Type"::Employee)
                then begin
                    AccType := GenJnlLine."Bal. Account Type";
                    AccNo := GenJnlLine."Bal. Account No.";
                end;

                case AccType of
                    AccType::Customer:
                        LookupApplyCustEntry(GenJnlLine, AccNo);
                    AccType::Vendor:
                        LookupApplyVendEntry(GenJnlLine, AccNo);
                    AccType::Employee:
                        LookupApplyEmplEntry(GenJnlLine, AccNo);
                end;

                if GenJnlLine."Applies-to Doc. No." = '' then
                    exit;

                if AccNo = '' then
                    Validate("Account No.", GenJnlLine."Account No.");
                "Applies-To Doc. Type" := GenJnlLine."Applies-to Doc. Type";
                "Applies-To Doc. No." := GenJnlLine."Applies-to Doc. No.";
                "Applies-to ID" := GenJnlLine."Applies-to ID";
                Validate(Amount, SignAmount * GenJnlLine.Amount);

                if xAmount <> 0 then
                    if not PaymentToleranceMgt.PmtTolGenJnl(GenJnlLine) then
                        exit;
            end;

            trigger OnValidate()
            var
                GenJnlLine: Record "Gen. Journal Line";
                CustLedgEntry: Record "Cust. Ledger Entry";
                VendLedgEntry: Record "Vendor Ledger Entry";
                EmplLedgEntry: Record "Employee Ledger Entry";
                CashDocPost: Codeunit "Cash Document-Post";
            begin
                GetDocHeader;
                CashDocPost.InitGenJnlLine(CashDocHeader, Rec);
                CashDocPost.GetGenJnlLine(GenJnlLine);
                GenJnlLine.SetSuppressCommit(true);
                GenJnlLine.SetUseForCalculation(true);
                GenJnlLine.Validate("Applies-to Doc. No.");

                if ("Applies-To Doc. No." = '') and (xRec."Applies-To Doc. No." <> '') then begin
                    PaymentToleranceMgt.DelPmtTolApllnDocNo(GenJnlLine, xRec."Applies-To Doc. No.");

                    case "Account Type" of
                        "Account Type"::Customer:
                            begin
                                CustLedgEntry.SetCurrentKey("Document No.");
                                CustLedgEntry.SetRange("Document No.", xRec."Applies-To Doc. No.");
                                if not (xRec."Applies-To Doc. Type" = "Document Type"::" ") then
                                    CustLedgEntry.SetRange("Document Type", xRec."Applies-To Doc. Type");
                                CustLedgEntry.SetRange("Customer No.", "Account No.");
                                CustLedgEntry.SetRange(Open, true);
                                if CustLedgEntry.FindFirst() then
                                    if CustLedgEntry."Amount to Apply" <> 0 then begin
                                        CustLedgEntry."Amount to Apply" := 0;
                                        Codeunit.Run(Codeunit::"Cust. Entry-Edit", CustLedgEntry);
                                    end;
                            end;
                        "Account Type"::Vendor:
                            begin
                                VendLedgEntry.SetCurrentKey("Document No.");
                                VendLedgEntry.SetRange("Document No.", xRec."Applies-To Doc. No.");
                                if not (xRec."Applies-To Doc. Type" = "Document Type"::" ") then
                                    VendLedgEntry.SetRange("Document Type", xRec."Applies-To Doc. Type");
                                VendLedgEntry.SetRange("Vendor No.", "Account No.");
                                VendLedgEntry.SetRange(Open, true);
                                if VendLedgEntry.FindFirst() then
                                    if VendLedgEntry."Amount to Apply" <> 0 then begin
                                        VendLedgEntry."Amount to Apply" := 0;
                                        Codeunit.Run(Codeunit::"Vend. Entry-Edit", VendLedgEntry);
                                    end;
                            end;
                        "Account Type"::Employee:
                            begin
                                EmplLedgEntry.SetCurrentKey("Document No.");
                                EmplLedgEntry.SetRange("Document No.", xRec."Applies-To Doc. No.");
                                if not (xRec."Applies-To Doc. Type" = "Document Type"::" ") then
                                    EmplLedgEntry.SetRange("Document Type", xRec."Applies-To Doc. Type");
                                EmplLedgEntry.SetRange("Employee No.", "Account No.");
                                EmplLedgEntry.SetRange(Open, true);
                                if EmplLedgEntry.FindFirst() then
                                    if EmplLedgEntry."Amount to Apply" <> 0 then begin
                                        EmplLedgEntry."Amount to Apply" := 0;
                                        Codeunit.Run(Codeunit::"Empl. Entry-Edit", EmplLedgEntry);
                                    end;
                            end;
                    end;
                end;

                if (Amount = 0) and ("Applies-To Doc. No." <> '') then begin
                    TestField("Currency Code", GenJnlLine."Currency Code");
                    Validate("Account No.", GenJnlLine."Account No.");

                    case "Account Type" of
                        "Account Type"::Customer:
                            begin
                                GenJnlLine.GetAppliedCustLedgerEntry(CustLedgEntry);
                                CustLedgEntry.CalcFields("Remaining Amount");
                                GenJnlLine.Validate(Amount, GetAmtToApplyCust(CustLedgEntry, GenJnlLine));
                                Validate(Amount, SignAmount * GenJnlLine.Amount);
                            end;
                        "Account Type"::Vendor:
                            begin
                                GenJnlLine.GetAppliedVendLedgerEntry(VendLedgEntry);
                                VendLedgEntry.CalcFields("Remaining Amount");
                                GenJnlLine.Validate(Amount, GetAmtToApplyVend(VendLedgEntry, GenJnlLine));
                                Validate(Amount, SignAmount * GenJnlLine.Amount);
                            end;
                        "Account Type"::Employee:
                            begin
                                GenJnlLine.GetAppliedEmplLedgerEntry(EmplLedgEntry);
                                EmplLedgEntry.CalcFields("Remaining Amount");
                                GenJnlLine.Validate(Amount, GetAmtToApplyEmpl(EmplLedgEntry));
                                Validate(Amount, SignAmount * GenJnlLine.Amount);
                            end;
                    end;

                    "Applies-To Doc. Type" := GenJnlLine."Applies-to Doc. Type";
                    "Applies-To Doc. No." := GenJnlLine."Applies-to Doc. No.";
                    "Applies-to ID" := GenJnlLine."Applies-to ID";
                end;

                if ("Applies-To Doc. No." <> xRec."Applies-To Doc. No.") and (Amount <> 0) then begin
                    if xRec."Applies-To Doc. No." <> '' then
                        PaymentToleranceMgt.DelPmtTolApllnDocNo(GenJnlLine, xRec."Applies-To Doc. No.");
                    PaymentToleranceMgt.PmtTolGenJnl(GenJnlLine);
                end;
            end;
        }
        field(16; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(17; Amount; Decimal)
        {
            Caption = 'Amount';

            trigger OnValidate()
            begin
                TestField("Account Type");
                TestField("Account No.");

                UpdateAmounts;
            end;
        }
        field(18; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';

            trigger OnValidate()
            var
                CurrExchRate: Record "Currency Exchange Rate";
            begin
                GetDocHeader;

                if CashDocHeader."Currency Code" = '' then
                    Validate(Amount, "Amount (LCY)")
                else
                    Validate(Amount, Round(CurrExchRate.ExchangeAmtLCYToFCY(CashDocHeader."Posting Date", CashDocHeader."Currency Code",
                          "Amount (LCY)", CashDocHeader."Currency Factor"), Currency."Amount Rounding Precision"));
            end;
        }
        field(20; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(22; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
        }
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(26; "Cash Document Type"; Option)
        {
            Caption = 'Cash Document Type';
            Editable = false;
            OptionCaption = ' ,Receipt,Withdrawal';
            OptionMembers = " ",Receipt,Withdrawal;
        }
        field(28; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(29; Prepayment; Boolean)
        {
            Caption = 'Prepayment';

            trigger OnValidate()
            begin
                if Prepayment then begin
                    GLSetup.Get();
                    GLSetup.TestField("Prepayment Type");
                    "Prepayment Type" := GLSetup."Prepayment Type";
                end else
                    "Prepayment Type" := "Prepayment Type"::" ";
                Validate("Prepayment Type");
            end;
        }
        field(30; "Prepayment Type"; Option)
        {
            Caption = 'Prepayment Type';
            OptionCaption = ' ,Prepayment,Advance';
            OptionMembers = " ",Prepayment,Advance;

            trigger OnValidate()
            begin
                TestField(Prepayment, "Prepayment Type" <> "Prepayment Type"::" ");
                if "Prepayment Type" = "Prepayment Type"::Advance then begin
                    TestField("Applies-To Doc. Type", 0);
                    TestField("Applies-To Doc. No.", '');
                end;
            end;
        }
        field(36; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(40; "Cash Desk Event"; Code[10])
        {
            Caption = 'Cash Desk Event';
            TableRelation = "Cash Desk Event";

            trigger OnLookup()
            var
                CashDeskEvent: Record "Cash Desk Event";
            begin
                GetDocHeader;
                CashDeskEvent.Reset();
                CashDeskEvent.FilterGroup(2);
                CashDeskEvent.SetFilter("Cash Document Type", '%1|%2', CashDocHeader."Cash Document Type"::" ", CashDocHeader."Cash Document Type");
                CashDeskEvent.SetFilter("Cash Desk No.", '%1|%2', '', CashDocHeader."Cash Desk No.");
                CashDeskEvent.FilterGroup(0);
                CashDeskEvent.Code := "Cash Desk Event";
                if PAGE.RunModal(0, CashDeskEvent) = ACTION::LookupOK then
                    Validate("Cash Desk Event", CashDeskEvent.Code);
            end;

            trigger OnValidate()
            begin
                if "Cash Desk Event" <> xRec."Cash Desk Event" then
                    if "Cash Desk Event" <> '' then begin
                        BankAccount.Get("Cash Desk No.");
                        GetCashDeskEvent;
                        GetDocHeader;
                        case CashDocHeader."Cash Document Type" of
                            CashDocHeader."Cash Document Type"::Receipt:
                                CashDeskEvent.TestField("Cash Document Type", CashDeskEvent."Cash Document Type"::Receipt);
                            CashDocHeader."Cash Document Type"::Withdrawal:
                                CashDeskEvent.TestField("Cash Document Type", CashDeskEvent."Cash Document Type"::Withdrawal);
                        end;
                        TempCashDocLine := Rec;
                        Init;
                        "External Document No." := TempCashDocLine."External Document No.";
                        "Cash Desk Event" := TempCashDocLine."Cash Desk Event";
                        Validate("Account Type", CashDeskEvent."Account Type");
                        Validate("System-Created Entry", true);
                        if CashDeskEvent."Account No." <> '' then
                            Validate("Account No.", CashDeskEvent."Account No.");
                        Validate(Description, CashDeskEvent.Description);
                        Validate("Gen. Posting Type", CashDeskEvent."Gen. Posting Type");
                        if CashDeskEvent."VAT Bus. Posting Group" <> '' then
                            Validate("VAT Bus. Posting Group", CashDeskEvent."VAT Bus. Posting Group");
                        if CashDeskEvent."VAT Prod. Posting Group" <> '' then
                            Validate("VAT Prod. Posting Group", CashDeskEvent."VAT Prod. Posting Group");
                        if CashDeskEvent."Global Dimension 1 Code" <> '' then
                            Validate("Shortcut Dimension 1 Code", CashDeskEvent."Global Dimension 1 Code");
                        if CashDeskEvent."Global Dimension 2 Code" <> '' then
                            Validate("Shortcut Dimension 2 Code", CashDeskEvent."Global Dimension 2 Code");
                        Validate("Document Type", CashDeskEvent."Document Type");
                        "Currency Code" := CashDocHeader."Currency Code";
                        Validate("Salespers./Purch. Code", CashDocHeader."Salespers./Purch. Code");
                        CreateDim(
                          TypeToTableID("Account Type"), "Account No.",
                          DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                          DATABASE::"Responsibility Center", "Responsibility Center",
                          DATABASE::"Cash Desk Event", "Cash Desk Event");
                    end;
            end;
        }
        field(42; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                CreateDim(
                  TypeToTableID("Account Type"), "Account No.",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Cash Desk Event", "Cash Desk Event");
            end;
        }
        field(43; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(51; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;

            trigger OnValidate()
            begin
                GetDocHeader;
                "VAT Base Amount" := Round("VAT Base Amount", Currency."Amount Rounding Precision");

                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                        "VAT Amount" :=
                          Round("VAT Base Amount" * ("VAT %" / 100),
                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection);
                    "VAT Calculation Type"::"Full VAT":
                        if "VAT Base Amount" <> 0 then
                            FieldError("VAT Base Amount", StrSubstNo(MustBeZeroErr, FieldCaption("VAT Calculation Type"),
                                "VAT Calculation Type"));
                end;

                if CashDocHeader."Currency Code" = '' then begin
                    "VAT Base Amount (LCY)" := "VAT Base Amount";
                    "VAT Amount (LCY)" := "VAT Amount";
                end else begin
                    "VAT Base Amount (LCY)" := Round("VAT Base Amount" / CashDocHeader."Currency Factor");
                    "VAT Amount (LCY)" := Round("VAT Amount" / CashDocHeader."Currency Factor");
                end;

                "Amount Including VAT" := "VAT Base Amount" + "VAT Amount";
                "Amount Including VAT (LCY)" := "VAT Base Amount (LCY)" + "VAT Amount (LCY)";
                "VAT Difference" := 0;
                "VAT Difference (LCY)" := 0;
                Validate("VAT % (Non Deductible)");
            end;
        }
        field(52; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;

            trigger OnValidate()
            begin
                GetDocHeader;
                "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");

                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                  "VAT Calculation Type"::"Reverse Charge VAT":
                        "VAT Amount" :=
                          Round("Amount Including VAT" * CalcVATCoefficient, Currency."Amount Rounding Precision");
                    "VAT Calculation Type"::"Full VAT":
                        "VAT Base Amount" := 0;
                end;

                if CashDocHeader."Currency Code" = '' then begin
                    "Amount Including VAT (LCY)" := "Amount Including VAT";
                    "VAT Amount (LCY)" := "VAT Amount";
                end else begin
                    "Amount Including VAT (LCY)" := Round("Amount Including VAT" / CashDocHeader."Currency Factor");
                    "VAT Amount (LCY)" := Round("VAT Amount" / CashDocHeader."Currency Factor");
                end;

                "VAT Base Amount" := "Amount Including VAT" - "VAT Amount";
                "VAT Base Amount (LCY)" := "Amount Including VAT (LCY)" - "VAT Amount (LCY)";
                "VAT Difference" := 0;
                "VAT Difference (LCY)" := 0;
                Validate("VAT % (Non Deductible)");
            end;
        }
        field(53; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';

            trigger OnValidate()
            begin
                GLSetup.Get();
                GetDocHeader;
                BankAccount.Get("Cash Desk No.");

                if CurrFieldNo = FieldNo("VAT Amount") then
                    BankAccount.TestField("Allow VAT Difference");

                if not ("VAT Calculation Type" in
                        ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"])
                then
                    Error(
                      MustBeErr, FieldCaption("VAT Calculation Type"),
                      "VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT");
                if "VAT Amount" <> 0 then begin
                    TestField("VAT %");
                    TestField("VAT Base Amount");
                end;

                "VAT Amount" := Round("VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection);

                if "VAT Amount" * "VAT Base Amount" < 0 then begin
                    if "VAT Amount" > 0 then
                        Error(MustBeNegativeErr, FieldCaption("VAT Amount"));
                    Error(MustBePositiveErr, FieldCaption("VAT Amount"));
                end;

                if CashDocHeader."Currency Code" = '' then begin
                    "VAT Amount (LCY)" := "VAT Amount";

                    if CashDocHeader."Amounts Including VAT" then
                        "Amount Including VAT (LCY)" := "Amount Including VAT"
                    else
                        "VAT Base Amount (LCY)" := "VAT Base Amount";
                end else begin
                    "VAT Amount (LCY)" := Round("VAT Amount" / CashDocHeader."Currency Factor");

                    if CashDocHeader."Amounts Including VAT" then
                        "Amount Including VAT (LCY)" := Round("Amount Including VAT" / CashDocHeader."Currency Factor")
                    else
                        "VAT Base Amount (LCY)" := Round("VAT Base Amount" / CashDocHeader."Currency Factor");
                end;

                if CashDocHeader."Amounts Including VAT" then begin
                    "VAT Base Amount" := "Amount Including VAT" - "VAT Amount";
                    "VAT Base Amount (LCY)" := "Amount Including VAT (LCY)" - "VAT Amount (LCY)";
                end else begin
                    "Amount Including VAT" := "VAT Base Amount" + "VAT Amount";
                    "Amount Including VAT (LCY)" := "VAT Base Amount (LCY)" + "VAT Amount (LCY)";
                end;

                "VAT Difference" := "VAT Amount" - CalcVATAmount;
                "VAT Difference (LCY)" := "VAT Amount (LCY)" - CalcVATAmountLCY;

                if CurrFieldNo = FieldNo("VAT Amount") then
                    if Abs("VAT Difference") > Currency."Max. VAT Difference Allowed" then
                        Error(MustNotBeMoreThanErr, FieldCaption("VAT Difference"), Currency."Max. VAT Difference Allowed");

                Validate("VAT % (Non Deductible)");
            end;
        }
        field(55; "VAT Base Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
        }
        field(56; "Amount Including VAT (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount Including VAT (LCY)';
            Editable = false;
        }
        field(57; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VAT Amount (LCY)';
            Editable = false;
        }
        field(59; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(60; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(61; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(62; "VAT Difference (LCY)"; Decimal)
        {
            Caption = 'VAT Difference (LCY)';
        }
        field(63; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(65; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;
        }
        field(70; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(71; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(72; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                if VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then begin
                    "VAT %" := VATPostingSetup."VAT %";
                    if "Cash Document Type" = "Cash Document Type"::Withdrawal then
                        "VAT % (Non Deductible)" := GetVATDeduction;
                    "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                    "VAT Identifier" := VATPostingSetup."VAT Identifier";
                    case "VAT Calculation Type" of
                        "VAT Calculation Type"::"Reverse Charge VAT",
                        "VAT Calculation Type"::"Sales Tax":
                            begin
                                "VAT %" := 0;
                                "VAT % (Non Deductible)" := 0;
                            end;
                        "VAT Calculation Type"::"Full VAT":
                            begin
                                TestField("Account Type", "Account Type"::"G/L Account");
                                VATPostingSetup.TestField("Sales VAT Account");
                                TestField("Account No.", VATPostingSetup."Sales VAT Account");
                            end;
                    end;
                end else begin
                    "VAT %" := 0;
                    "VAT % (Non Deductible)" := 0;
                    "VAT Calculation Type" := "VAT Calculation Type"::"Normal VAT";
                    "VAT Identifier" := '';
                end;

                Validate(Amount);
            end;
        }
        field(75; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';

            trigger OnValidate()
            begin
                TestField("Gen. Posting Type", "Gen. Posting Type"::Purchase);
            end;
        }
        field(90; "FA Posting Type"; Option)
        {
            Caption = 'FA Posting Type';
            OptionCaption = ' ,Acquisition Cost,,,Appreciation,,Custom 2,,Maintenance';
            OptionMembers = " ","Acquisition Cost",,,Appreciation,,"Custom 2",,Maintenance;
        }
        field(91; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";
        }
        field(92; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;

            trigger OnValidate()
            begin
                if "Maintenance Code" <> '' then
                    TestField("FA Posting Type", "FA Posting Type"::Maintenance);
            end;
        }
        field(93; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                "Use Duplication List" := false;
            end;
        }
        field(94; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';

            trigger OnValidate()
            begin
                "Duplicate in Depreciation Book" := '';
            end;
        }
        field(98; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            Editable = false;
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            begin
                CreateDim(
                  TypeToTableID("Account Type"), "Account No.",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Cash Desk Event", "Cash Desk Event");
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(602; "VAT % (Non Deductible)"; Decimal)
        {
            Caption = 'VAT % (Non Deductible)';
            MaxValue = 100;
            MinValue = 0;
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Non-deductible VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';

            trigger OnValidate()
            begin
                if "Cash Document Type" = "Cash Document Type"::Withdrawal then begin
                    "VAT Base (Non Deductible)" :=
                      Round("VAT Base Amount" * "VAT % (Non Deductible)" / 100, Currency."Amount Rounding Precision");
                    "VAT Amount (Non Deductible)" :=
                      Round(("Amount Including VAT" - "VAT Base Amount") * "VAT % (Non Deductible)" / 100,
                        Currency."Amount Rounding Precision");
                end;
            end;
        }
        field(603; "VAT Base (Non Deductible)"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            Caption = 'VAT Base (Non Deductible)';
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Non-deductible VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
        field(604; "VAT Amount (Non Deductible)"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            Caption = 'VAT Amount (Non Deductible)';
            Editable = false;
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Non-deductible VAT will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
        field(31001; "Advance Letter Link Code"; Code[30])
        {
            Caption = 'Advance Letter Link Code';

            trigger OnValidate()
            begin
                UpdateEETTransaction;
            end;
        }
        field(31125; "EET Transaction"; Boolean)
        {
            Caption = 'EET Transaction';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Cash Desk No.", "Cash Document No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key2; "Cash Desk No.", "Cash Document No.", "External Document No.", "VAT Identifier")
        {
            SumIndexFields = "Amount Including VAT", "Amount Including VAT (LCY)", "VAT Base Amount", "VAT Base Amount (LCY)", "VAT Amount", "VAT Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PrepmtLinksMgt: Codeunit "Prepayment Links Management";
    begin
        if "Advance Letter Link Code" <> '' then
            case "Account Type" of
                "Account Type"::Customer:
                    PrepmtLinksMgt.UnLinkWholeSalesLetter("Advance Letter Link Code");
                "Account Type"::Vendor:
                    PrepmtLinksMgt.UnLinkWholePurchLetter("Advance Letter Link Code");
            end;
    end;

    trigger OnInsert()
    begin
        LockTable();
        InitRecord;
        UpdateEETTransaction;
    end;

    trigger OnModify()
    begin
        UpdateEETTransaction;
    end;

    trigger OnRename()
    begin
        Error(RenameErr, TableCaption);
    end;

    var
        CashDocHeader: Record "Cash Document Header";
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        BankAccount: Record "Bank Account";
        CashDeskEvent: Record "Cash Desk Event";
        TempCashDocLine: Record "Cash Document Line" temporary;
        FixedAsset: Record "Fixed Asset";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        RenameErr: Label 'You cannot rename a %1.', Comment = '%1=TABLECAPTION';
        LookupConfirmQst: Label 'The %1 in the %2 will be changed from %3 to %4.\Do you wish to continue?', Comment = '%1=Field caption of Currency Code,%2=Table caption of Gen. Jnl. Line,%3=Old Currency Code,%4=New Currency Code';
        UpdateInteruptedErr: Label 'The update has been interrupted to respect the warning.';
        MustBeNegativeErr: Label '%1 must be negative.', Comment = '%1=Field caption of VAT Amount';
        MustBePositiveErr: Label '%1 must be positive.', Comment = '%1=Field caption of VAT Amount';
        MustBeErr: Label '%1 must be %2 or %3.', Comment = '%1=FIELDCAPTION("VAT Calculation Type"),%2="VAT Calculation Type"::"Normal VAT",%3="VAT Calculation Type"::"Reverse Charge VAT"';
        MustNotBeMoreThanErr: Label 'The %1 must not be more than %2.', Comment = '%1=FIELDCAPTION("VAT Difference"),%2=GLSetup."Max. VAT Difference Allowed"';
        MustBeZeroErr: Label ' must be 0 when %1 is %2.', Comment = '%1=FIELDCAPTION("VAT Calculation Type"),%2="VAT Calculation Type"';
        DimMgt: Codeunit DimensionManagement;
        HideValidationDialog: Boolean;

    [Scope('OnPrem')]
    procedure InitRecord()
    begin
        GetDocHeader;
        "Cash Desk No." := CashDocHeader."Cash Desk No.";
        "Cash Document Type" := CashDocHeader."Cash Document Type";
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption, "Cash Document No.", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
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
        GetDocHeader;
        "Dimension Set ID" :=
          DimMgt.GetDefaultDimID(
            TableID, No, SourceCodeSetup."Cash Desk",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code",
            CashDocHeader."Dimension Set ID", DATABASE::Customer);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure GetDocHeader()
    begin
        TestField("Cash Desk No.");
        TestField("Cash Document No.");
        if ("Cash Desk No." <> CashDocHeader."Cash Desk No.") or ("Cash Document No." <> CashDocHeader."No.") then begin
            CashDocHeader.Get("Cash Desk No.", "Cash Document No.");
            if CashDocHeader."Currency Code" = '' then
                Currency.InitRoundingPrecision
            else begin
                CashDocHeader.TestField("Currency Factor");
                Currency.Get(CashDocHeader."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;

        CashDocHeader.SetHideValidationDialog(HideValidationDialog);
    end;

    [Scope('OnPrem')]
    procedure UpdateAmounts()
    var
        CurrExchRate: Record "Currency Exchange Rate";
        GenJnlLine: Record "Gen. Journal Line";
        CashDocPost: Codeunit "Cash Document-Post";
    begin
        GetDocHeader;

        if CashDocHeader."Currency Code" <> '' then
            "Amount (LCY)" := Round(CurrExchRate.ExchangeAmtFCYToLCY(CashDocHeader."Posting Date", CashDocHeader."Currency Code",
                  Amount, CashDocHeader."Currency Factor"))
        else
            "Amount (LCY)" := Round(Amount);

        if CashDocHeader."Amounts Including VAT" then
            Validate("Amount Including VAT", Amount)
        else
            Validate("VAT Base Amount", Amount);

        if (Amount <> xRec.Amount) and
           (xRec.Amount <> 0) or (xRec."Applies-To Doc. No." <> '') or (xRec."Applies-to ID" <> '')
        then begin
            CashDocPost.InitGenJnlLine(CashDocHeader, Rec);
            CashDocPost.GetGenJnlLine(GenJnlLine);
            PaymentToleranceMgt.PmtTolGenJnl(GenJnlLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateDocumentType()
    begin
        "Document Type" := "Document Type"::" ";
        if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) then
            exit;

        if (("Cash Document Type" = "Cash Document Type"::Receipt) and ("Account Type" = "Account Type"::Customer)) or
           (("Cash Document Type" = "Cash Document Type"::Withdrawal) and ("Account Type" = "Account Type"::Vendor))
        then
            "Document Type" := "Document Type"::Payment;

        if (("Cash Document Type" = "Cash Document Type"::Withdrawal) and ("Account Type" = "Account Type"::Customer)) or
           (("Cash Document Type" = "Cash Document Type"::Receipt) and ("Account Type" = "Account Type"::Vendor))
        then
            "Document Type" := "Document Type"::Refund;
    end;

    [Scope('OnPrem')]
    procedure SignAmount(): Integer
    begin
        if "Cash Document Type" = "Cash Document Type"::Receipt then
            exit(-1);
        exit(1);
    end;

    [Scope('OnPrem')]
    procedure ApplyEntries()
    var
        GenJnlLine: Record "Gen. Journal Line";
        CashDocPost: Codeunit "Cash Document-Post";
    begin
        CashDocHeader.Get("Cash Desk No.", "Cash Document No.");
        if "Account Type" = "Account Type"::Customer then
            CashDocHeader.TestNotEETCashRegister;
        CashDocPost.InitGenJnlLine(CashDocHeader, Rec);
        CashDocPost.GetGenJnlLine(GenJnlLine);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJnlLine);
        "Applies-to ID" := GenJnlLine."Applies-to ID";
        if Amount = 0 then
            if CashDocHeader."Amounts Including VAT" then
                Validate(Amount, SignAmount * GenJnlLine.Amount)
            else
                Validate(Amount, SignAmount * GenJnlLine.Amount * (1 - "VAT %" / (100 + "VAT %")));
        Modify;
    end;

    local procedure GetAmtToApplyCust(CustLedgEntry: Record "Cust. Ledger Entry"; GenJnlLine: Record "Gen. Journal Line"): Decimal
    begin
        if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(GenJnlLine, CustLedgEntry, 0, false) then
            if (CustLedgEntry."Amount to Apply" = 0) or
               (Abs(CustLedgEntry."Amount to Apply") >=
                Abs(CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible"))
            then
                exit(-CustLedgEntry."Remaining Amount" + CustLedgEntry."Remaining Pmt. Disc. Possible");
        if CustLedgEntry."Amount to Apply" = 0 then
            exit(-CustLedgEntry."Remaining Amount");
        exit(-CustLedgEntry."Amount to Apply");
    end;

    local procedure GetAmtToApplyVend(VendLedgEntry: Record "Vendor Ledger Entry"; GenJnlLine: Record "Gen. Journal Line"): Decimal
    begin
        if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(GenJnlLine, VendLedgEntry, 0, false) then
            if (VendLedgEntry."Amount to Apply" = 0) or
               (Abs(VendLedgEntry."Amount to Apply") >=
                Abs(VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible"))
            then
                exit(-VendLedgEntry."Remaining Amount" + VendLedgEntry."Remaining Pmt. Disc. Possible");
        if VendLedgEntry."Amount to Apply" = 0 then
            exit(-VendLedgEntry."Remaining Amount");
        exit(-VendLedgEntry."Amount to Apply");
    end;

    local procedure GetAmtToApplyEmpl(EmplLedgEntry: Record "Employee Ledger Entry"): Decimal
    begin
        if EmplLedgEntry."Amount to Apply" = 0 then
            exit(-EmplLedgEntry."Remaining Amount");
        exit(-EmplLedgEntry."Amount to Apply");
    end;

    local procedure SetAppliesToFiltersCust(var CustLedgEntry: Record "Cust. Ledger Entry"; GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20])
    begin
        CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        if AccNo <> '' then
            CustLedgEntry.SetRange("Customer No.", AccNo);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetRange("Currency Code", GenJnlLine."Currency Code");
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            CustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            CustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if not CustLedgEntry.FindFirst then begin
                CustLedgEntry.SetRange("Document Type");
                CustLedgEntry.SetRange("Document No.");
            end;
        end;
        if GenJnlLine."Applies-to ID" <> '' then begin
            CustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            if not CustLedgEntry.FindFirst then
                CustLedgEntry.SetRange("Applies-to ID");
        end;
        if GenJnlLine."Applies-to Doc. Type" <> GenJnlLine."Applies-to Doc. Type"::" " then begin
            CustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            if not CustLedgEntry.FindFirst then
                CustLedgEntry.SetRange("Document Type");
        end;
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            CustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if not CustLedgEntry.FindFirst then
                CustLedgEntry.SetRange("Document No.");
        end;
        if GenJnlLine.Amount <> 0 then begin
            CustLedgEntry.SetRange(Positive, GenJnlLine.Amount < 0);
            if CustLedgEntry.FindFirst then;
            CustLedgEntry.SetRange(Positive);
        end;
    end;

    local procedure SetAppliesToFiltersVend(var VendLedgEntry: Record "Vendor Ledger Entry"; GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20])
    begin
        VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        if AccNo <> '' then
            VendLedgEntry.SetRange("Vendor No.", AccNo);
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange("Currency Code", GenJnlLine."Currency Code");
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            VendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if not VendLedgEntry.FindFirst then begin
                VendLedgEntry.SetRange("Document Type");
                VendLedgEntry.SetRange("Document No.");
            end;
        end;
        if GenJnlLine."Applies-to ID" <> '' then begin
            VendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            if not VendLedgEntry.FindFirst then
                VendLedgEntry.SetRange("Applies-to ID");
        end;
        if GenJnlLine."Applies-to Doc. Type" <> GenJnlLine."Applies-to Doc. Type"::" " then begin
            VendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            if not VendLedgEntry.FindFirst then
                VendLedgEntry.SetRange("Document Type");
        end;
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if not VendLedgEntry.FindFirst then
                VendLedgEntry.SetRange("Document No.");
        end;
        if GenJnlLine.Amount <> 0 then begin
            VendLedgEntry.SetRange(Positive, GenJnlLine.Amount < 0);
            if VendLedgEntry.FindFirst then;
            VendLedgEntry.SetRange(Positive);
        end;
    end;

    local procedure SetAppliesToFiltersEmpl(var EmplLedgEntry: Record "Employee Ledger Entry"; GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20])
    begin
        EmplLedgEntry.SetCurrentKey("Employee No.", "Applies-to ID", Open, Positive);
        if AccNo <> '' then
            EmplLedgEntry.SetRange("Employee No.", AccNo);
        EmplLedgEntry.SetRange(Open, true);
        EmplLedgEntry.SetRange("Currency Code", GenJnlLine."Currency Code");
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            EmplLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            EmplLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if not EmplLedgEntry.FindFirst then begin
                EmplLedgEntry.SetRange("Document Type");
                EmplLedgEntry.SetRange("Document No.");
            end;
        end;
        if GenJnlLine."Applies-to ID" <> '' then begin
            EmplLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
            if not EmplLedgEntry.FindFirst then
                EmplLedgEntry.SetRange("Applies-to ID");
        end;
        if GenJnlLine."Applies-to Doc. Type" <> GenJnlLine."Applies-to Doc. Type"::" " then begin
            EmplLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
            if not EmplLedgEntry.FindFirst then
                EmplLedgEntry.SetRange("Document Type");
        end;
        if GenJnlLine."Applies-to Doc. No." <> '' then begin
            EmplLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            if not EmplLedgEntry.FindFirst then
                EmplLedgEntry.SetRange("Document No.");
        end;
        if GenJnlLine.Amount <> 0 then begin
            EmplLedgEntry.SetRange(Positive, GenJnlLine.Amount < 0);
            if EmplLedgEntry.FindFirst then;
            EmplLedgEntry.SetRange(Positive);
        end;
    end;

    local procedure LookupApplyCustEntry(var GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        ApplyCustEntries: Page "Apply Customer Entries";
    begin
        Clear(CustLedgEntry);
        SetAppliesToFiltersCust(CustLedgEntry, GenJnlLine, AccNo);
        ApplyCustEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyCustEntries.SetTableView(CustLedgEntry);
        ApplyCustEntries.SetRecord(CustLedgEntry);
        ApplyCustEntries.LookupMode(true);
        if ApplyCustEntries.RunModal = ACTION::LookupOK then begin
            ApplyCustEntries.GetRecord(CustLedgEntry);
            if GenJnlLine."Currency Code" <> CustLedgEntry."Currency Code" then
                if GenJnlLine.Amount = 0 then begin
                    if not
                       Confirm(
                         LookupConfirmQst, true,
                         GenJnlLine.FieldCaption("Currency Code"), GenJnlLine.TableCaption,
                         GenJnlLine.GetShowCurrencyCode(GenJnlLine."Currency Code"),
                         GenJnlLine.GetShowCurrencyCode(CustLedgEntry."Currency Code"))
                    then
                        Error(UpdateInteruptedErr);
                    GenJnlLine.Validate("Currency Code", CustLedgEntry."Currency Code");
                end else
                    GenJnlApply.CheckAgainstApplnCurrency(
                      GenJnlLine."Currency Code", CustLedgEntry."Currency Code",
                      GenJnlLine."Account Type"::Customer, true);
            if Amount = 0 then begin
                CustLedgEntry.CalcFields("Remaining Amount");
                GenJnlLine.Validate(Amount, GetAmtToApplyCust(CustLedgEntry, GenJnlLine));
            end;
            if AccNo = '' then
                GenJnlLine.Validate("Account No.", CustLedgEntry."Customer No.");
            GenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
            GenJnlLine."Applies-to Doc. No." := CustLedgEntry."Document No.";
            GenJnlLine."Applies-to ID" := '';
        end;
        Clear(ApplyCustEntries);
    end;

    local procedure LookupApplyVendEntry(var GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        ApplyVendEntries: Page "Apply Vendor Entries";
    begin
        Clear(VendLedgEntry);
        SetAppliesToFiltersVend(VendLedgEntry, GenJnlLine, AccNo);
        ApplyVendEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyVendEntries.SetTableView(VendLedgEntry);
        ApplyVendEntries.SetRecord(VendLedgEntry);
        ApplyVendEntries.LookupMode(true);
        if ApplyVendEntries.RunModal = ACTION::LookupOK then begin
            ApplyVendEntries.GetRecord(VendLedgEntry);
            if GenJnlLine."Currency Code" <> VendLedgEntry."Currency Code" then
                if GenJnlLine.Amount = 0 then begin
                    if not
                       Confirm(
                         LookupConfirmQst, true,
                         GenJnlLine.FieldCaption("Currency Code"), GenJnlLine.TableCaption,
                         GenJnlLine.GetShowCurrencyCode(GenJnlLine."Currency Code"),
                         GenJnlLine.GetShowCurrencyCode(VendLedgEntry."Currency Code"))
                    then
                        Error(UpdateInteruptedErr);
                    GenJnlLine.Validate("Currency Code", VendLedgEntry."Currency Code");
                end else
                    GenJnlApply.CheckAgainstApplnCurrency(
                      GenJnlLine."Currency Code", VendLedgEntry."Currency Code",
                      GenJnlLine."Account Type"::Vendor, true);
            if Amount = 0 then begin
                VendLedgEntry.CalcFields("Remaining Amount");
                GenJnlLine.Validate(Amount, GetAmtToApplyVend(VendLedgEntry, GenJnlLine));
            end;
            if AccNo = '' then
                GenJnlLine.Validate("Account No.", VendLedgEntry."Vendor No.");
            GenJnlLine."Applies-to Doc. Type" := VendLedgEntry."Document Type";
            GenJnlLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
            GenJnlLine."Applies-to ID" := '';
        end;
        Clear(ApplyVendEntries);
    end;

    local procedure LookupApplyEmplEntry(var GenJnlLine: Record "Gen. Journal Line"; AccNo: Code[20])
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        ApplyEmplEntries: Page "Apply Employee Entries";
    begin
        Clear(EmplLedgEntry);
        SetAppliesToFiltersEmpl(EmplLedgEntry, GenJnlLine, AccNo);
        ApplyEmplEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to Doc. No."));
        ApplyEmplEntries.SetTableView(EmplLedgEntry);
        ApplyEmplEntries.SetRecord(EmplLedgEntry);
        ApplyEmplEntries.LookupMode(true);
        if ApplyEmplEntries.RunModal = ACTION::LookupOK then begin
            ApplyEmplEntries.GetRecord(EmplLedgEntry);
            if GenJnlLine."Currency Code" <> EmplLedgEntry."Currency Code" then
                if GenJnlLine.Amount = 0 then begin
                    if not
                       Confirm(
                         LookupConfirmQst, true,
                         GenJnlLine.FieldCaption("Currency Code"), GenJnlLine.TableCaption,
                         GenJnlLine.GetShowCurrencyCode(GenJnlLine."Currency Code"),
                         GenJnlLine.GetShowCurrencyCode(EmplLedgEntry."Currency Code"))
                    then
                        Error(UpdateInteruptedErr);
                    GenJnlLine.Validate("Currency Code", EmplLedgEntry."Currency Code");
                end else
                    GenJnlApply.CheckAgainstApplnCurrency(
                      GenJnlLine."Currency Code", EmplLedgEntry."Currency Code",
                      GenJnlLine."Account Type"::Employee, true);
            if Amount = 0 then begin
                EmplLedgEntry.CalcFields("Remaining Amount");
                GenJnlLine.Validate(Amount, GetAmtToApplyEmpl(EmplLedgEntry));
            end;
            if AccNo = '' then
                GenJnlLine.Validate("Account No.", EmplLedgEntry."Employee No.");
            GenJnlLine."Applies-to Doc. Type" := EmplLedgEntry."Document Type";
            GenJnlLine."Applies-to Doc. No." := EmplLedgEntry."Document No.";
            GenJnlLine."Applies-to ID" := '';
        end;
        Clear(ApplyEmplEntries);
    end;

    [Scope('OnPrem')]
    procedure TypeToTableID(Type: Option " ","G/L Account",Customer,Vendor,"Bank Account","Fixed Asset",Employee): Integer
    begin
        case Type of
            Type::" ":
                exit(0);
            Type::"G/L Account":
                exit(DATABASE::"G/L Account");
            Type::Customer:
                exit(DATABASE::Customer);
            Type::Vendor:
                exit(DATABASE::Vendor);
            Type::"Bank Account":
                exit(DATABASE::"Bank Account");
            Type::"Fixed Asset":
                exit(DATABASE::"Fixed Asset");
            Type::Employee:
                exit(DATABASE::Employee);
        end;
    end;

    local procedure GetFAPostingGroup()
    var
        LocalGLAcc: Record "G/L Account";
        FAPostingGr: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
        FAExtPostingGr: Record "FA Extended Posting Group";
    begin
        if ("Account Type" <> "Account Type"::"Fixed Asset") or ("Account No." = '') then
            exit;
        if "Depreciation Book Code" = '' then begin
            FASetup.Get();
            FADeprBook.Reset();
            FADeprBook.SetRange("FA No.", "Account No.");
            FADeprBook.SetRange("Default FA Depreciation Book", true);
            if not FADeprBook.FindFirst then begin
                "Depreciation Book Code" := FASetup."Default Depr. Book";
                if not FADeprBook.Get("Account No.", "Depreciation Book Code") then
                    "Depreciation Book Code" := '';
            end else
                "Depreciation Book Code" := FADeprBook."Depreciation Book Code";
            if "Depreciation Book Code" = '' then
                exit;
        end;
        if "FA Posting Type" = "FA Posting Type"::" " then
            "FA Posting Type" := "FA Posting Type"::"Acquisition Cost";
        if "FA Posting Type" = "FA Posting Type"::"Acquisition Cost" then
            if FASetup.Get then
                if FASetup."FA Acquisition As Custom 2" then
                    "FA Posting Type" := "FA Posting Type"::"Custom 2";
        FADeprBook.Get("Account No.", "Depreciation Book Code");
        FADeprBook.TestField("FA Posting Group");
        FAPostingGr.Get(FADeprBook."FA Posting Group");
        if "FA Posting Type" = "FA Posting Type"::"Custom 2" then begin
            FAPostingGr.TestField("Custom 2 Account");
            LocalGLAcc.Get(FAPostingGr."Custom 2 Account");
        end else
            if "FA Posting Type" = "FA Posting Type"::"Acquisition Cost" then begin
                FAPostingGr.TestField("Acquisition Cost Account");
                LocalGLAcc.Get(FAPostingGr."Acquisition Cost Account");
            end else
                if FASetup."FA Maintenance By Maint. Code" then begin
                    FAExtPostingGr.Get(FADeprBook."FA Posting Group", 2, "Maintenance Code");
                    FAExtPostingGr.TestField("Maintenance Expense Account");
                    LocalGLAcc.Get(FAExtPostingGr."Maintenance Expense Account");
                end else begin
                    FAPostingGr.TestField("Maintenance Expense Account");
                    LocalGLAcc.Get(FAPostingGr."Maintenance Expense Account");
                end;
        LocalGLAcc.CheckGLAcc;
        LocalGLAcc.TestField("Gen. Prod. Posting Group");
        "Posting Group" := FADeprBook."FA Posting Group";
        Validate("Gen. Posting Type", LocalGLAcc."Gen. Posting Type");
        Validate("VAT Bus. Posting Group", LocalGLAcc."VAT Bus. Posting Group");
        Validate("VAT Prod. Posting Group", LocalGLAcc."VAT Prod. Posting Group");
    end;

    [Scope('OnPrem')]
    procedure ExtStatistics()
    var
        CashDocLine: Record "Cash Document Line";
    begin
        TestField("Cash Desk No.");
        TestField("Cash Document No.");

        GetDocHeader;
        if CashDocHeader.Status = CashDocHeader.Status::Open then begin
            CashDocHeader.VATRounding;
            Commit();
        end;

        CashDocLine.SetRange("Cash Desk No.", "Cash Desk No.");
        CashDocLine.SetRange("Cash Document No.", "Cash Document No.");
        CashDocLine.SetRange("Line No.", "Line No.");
        PAGE.RunModal(PAGE::"Cash Document Statistics", CashDocLine);
    end;

    [Scope('OnPrem')]
    procedure LinkToAdvLetter()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        TestField("Document Type", "Document Type"::Payment);
        TestField("Prepayment Type", "Prepayment Type"::Advance);
        if not ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) then
            FieldError("Account Type");

        GetDocHeader;
        GenJnlLine.Init();
        GenJnlLine."Line No." := "Line No.";
        GenJnlLine."Account No." := "Account No.";
        GenJnlLine."Document Type" := "Document Type";
        GenJnlLine."Document No." := "Cash Document No.";
        GenJnlLine."Currency Code" := CashDocHeader."Currency Code";
        GenJnlLine."Posting Date" := CashDocHeader."Posting Date";
        GenJnlLine."Posting Group" := "Posting Group";
        GenJnlLine.Prepayment := true;
        GenJnlLine."Prepayment Type" := "Prepayment Type";
        GenJnlLine."Advance Letter Link Code" := "Advance Letter Link Code";
        case "Account Type" of
            "Account Type"::Customer:
                begin
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
                    GenJnlLine.Amount := -Amount;
                end;
            "Account Type"::Vendor:
                begin
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                    GenJnlLine.Amount := Amount;
                end;
        end;
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Link Letters", GenJnlLine);

        if (GenJnlLine."Advance Letter Link Code" <> "Advance Letter Link Code") or
           (GenJnlLine."Posting Group" <> "Posting Group")
        then begin
            "Advance Letter Link Code" := GenJnlLine."Advance Letter Link Code";
            Validate("Posting Group", GenJnlLine."Posting Group");
            Modify;
        end;
    end;

    [Scope('OnPrem')]
    procedure LinkWholeLetter()
    var
        PrepmtLinksMgt: Codeunit "Prepayment Links Management";
    begin
        PrepmtLinksMgt.LinkCashDocLine(Rec);
    end;

    [Scope('OnPrem')]
    procedure UnLinkWholeLetter()
    var
        PrepmtLinksMgt: Codeunit "Prepayment Links Management";
    begin
        PrepmtLinksMgt.UnLinkCashDocLine(Rec);
    end;

    [Scope('OnPrem')]
    [Obsolete('The functionality of Non-deductible VAT will be removed and this function should not be used. (Obsolete::Removed in release 01.2021)', '15.3')]
    procedure GetVATDeduction(): Decimal
    var
        NonDeductVATSetup: Record "Non Deductible VAT Setup";
    begin
        GetDocHeader;
        if ((VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Normal VAT") or
            (VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT")) and
           VATPostingSetup."Allow Non Deductible VAT"
        then begin
            NonDeductVATSetup.Reset();
            NonDeductVATSetup.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            NonDeductVATSetup.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            NonDeductVATSetup.SetRange("From Date", 0D, CashDocHeader."VAT Date");
            if NonDeductVATSetup.FindLast then begin
                NonDeductVATSetup.TestField("Non Deductible VAT %");
                exit(NonDeductVATSetup."Non Deductible VAT %");
            end
        end;
        exit(0);
    end;

    [Scope('OnPrem')]
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure UpdateEETTransaction()
    var
        EETEntryMgt: Codeunit "EET Entry Management";
    begin
        if not "System-Created Entry" then begin
            GetDocHeader;
            "EET Transaction" := EETEntryMgt.IsEETTransaction(CashDocHeader, Rec);
        end;
    end;

    [Obsolete('The functionality of VAT Coefficient will be removed and this function should not be used. (Obsolete::Removed in release 01.2021', '15.3')]
    local procedure CalcVATCoefficient(): Decimal
    begin
        GLSetup.Get();
        if GLSetup."Round VAT Coeff." then
            exit(Round("VAT %" / (100 + "VAT %"), GLSetup."VAT Coeff. Rounding Precision"));
        exit("VAT %" / (100 + "VAT %"));
    end;

    local procedure CalcVATAmount(): Decimal
    begin
        GetDocHeader;
        if CashDocHeader."Amounts Including VAT" then
            exit(
              Round(
                "Amount Including VAT" * CalcVATCoefficient,
                Currency."Amount Rounding Precision", Currency.VATRoundingDirection));
        exit(
          Round(
            "VAT Base Amount" * "VAT %" / 100,
            Currency."Amount Rounding Precision", Currency.VATRoundingDirection));
    end;

    local procedure CalcVATAmountLCY(): Decimal
    begin
        GetDocHeader;
        if CashDocHeader."Amounts Including VAT" then
            exit(
              Round(
                "Amount Including VAT (LCY)" * CalcVATCoefficient,
                Currency."Amount Rounding Precision", Currency.VATRoundingDirection));
        exit(
          Round(
            "VAT Base Amount (LCY)" * "VAT %" / 100,
            Currency."Amount Rounding Precision", Currency.VATRoundingDirection));
    end;

    local procedure GetCashDeskEvent()
    begin
        if "Cash Desk Event" = '' then begin
            Clear(CashDeskEvent);
            exit;
        end;

        if "Cash Desk Event" <> CashDeskEvent.Code then
            CashDeskEvent.Get("Cash Desk Event");
    end;
}

