table 274 "Bank Acc. Reconciliation Line"
{
    Caption = 'Bank Acc. Reconciliation Line';
    Permissions = TableData "Data Exch. Field" = rimd;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."));
        }
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(5; "Transaction Date"; Date)
        {
            Caption = 'Transaction Date';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Statement Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            Caption = 'Statement Amount';

            trigger OnValidate()
            begin
                Difference := "Statement Amount" - "Applied Amount";
            end;
        }
        field(8; Difference; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Difference';

            trigger OnValidate()
            begin
                "Statement Amount" := "Applied Amount" + Difference;
            end;
        }
        field(9; "Applied Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Applied Amount';
            Editable = false;

            trigger OnValidate()
            begin
                Difference := "Statement Amount" - "Applied Amount";
            end;
        }
        field(10; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Bank Account Ledger Entry,Check Ledger Entry,Difference';
            OptionMembers = "Bank Account Ledger Entry","Check Ledger Entry",Difference;

            trigger OnValidate()
            begin
                if (Type <> xRec.Type) and
                   ("Applied Entries" <> 0)
                then
                    if Confirm(Text001, false) then begin
                        RemoveApplication(xRec.Type);
                        Validate("Applied Amount", 0);
                        "Applied Entries" := 0;
                        "Check No." := '';
                    end else
                        Error(Text002);
            end;
        }
        field(11; "Applied Entries"; Integer)
        {
            Caption = 'Applied Entries';
            Editable = false;

            trigger OnLookup()
            begin
                DisplayApplication;
            end;
        }
        field(12; "Value Date"; Date)
        {
            Caption = 'Value Date';
        }
        field(13; "Ready for Application"; Boolean)
        {
            Caption = 'Ready for Application';
        }
        field(14; "Check No."; Code[20])
        {
            Caption = 'Check No.';
        }
        field(15; "Related-Party Name"; Text[250])
        {
            Caption = 'Related-Party Name';
        }
        field(16; "Additional Transaction Info"; Text[100])
        {
            Caption = 'Additional Transaction Info';
        }
        field(17; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(18; "Data Exch. Line No."; Integer)
        {
            Caption = 'Data Exch. Line No.';
            Editable = false;
        }
        field(20; "Statement Type"; Option)
        {
            Caption = 'Statement Type';
            OptionCaption = 'Bank Reconciliation,Payment Application';
            OptionMembers = "Bank Reconciliation","Payment Application";
        }
        field(21; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';

            trigger OnValidate()
            begin
                TestField("Applied Amount", 0);
                if "Account Type" = "Account Type"::"IC Partner" then
                    if not ConfirmManagement.GetResponse(ICPartnerAccountTypeQst, false) then begin
                        "Account Type" := xRec."Account Type";
                        exit;
                    end;
                if "Account Type" <> xRec."Account Type" then
                    Validate("Account No.", '');
            end;
        }
        field(22; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account" WHERE("Account Type" = CONST(Posting),
                                                                                          Blocked = CONST(false))
            ELSE
            IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Account Type" = CONST("Fixed Asset")) "Fixed Asset"
            ELSE
            IF ("Account Type" = CONST("IC Partner")) "IC Partner";

            trigger OnValidate()
            begin
                TestField("Applied Amount", 0);
                CreateDim(
                  DimMgt.TypeToTableID1("Account Type"), "Account No.",
                  DATABASE::"Salesperson/Purchaser", GetSalepersonPurchaserCode);
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(23; "Transaction Text"; Text[140])
        {
            Caption = 'Transaction Text';

            trigger OnValidate()
            begin
                if ("Statement Type" = "Statement Type"::"Payment Application") or (Description = '') then
                    Description := CopyStr("Transaction Text", 1, MaxStrLen(Description));
            end;
        }
        field(24; "Related-Party Bank Acc. No."; Text[100])
        {
            Caption = 'Related-Party Bank Acc. No.';
        }
        field(25; "Related-Party Address"; Text[100])
        {
            Caption = 'Related-Party Address';
        }
        field(26; "Related-Party City"; Text[50])
        {
            Caption = 'Related-Party City';
        }
        field(27; "Payment Reference No."; Code[50])
        {
            Caption = 'Payment Reference';
        }
        field(31; "Shortcut Dimension 1 Code"; Code[20])
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
        field(32; "Shortcut Dimension 2 Code"; Code[20])
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
        field(50; "Match Confidence"; Option)
        {
            CalcFormula = Max ("Applied Payment Entry"."Match Confidence" WHERE("Statement Type" = FIELD("Statement Type"),
                                                                                "Bank Account No." = FIELD("Bank Account No."),
                                                                                "Statement No." = FIELD("Statement No."),
                                                                                "Statement Line No." = FIELD("Statement Line No.")));
            Caption = 'Match Confidence';
            Editable = false;
            FieldClass = FlowField;
            InitValue = "None";
            OptionCaption = 'None,Low,Medium,High,High - Text-to-Account Mapping,Manual,Accepted';
            OptionMembers = "None",Low,Medium,High,"High - Text-to-Account Mapping",Manual,Accepted;
        }
        field(51; "Match Quality"; Integer)
        {
            CalcFormula = Max ("Applied Payment Entry".Quality WHERE("Bank Account No." = FIELD("Bank Account No."),
                                                                     "Statement No." = FIELD("Statement No."),
                                                                     "Statement Line No." = FIELD("Statement Line No."),
                                                                     "Statement Type" = FIELD("Statement Type")));
            Caption = 'Match Quality';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Sorting Order"; Integer)
        {
            Caption = 'Sorting Order';
        }
        field(61; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
            Editable = false;
        }
        field(70; "Transaction ID"; Text[50])
        {
            Caption = 'Transaction ID';
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
        field(12400; "Operation Date"; Date)
        {
            Caption = 'Operation Date';
        }
        field(12401; "Sender Account No."; Code[20])
        {
            Caption = 'Sender Account No.';

            trigger OnValidate()
            begin
                CheckLineStatus;
                GetPaymentDirection;
                GetContractor;
            end;
        }
        field(12402; "Sender VAT Reg. No."; Text[20])
        {
            Caption = 'Sender VAT Reg. No.';

            trigger OnValidate()
            begin
                CheckLineStatus;
                GetPaymentDirection;
                GetContractor;
            end;
        }
        field(12403; "Sender Party Name"; Text[150])
        {
            Caption = 'Sender Party Name';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12404; "Sender BIC"; Code[9])
        {
            Caption = 'Sender BIC';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12405; "Sender Bank Name"; Text[150])
        {
            Caption = 'Sender Bank Name';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12406; "Sender Bank City"; Text[50])
        {
            Caption = 'Sender Bank City';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12407; "Sender Transit No."; Code[20])
        {
            Caption = 'Sender Transit No.';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12408; "Sender KPP"; Code[20])
        {
            Caption = 'Sender KPP';

            trigger OnValidate()
            begin
                CheckLineStatus;
                GetContractor;
            end;
        }
        field(12409; "Recipient Account No."; Code[20])
        {
            Caption = 'Recipient Account No.';

            trigger OnValidate()
            begin
                CheckLineStatus;
                GetPaymentDirection;
                GetContractor;
            end;
        }
        field(12410; "Recipient VAT Reg. No."; Text[20])
        {
            Caption = 'Recipient VAT Reg. No.';

            trigger OnValidate()
            begin
                CheckLineStatus;
                GetPaymentDirection;
                GetContractor;
            end;
        }
        field(12411; "Recipient Name"; Text[150])
        {
            Caption = 'Recipient Name';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12412; "Recipient BIC"; Code[9])
        {
            Caption = 'Recipient BIC';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12413; "Recipient Bank Name"; Text[150])
        {
            Caption = 'Recipient Bank Name';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12414; "Recipient Bank City"; Text[50])
        {
            Caption = 'Recipient Bank City';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12415; "Recipient Transit No."; Code[20])
        {
            Caption = 'Recipient Transit No.';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12416; "Recipient KPP"; Code[20])
        {
            Caption = 'Recipient KPP';

            trigger OnValidate()
            begin
                CheckLineStatus;
                GetContractor;
            end;
        }
        field(12417; "Status Parameter"; Option)
        {
            Caption = 'Status Parameter';
            OptionCaption = ' ,01-taxpayer (charges payer),02-tax agent,03-collector of taxes and charges,04-tax authority,05-service of officers of justice of Department of Justice of Russian Federation,06-participant of foreign-economic activity,07-tax authority,08-payer of other mandatory payments';
            OptionMembers = " ","01","02","03","04","05","06","07","08";

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12418; KBK; Code[20])
        {
            Caption = 'KBK';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12419; OKATO; Code[11])
        {
            Caption = 'OKATO';
            TableRelation = OKATO;

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12420; "Payment Reason Code"; Option)
        {
            Caption = 'Payment Reason Code';
            OptionCaption = ' ,0,TP-payments of current period,ZD-voluntary offset of debt for the pass tax period,TR-offset of debt by demand of tax authorities about tax payments,RS-offset of installment debt,OT-offset of deferred debt,VU-offset of deferred debt in connection with implementation of external management,PR-offset of debt suspended for penalty,AP-offset of debt via audit act,AR-offset of debt via executive act,BF,RT';
            OptionMembers = " ","0",TP,ZD,TR,RS,OT,VU,PR,AP,AR,BF,RT;

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12421; "Tax Period"; Code[10])
        {
            Caption = 'Tax Period';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12422; "Period Code"; Option)
        {
            Caption = 'Period Code';
            OptionCaption = ' ,0,D1-payment for the first decade of month,D2-payment for the second decade of month,D3-payment for the third decade of month,MH-monthly payments,QT-quarter payment,HY-half-year payments,YR-year payments';
            OptionMembers = " ","0",D1,D2,D3,MH,QT,HY,YR;

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12423; "Reason Document No."; Code[15])
        {
            Caption = 'Reason Document No.';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12424; "Reason Document Date"; Date)
        {
            Caption = 'Reason Document Date';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12425; "Reason Document Type"; Option)
        {
            Caption = 'Reason Document Type';
            OptionCaption = ' ,TR-Number of requirement about taxes payment from TA,RS-Number of decision about installment,OT-Number of decision about deferral,VU-Number of act of materials in court,PR-Number of decision about suspension of penalty,AP-Number of control act,AR-number of executive document';
            OptionMembers = " ",TR,RS,OT,VU,PR,AP,AR;

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12426; "Pay Type"; Option)
        {
            Caption = 'Pay Type';
            OptionCaption = ' ,0,NS-discharge of tax or charge,AV-advance payment or prepayment,PE-penalty fees payment,PC-interests payment,SA-tax sanctions according Tax Code RF,ASH-administrative penalties,ISH-other penalties,PL,GR,VZ';
            OptionMembers = " ","0",NS,AV,PE,PC,SA,ASH,ISH,PL,GR,VZ;

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12427; "Payment Method"; Option)
        {
            Caption = 'Payment Method';
            OptionCaption = ' ,Mail,Telegraph,Through Moscow,Clearing,Electronic';
            OptionMembers = " ",Mail,Telegraph,"Through Moscow",Clearing,Electronic;

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12428; "Payment Variant"; Code[10])
        {
            Caption = 'Payment Variant';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12429; "Payment Date"; Date)
        {
            Caption = 'Payment Date';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12430; "Payment Subsequence"; Code[10])
        {
            Caption = 'Payment Subsequence';

            trigger OnValidate()
            begin
                CheckLineStatus;
            end;
        }
        field(12431; "Line Status"; Option)
        {
            Caption = 'Line Status';
            Editable = false;
            OptionCaption = ' ,Imported,Contractor Undefined,Contractor Confirmed,Payment Order Found,Transferred to Gen. Journal,Posted';
            OptionMembers = " ",Imported,"Contractor Undefined","Contractor Confirmed","Payment Order Found","Transferred to Gen. Journal",Posted;
        }
        field(12432; "Payment Direction"; Option)
        {
            Caption = 'Payment Direction';
            Editable = false;
            OptionCaption = ' ,Incoming,Outgoing';
            OptionMembers = " ",Incoming,Outgoing;

            trigger OnValidate()
            begin
                Validate("Entity No.");
            end;
        }
        field(12433; "Entity Type"; Option)
        {
            Caption = 'Entity Type';
            OptionCaption = 'G/L Account,Customer,Vendor';
            OptionMembers = "G/L Account",Customer,Vendor;

            trigger OnValidate()
            begin
                CheckLineStatus;
                if "Entity Type" <> xRec."Entity Type" then begin
                    Validate("Entity No.", '');
                    if "Entity Type" = "Entity Type"::Customer then begin
                        if "Payment Direction" = "Payment Direction"::Incoming then
                            "Document Type" := "Document Type"::Payment;
                        if "Payment Direction" = "Payment Direction"::Outgoing then
                            "Document Type" := "Document Type"::Refund;
                    end;
                    if "Entity Type" = "Entity Type"::Vendor then begin
                        if "Payment Direction" = "Payment Direction"::Incoming then
                            "Document Type" := "Document Type"::Refund;
                        if "Payment Direction" = "Payment Direction"::Outgoing then
                            "Document Type" := "Document Type"::Payment;
                    end;
                end;
            end;
        }
        field(12434; "Entity No."; Code[20])
        {
            Caption = 'Entity No.';
            TableRelation = IF ("Entity Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("Entity Type" = CONST(Vendor)) Vendor."No."
            ELSE
            IF ("Entity Type" = CONST("G/L Account")) "G/L Account"."No.";

            trigger OnValidate()
            var
                Vend: Record Vendor;
                Cust: Record Customer;
                VendBankAcc: Record "Vendor Bank Account";
                CustBankAcc: Record "Customer Bank Account";
                BankAccountDetail: Record "Bank Account Details";
                BankAccountNo: Code[20];
                VATRegNo: Text[20];
                KPPCode: Code[20];
                ConfirmedEntityNo: Boolean;
            begin
                CheckLineStatus;
                if not ConfirmedEntityNo then
                    if "Entity No." <> '' then begin
                        BankAccountNo := '';
                        VATRegNo := '';
                        KPPCode := '';

                        case "Payment Direction" of
                            "Payment Direction"::Outgoing:
                                begin
                                    BankAccountNo := "Recipient Account No.";
                                    VATRegNo := "Recipient VAT Reg. No.";
                                    KPPCode := "Recipient KPP";
                                end;
                            "Payment Direction"::Incoming:
                                begin
                                    BankAccountNo := "Sender Account No.";
                                    VATRegNo := "Sender VAT Reg. No.";
                                    KPPCode := "Sender KPP";
                                end;
                        end;

                        case "Entity Type" of
                            "Entity Type"::Vendor:
                                begin
                                    Vend.Reset();
                                    Vend.SetRange("No.", "Entity No.");
                                    if VATRegNo <> '' then
                                        Vend.SetRange("VAT Registration No.", VATRegNo);
                                    if KPPCode <> '' then
                                        Vend.SetRange("KPP Code", KPPCode);
                                    if Vend.FindFirst then begin
                                        VendBankAcc.SetRange("Vendor No.", Vend."No.");
                                        VendBankAcc.SetRange("Bank Account No.", BankAccountNo);
                                        if VendBankAcc.FindLast then begin
                                            "Line Status" := "Line Status"::"Contractor Confirmed";
                                        end else
                                            IncorrectContractor;
                                    end else
                                        IncorrectContractor;
                                end;
                            "Entity Type"::Customer:
                                begin
                                    Cust.Reset();
                                    Cust.SetRange("No.", "Entity No.");
                                    if VATRegNo <> '' then
                                        Cust.SetRange("VAT Registration No.", VATRegNo);
                                    if KPPCode <> '' then
                                        Cust.SetRange("KPP Code", KPPCode);
                                    if Cust.FindFirst then begin
                                        CustBankAcc.SetRange("Customer No.", Cust."No.");
                                        CustBankAcc.SetRange("Bank Account No.", BankAccountNo);
                                        if CustBankAcc.FindLast then begin
                                            "Line Status" := "Line Status"::"Contractor Confirmed";
                                        end else
                                            IncorrectContractor;
                                    end else
                                        IncorrectContractor;
                                end;
                            "Entity Type"::"G/L Account":
                                begin
                                    BankAccountDetail.SetRange("G/L Account", "Entity No.");
                                    BankAccountDetail.SetRange("Bank Account No.", BankAccountNo);
                                    if VATRegNo <> '' then
                                        BankAccountDetail.SetRange("VAT Registration No.", VATRegNo);
                                    if KPPCode <> '' then
                                        BankAccountDetail.SetRange("KPP Code", KPPCode);
                                    if BankAccountDetail.FindFirst then begin
                                        "Document Type" := BankAccountDetail."Document Type";
                                        "Line Status" := "Line Status"::"Contractor Confirmed";
                                    end else
                                        IncorrectContractor;
                                end;
                        end;
                    end else
                        if "Line Status" = "Line Status"::"Contractor Confirmed" then begin
                            "Line Status" := "Line Status"::Imported;
                        end;

                if "Entity No." <> xRec."Entity No." then
                    CalculateDebitCreditAmount;
            end;
        }
        field(12435; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Editable = false;
            OptionCaption = ' ,Payment,Refund';
            OptionMembers = " ",Payment,Refund;
        }
        field(12436; "Debit Amount"; Decimal)
        {
            Caption = 'Debit Amount';
        }
        field(12437; "Credit Amount"; Decimal)
        {
            Caption = 'Credit Amount';
        }
        field(12438; "Payment Code"; Text[20])
        {
            Caption = 'Payment Code';
        }
    }

    keys
    {
        key(Key1; "Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Account Type", "Statement Amount")
        {
        }
        key(Key3; Type, "Applied Amount")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        RemoveApplication(Type);
        ClearDataExchEntries;
        RemoveAppliedPaymentEntries;
        DeletePaymentMatchingDetails;
        UpdateParentLineStatementAmount;
        if Find then;
    end;

    trigger OnInsert()
    begin
        BankAccRecon.Get("Statement Type", "Bank Account No.", "Statement No.");
        "Applied Entries" := 0;
        Validate("Applied Amount", 0);
    end;

    trigger OnModify()
    begin
        if xRec."Statement Amount" <> "Statement Amount" then
            RemoveApplication(Type);
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'Delete application?';
        Text002: Label 'Update canceled.';
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccSetStmtNo: Codeunit "Bank Acc. Entry Set Recon.-No.";
        CheckSetStmtNo: Codeunit "Check Entry Set Recon.-No.";
        DimMgt: Codeunit DimensionManagement;
        ConfirmManagement: Codeunit "Confirm Management";
        AmountWithinToleranceRangeTok: Label '>=%1&<=%2', Locked = true;
        AmountOustideToleranceRangeTok: Label '<%1|>%2', Locked = true;
        TransactionAmountMustNotBeZeroErr: Label 'The Transaction Amount field must have a value that is not 0.';
        CreditTheAccountQst: Label 'The remaining amount to apply is %2.\\Do you want to create a new payment application line that will debit or credit %1 with the remaining amount when you post the payment?', Comment = '%1 is the account name, %2 is the amount that is not applied (there is filed on the page named Remaining Amount To Apply)';
        ExcessiveAmountErr: Label 'The remaining amount to apply is %1.', Comment = '%1 is the amount that is not applied (there is filed on the page named Remaining Amount To Apply)';
        ImportPostedTransactionsQst: Label 'The bank statement contains payments that are already applied, but the related bank account ledger entries are not closed.\\Do you want to include these payments in the import?';
        ICPartnerAccountTypeQst: Label 'The resulting entry will be of type IC Transaction, but no Intercompany Outbox transaction will be created. \\Do you want to use the IC Partner account type anyway?';

    procedure DisplayApplication()
    var
        PaymentApplication: Page "Payment Application";
    begin
        case "Statement Type" of
            "Statement Type"::"Bank Reconciliation":
                case Type of
                    Type::"Bank Account Ledger Entry":
                        begin
                            BankAccLedgEntry.Reset();
                            BankAccLedgEntry.SetCurrentKey("Bank Account No.", Open);
                            BankAccLedgEntry.SetRange("Bank Account No.", "Bank Account No.");
                            BankAccLedgEntry.SetRange(Open, true);
                            BankAccLedgEntry.SetRange(
                              "Statement Status", BankAccLedgEntry."Statement Status"::"Bank Acc. Entry Applied");
                            BankAccLedgEntry.SetRange("Statement No.", "Statement No.");
                            BankAccLedgEntry.SetRange("Statement Line No.", "Statement Line No.");
                            PAGE.Run(0, BankAccLedgEntry);
                        end;
                    Type::"Check Ledger Entry":
                        begin
                            CheckLedgEntry.Reset();
                            CheckLedgEntry.SetCurrentKey("Bank Account No.", Open);
                            CheckLedgEntry.SetRange("Bank Account No.", "Bank Account No.");
                            CheckLedgEntry.SetRange(Open, true);
                            CheckLedgEntry.SetRange(
                              "Statement Status", CheckLedgEntry."Statement Status"::"Check Entry Applied");
                            CheckLedgEntry.SetRange("Statement No.", "Statement No.");
                            CheckLedgEntry.SetRange("Statement Line No.", "Statement Line No.");
                            PAGE.Run(0, CheckLedgEntry);
                        end;
                end;
            "Statement Type"::"Payment Application":
                begin
                    if "Statement Amount" = 0 then
                        Error(TransactionAmountMustNotBeZeroErr);
                    PaymentApplication.SetBankAccReconcLine(Rec);
                    PaymentApplication.RunModal;
                end;
        end;
    end;

    procedure GetCurrencyCode(): Code[10]
    var
        BankAcc: Record "Bank Account";
    begin
        if "Bank Account No." = BankAcc."No." then
            exit(BankAcc."Currency Code");

        if BankAcc.Get("Bank Account No.") then
            exit(BankAcc."Currency Code");

        exit('');
    end;

    procedure GetStyle(): Text
    begin
        if "Applied Entries" <> 0 then
            exit('Favorable');

        exit('');
    end;

    procedure ClearDataExchEntries()
    var
        DataExchField: Record "Data Exch. Field";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        DataExchField.DeleteRelatedRecords("Data Exch. Entry No.", "Data Exch. Line No.");

        BankAccReconciliationLine.SetRange("Statement Type", "Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", "Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", "Statement No.");
        BankAccReconciliationLine.SetRange("Data Exch. Entry No.", "Data Exch. Entry No.");
        BankAccReconciliationLine.SetFilter("Statement Line No.", '<>%1', "Statement Line No.");
        if BankAccReconciliationLine.IsEmpty then
            DataExchField.DeleteRelatedRecords("Data Exch. Entry No.", 0);
    end;

    local procedure GetContractor(): Boolean
    var
        VendBankAcc: Record "Vendor Bank Account";
        Vend: Record Vendor;
        CustBankAcc: Record "Customer Bank Account";
        Cust: Record Customer;
        BankAccountDetail: Record "Bank Account Details";
        VendorFound: Boolean;
        CustomerFound: Boolean;
        GLAccountFound: Boolean;
        BankAccountNo: Code[20];
        VATRegNo: Text[20];
        KPPCode: Code[20];
        ConfirmedEntityNo: Boolean;
    begin
        ConfirmedEntityNo := false;

        BankAccountNo := '';
        VATRegNo := '';
        KPPCode := '';
        VendorFound := false;
        CustomerFound := false;
        GLAccountFound := false;

        case "Payment Direction" of
            "Payment Direction"::Outgoing:
                begin
                    BankAccountNo := "Recipient Account No.";
                    VATRegNo := "Recipient VAT Reg. No.";
                    KPPCode := "Recipient KPP";
                end;
            "Payment Direction"::Incoming:
                begin
                    BankAccountNo := "Sender Account No.";
                    VATRegNo := "Sender VAT Reg. No.";
                    KPPCode := "Sender KPP";
                end;
        end;

        if "Payment Direction" <> "Payment Direction"::" " then begin
            VendBankAcc.Reset();
            VendBankAcc.SetCurrentKey("Bank Account No.");
            VendBankAcc.SetRange("Bank Account No.", BankAccountNo);
            if VendBankAcc.FindSet then
                repeat
                    Vend.Reset();
                    Vend.SetRange("No.", VendBankAcc."Vendor No.");
                    if VATRegNo <> '' then
                        Vend.SetRange("VAT Registration No.", VATRegNo);
                    if KPPCode <> '' then
                        Vend.SetRange("KPP Code", KPPCode);
                    VendorFound := Vend.FindFirst;
                until (VendBankAcc.Next = 0) or VendorFound;

            CustBankAcc.Reset();
            CustBankAcc.SetCurrentKey("Bank Account No.");
            CustBankAcc.SetRange("Bank Account No.", BankAccountNo);
            if CustBankAcc.FindSet then
                repeat
                    Cust.Reset();
                    Cust.SetRange("No.", CustBankAcc."Customer No.");
                    if VATRegNo <> '' then
                        Cust.SetRange("VAT Registration No.", VATRegNo);
                    if KPPCode <> '' then
                        Cust.SetRange("KPP Code", KPPCode);
                    CustomerFound := Cust.FindFirst;
                until (CustBankAcc.Next = 0) or CustomerFound;

            BankAccountDetail.Reset();
            BankAccountDetail.SetRange("Bank Account No.", BankAccountNo);
            if VATRegNo <> '' then
                BankAccountDetail.SetRange("VAT Registration No.", VATRegNo);
            if KPPCode <> '' then
                BankAccountDetail.SetRange("KPP Code", KPPCode);
            GLAccountFound := BankAccountDetail.FindFirst;
        end;

        if (VendorFound and CustomerFound) or (VendorFound and GLAccountFound) or (GLAccountFound and CustomerFound) then begin
            Validate("Entity No.", '');
            "Line Status" := "Line Status"::"Contractor Undefined";
            "Entity Type" := "Entity Type"::"G/L Account";
            exit(false);
        end;

        if VendorFound then begin
            ConfirmedEntityNo := true;
            "Entity Type" := "Entity Type"::Vendor;
            Validate("Entity No.", Vend."No.");
            "Line Status" := "Line Status"::"Contractor Confirmed";
            if "Payment Direction" = "Payment Direction"::Outgoing then
                "Document Type" := "Document Type"::Payment
            else
                "Document Type" := "Document Type"::Refund;
            exit(true);
        end;

        if CustomerFound then begin
            ConfirmedEntityNo := true;
            "Entity Type" := "Entity Type"::Customer;
            Validate("Entity No.", Cust."No.");
            "Line Status" := "Line Status"::"Contractor Confirmed";
            if "Payment Direction" = "Payment Direction"::Incoming then
                "Document Type" := "Document Type"::Payment
            else
                "Document Type" := "Document Type"::Refund;
            exit(true);
        end;

        if GLAccountFound then begin
            ConfirmedEntityNo := true;
            "Entity Type" := "Entity Type"::"G/L Account";
            Validate("Entity No.", BankAccountDetail."G/L Account");
            "Line Status" := "Line Status"::"Contractor Confirmed";
            "Document Type" := BankAccountDetail."Document Type";
            exit(true);
        end;

        "Line Status" := "Line Status"::Imported;
        "Entity Type" := "Entity Type"::"G/L Account";
        Validate("Entity No.", '');
    end;

    local procedure IncorrectContractor()
    begin
        "Line Status" := "Line Status"::Imported;
        "Entity Type" := 0;
        "Entity No." := '';
        "Document Type" := "Document Type"::" ";
    end;

    [Scope('OnPrem')]
    procedure CalculateDebitCreditAmount()
    begin
        if ("Payment Direction" <> "Payment Direction"::" ") and ("Entity No." <> '') then begin
            if "Payment Direction" = "Payment Direction"::Outgoing then begin
                if ("Document Type" = "Document Type"::Refund) and ("Entity Type" = "Entity Type"::"G/L Account") then begin
                    Validate("Debit Amount", "Statement Amount");
                    Validate("Credit Amount", 0);
                end else begin
                    Validate("Debit Amount", 0);
                    Validate("Credit Amount", "Statement Amount");
                end;
            end else begin
                if ("Document Type" = "Document Type"::Refund) and ("Entity Type" = "Entity Type"::"G/L Account") then begin
                    Validate("Debit Amount", 0);
                    Validate("Credit Amount", "Statement Amount");
                end else begin
                    Validate("Debit Amount", "Statement Amount");
                    Validate("Credit Amount", 0);
                end;
            end;
        end else begin
            Validate("Debit Amount", 0);
            Validate("Credit Amount", 0);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPaymentDirection()
    var
        CompanyInfo: Record "Company Information";
        BankAcc: Record "Bank Account";
    begin
        CompanyInfo.Get();
        BankAcc.Get("Bank Account No.");
        if ("Sender VAT Reg. No." = CompanyInfo."VAT Registration No.") and
           ("Sender Account No." = BankAcc."Bank Account No.")
        then
            "Payment Direction" := "Payment Direction"::Outgoing
        else
            if ("Recipient VAT Reg. No." = CompanyInfo."VAT Registration No.") and
               ("Recipient Account No." = BankAcc."Bank Account No.")
            then
                "Payment Direction" := "Payment Direction"::Incoming
            else
                "Payment Direction" := "Payment Direction"::" ";
    end;

    [Scope('OnPrem')]
    procedure CheckLineStatus()
    begin
        if "Line Status" in ["Line Status"::"Payment Order Found" .. "Line Status"::Posted] then
            FieldError("Line Status");
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption, "Statement No.", "Statement Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        SourceCodeSetup.Get();
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        BankAccReconciliation.Get("Statement Type", "Bank Account No.", "Statement No.");
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, SourceCodeSetup."Payment Reconciliation Journal",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", BankAccReconciliation."Dimension Set ID", DATABASE::"Bank Account");
    end;

    procedure SetUpNewLine()
    begin
        "Transaction Date" := WorkDate;
        "Match Confidence" := "Match Confidence"::None;
        "Document No." := '';
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure AcceptAppliedPaymentEntriesSelectedLines()
    begin
        if FindSet then
            repeat
                AcceptApplication;
            until Next = 0;
    end;

    procedure RejectAppliedPaymentEntriesSelectedLines()
    begin
        if FindSet then
            repeat
                RejectAppliedPayment;
            until Next = 0;
    end;

    procedure RejectAppliedPayment()
    begin
        RemoveAppliedPaymentEntries;
        DeletePaymentMatchingDetails;
    end;

    procedure AcceptApplication()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        // For customer payments, the applied amount is positive, so positive difference means excessive amount.
        // For vendor payments, the applied amount is negative, so negative difference means excessive amount.
        // If "Applied Amount" and Difference have the same sign, then this is an overpayment situation.
        // Two non-zero numbers have the same sign if and only if their product is a positive number.
        if Difference * "Applied Amount" > 0 then begin
            if "Account Type" = "Account Type"::"Bank Account" then
                Error(ExcessiveAmountErr, Difference);
            SetAppliedPaymentEntryFromRec(AppliedPaymentEntry);
            if not AppliedPaymentEntry.Find then begin
                if not Confirm(StrSubstNo(CreditTheAccountQst, GetAppliedToName, Difference)) then
                    exit;
                TransferRemainingAmountToAccount;
            end;
        end;

        AppliedPaymentEntry.FilterAppliedPmtEntry(Rec);
        AppliedPaymentEntry.ModifyAll("Match Confidence", "Match Confidence"::Accepted);
    end;

    local procedure RemoveApplication(AppliedType: Option)
    begin
        if "Statement Type" = "Statement Type"::"Bank Reconciliation" then
            case AppliedType of
                Type::"Bank Account Ledger Entry":
                    begin
                        BankAccLedgEntry.Reset();
                        BankAccLedgEntry.SetCurrentKey("Bank Account No.", Open);
                        BankAccLedgEntry.SetRange("Bank Account No.", "Bank Account No.");
                        BankAccLedgEntry.SetRange(Open, true);
                        BankAccLedgEntry.SetRange(
                          "Statement Status", BankAccLedgEntry."Statement Status"::"Bank Acc. Entry Applied");
                        BankAccLedgEntry.SetRange("Statement No.", "Statement No.");
                        BankAccLedgEntry.SetRange("Statement Line No.", "Statement Line No.");
                        BankAccLedgEntry.LockTable();
                        CheckLedgEntry.LockTable();
                        if BankAccLedgEntry.Find('-') then
                            repeat
                                BankAccSetStmtNo.RemoveReconNo(BankAccLedgEntry, Rec, true);
                            until BankAccLedgEntry.Next = 0;
                        "Applied Entries" := 0;
                        Validate("Applied Amount", 0);
                        Modify;
                    end;
                Type::"Check Ledger Entry":
                    begin
                        CheckLedgEntry.Reset();
                        CheckLedgEntry.SetCurrentKey("Bank Account No.", Open);
                        CheckLedgEntry.SetRange("Bank Account No.", "Bank Account No.");
                        CheckLedgEntry.SetRange(Open, true);
                        CheckLedgEntry.SetRange(
                          "Statement Status", CheckLedgEntry."Statement Status"::"Check Entry Applied");
                        CheckLedgEntry.SetRange("Statement No.", "Statement No.");
                        CheckLedgEntry.SetRange("Statement Line No.", "Statement Line No.");
                        BankAccLedgEntry.LockTable();
                        CheckLedgEntry.LockTable();
                        if CheckLedgEntry.Find('-') then
                            repeat
                                CheckSetStmtNo.RemoveReconNo(CheckLedgEntry, Rec, true);
                            until CheckLedgEntry.Next = 0;
                        "Applied Entries" := 0;
                        Validate("Applied Amount", 0);
                        "Check No." := '';
                        Modify;
                    end;
            end;
    end;

    procedure SetManualApplication()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.FilterAppliedPmtEntry(Rec);
        AppliedPaymentEntry.ModifyAll("Match Confidence", "Match Confidence"::Manual)
    end;

    local procedure RemoveAppliedPaymentEntries()
    var
        AppliedPmtEntry: Record "Applied Payment Entry";
    begin
        Validate("Applied Amount", 0);
        Validate("Applied Entries", 0);
        Validate("Account No.", '');
        Modify(true);

        AppliedPmtEntry.FilterAppliedPmtEntry(Rec);
        AppliedPmtEntry.DeleteAll(true);
    end;

    local procedure DeletePaymentMatchingDetails()
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
    begin
        PaymentMatchingDetails.SetRange("Statement Type", "Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", "Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", "Statement No.");
        PaymentMatchingDetails.SetRange("Statement Line No.", "Statement Line No.");
        PaymentMatchingDetails.DeleteAll(true);
    end;

    procedure GetAppliedEntryAccountName(AppliedToEntryNo: Integer): Text
    var
        AccountType: Option;
        AccountNo: Code[20];
    begin
        AccountType := GetAppliedEntryAccountType(AppliedToEntryNo);
        AccountNo := GetAppliedEntryAccountNo(AppliedToEntryNo);
        exit(GetAccountName(AccountType, AccountNo));
    end;

    procedure GetAppliedToName(): Text
    var
        AccountType: Option;
        AccountNo: Code[20];
    begin
        AccountType := GetAppliedToAccountType;
        AccountNo := GetAppliedToAccountNo;
        exit(GetAccountName(AccountType, AccountNo));
    end;

    procedure GetAppliedEntryAccountType(AppliedToEntryNo: Integer): Integer
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if "Account Type" = "Account Type"::"Bank Account" then
            if BankAccountLedgerEntry.Get(AppliedToEntryNo) then
                exit(BankAccountLedgerEntry."Bal. Account Type");
        exit("Account Type");
    end;

    procedure GetAppliedToAccountType(): Integer
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if "Account Type" = "Account Type"::"Bank Account" then
            if BankAccountLedgerEntry.Get(GetFirstAppliedToEntryNo) then
                exit(BankAccountLedgerEntry."Bal. Account Type");
        exit("Account Type");
    end;

    procedure GetAppliedEntryAccountNo(AppliedToEntryNo: Integer): Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        case "Account Type" of
            "Account Type"::Customer:
                if CustLedgerEntry.Get(AppliedToEntryNo) then
                    exit(CustLedgerEntry."Customer No.");
            "Account Type"::Vendor:
                if VendorLedgerEntry.Get(AppliedToEntryNo) then
                    exit(VendorLedgerEntry."Vendor No.");
            "Account Type"::"Bank Account":
                if BankAccountLedgerEntry.Get(AppliedToEntryNo) then
                    exit(BankAccountLedgerEntry."Bal. Account No.");
        end;
        exit("Account No.");
    end;

    procedure GetAppliedToAccountNo(): Code[20]
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if "Account Type" = "Account Type"::"Bank Account" then
            if BankAccountLedgerEntry.Get(GetFirstAppliedToEntryNo) then
                exit(BankAccountLedgerEntry."Bal. Account No.");
        exit("Account No.")
    end;

    local procedure GetAccountName(AccountType: Option; AccountNo: Code[20]): Text
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        Name: Text;
    begin
        case AccountType of
            "Account Type"::Customer:
                if Customer.Get(AccountNo) then
                    Name := Customer.Name;
            "Account Type"::Vendor:
                if Vendor.Get(AccountNo) then
                    Name := Vendor.Name;
            "Account Type"::"G/L Account":
                if GLAccount.Get(AccountNo) then
                    Name := GLAccount.Name;
            "Account Type"::"Bank Account":
                if BankAccount.Get(AccountNo) then
                    Name := BankAccount.Name;
        end;

        exit(Name);
    end;

    local procedure SetAppliedPaymentEntryFromRec(var AppliedPaymentEntry: Record "Applied Payment Entry")
    begin
        AppliedPaymentEntry.TransferFromBankAccReconLine(Rec);
        AppliedPaymentEntry."Account Type" := GetAppliedToAccountType;
        AppliedPaymentEntry."Account No." := GetAppliedToAccountNo;
    end;

    procedure AppliedEntryAccountDrillDown(AppliedEntryNo: Integer)
    var
        AccountType: Option;
        AccountNo: Code[20];
    begin
        AccountType := GetAppliedEntryAccountType(AppliedEntryNo);
        AccountNo := GetAppliedEntryAccountNo(AppliedEntryNo);
        OpenAccountPage(AccountType, AccountNo);
    end;

    procedure AppliedToDrillDown()
    var
        AccountType: Option;
        AccountNo: Code[20];
    begin
        AccountType := GetAppliedToAccountType;
        AccountNo := GetAppliedToAccountNo;
        OpenAccountPage(AccountType, AccountNo);
    end;

    local procedure OpenAccountPage(AccountType: Option; AccountNo: Code[20])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
    begin
        case AccountType of
            "Account Type"::Customer:
                begin
                    Customer.Get(AccountNo);
                    PAGE.Run(PAGE::"Customer Card", Customer);
                end;
            "Account Type"::Vendor:
                begin
                    Vendor.Get(AccountNo);
                    PAGE.Run(PAGE::"Vendor Card", Vendor);
                end;
            "Account Type"::"G/L Account":
                begin
                    GLAccount.Get(AccountNo);
                    PAGE.Run(PAGE::"G/L Account Card", GLAccount);
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAccount.Get(AccountNo);
                    PAGE.Run(PAGE::"Bank Account Card", BankAccount);
                end;
        end;
    end;

    procedure DrillDownOnNoOfLedgerEntriesWithinAmountTolerance()
    begin
        DrillDownOnNoOfLedgerEntriesBasedOnAmount(AmountWithinToleranceRangeTok);
    end;

    procedure DrillDownOnNoOfLedgerEntriesOutsideOfAmountTolerance()
    begin
        DrillDownOnNoOfLedgerEntriesBasedOnAmount(AmountOustideToleranceRangeTok);
    end;

    local procedure DrillDownOnNoOfLedgerEntriesBasedOnAmount(AmountFilter: Text)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        MinAmount: Decimal;
        MaxAmount: Decimal;
    begin
        GetAmountRangeForTolerance(MinAmount, MaxAmount);

        case "Account Type" of
            "Account Type"::Customer:
                begin
                    GetCustomerLedgerEntriesInAmountRange(CustLedgerEntry, "Account No.", AmountFilter, MinAmount, MaxAmount);
                    PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgerEntry);
                end;
            "Account Type"::Vendor:
                begin
                    GetVendorLedgerEntriesInAmountRange(VendorLedgerEntry, "Account No.", AmountFilter, MinAmount, MaxAmount);
                    PAGE.Run(PAGE::"Vendor Ledger Entries", VendorLedgerEntry);
                end;
            "Account Type"::"Bank Account":
                begin
                    GetBankAccountLedgerEntriesInAmountRange(BankAccountLedgerEntry, AmountFilter, MinAmount, MaxAmount);
                    PAGE.Run(PAGE::"Bank Account Ledger Entries", BankAccountLedgerEntry);
                end;
        end;
    end;

    local procedure GetCustomerLedgerEntriesInAmountRange(var CustLedgerEntry: Record "Cust. Ledger Entry"; AccountNo: Code[20]; AmountFilter: Text; MinAmount: Decimal; MaxAmount: Decimal): Integer
    var
        BankAccount: Record "Bank Account";
    begin
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        BankAccount.Get("Bank Account No.");
        GetApplicableCustomerLedgerEntries(CustLedgerEntry, BankAccount."Currency Code", AccountNo);

        if BankAccount.IsInLocalCurrency then
            CustLedgerEntry.SetFilter("Remaining Amt. (LCY)", AmountFilter, MinAmount, MaxAmount)
        else
            CustLedgerEntry.SetFilter("Remaining Amount", AmountFilter, MinAmount, MaxAmount);

        exit(CustLedgerEntry.Count);
    end;

    local procedure GetVendorLedgerEntriesInAmountRange(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AccountNo: Code[20]; AmountFilter: Text; MinAmount: Decimal; MaxAmount: Decimal): Integer
    var
        BankAccount: Record "Bank Account";
    begin
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount", "Remaining Amt. (LCY)");

        BankAccount.Get("Bank Account No.");
        GetApplicableVendorLedgerEntries(VendorLedgerEntry, BankAccount."Currency Code", AccountNo);

        if BankAccount.IsInLocalCurrency then
            VendorLedgerEntry.SetFilter("Remaining Amt. (LCY)", AmountFilter, MinAmount, MaxAmount)
        else
            VendorLedgerEntry.SetFilter("Remaining Amount", AmountFilter, MinAmount, MaxAmount);

        exit(VendorLedgerEntry.Count);
    end;

    local procedure GetBankAccountLedgerEntriesInAmountRange(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; AmountFilter: Text; MinAmount: Decimal; MaxAmount: Decimal): Integer
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get("Bank Account No.");
        GetApplicableBankAccountLedgerEntries(BankAccountLedgerEntry, BankAccount."Currency Code", "Bank Account No.");

        BankAccountLedgerEntry.SetFilter("Remaining Amount", AmountFilter, MinAmount, MaxAmount);

        exit(BankAccountLedgerEntry.Count);
    end;

    local procedure GetApplicableCustomerLedgerEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; AccountNo: Code[20])
    begin
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetRange("Applies-to ID", '');
        CustLedgerEntry.SetFilter("Document Type", '<>%1&<>%2',
          CustLedgerEntry."Document Type"::Payment,
          CustLedgerEntry."Document Type"::Refund);

        if CurrencyCode <> '' then
            CustLedgerEntry.SetRange("Currency Code", CurrencyCode);

        if AccountNo <> '' then
            CustLedgerEntry.SetFilter("Customer No.", AccountNo);
    end;

    local procedure GetApplicableVendorLedgerEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10]; AccountNo: Code[20])
    begin
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetRange("Applies-to ID", '');
        VendorLedgerEntry.SetFilter("Document Type", '<>%1&<>%2',
          VendorLedgerEntry."Document Type"::Payment,
          VendorLedgerEntry."Document Type"::Refund);

        if CurrencyCode <> '' then
            VendorLedgerEntry.SetRange("Currency Code", CurrencyCode);

        if AccountNo <> '' then
            VendorLedgerEntry.SetFilter("Vendor No.", AccountNo);
    end;

    local procedure GetApplicableBankAccountLedgerEntries(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; CurrencyCode: Code[10]; AccountNo: Code[20])
    begin
        BankAccountLedgerEntry.SetRange(Open, true);

        if CurrencyCode <> '' then
            BankAccountLedgerEntry.SetRange("Currency Code", CurrencyCode);

        if AccountNo <> '' then
            BankAccountLedgerEntry.SetRange("Bank Account No.", AccountNo);
    end;

    procedure FilterBankRecLines(BankAccRecon: Record "Bank Acc. Reconciliation")
    begin
        Reset;
        SetRange("Statement Type", BankAccRecon."Statement Type");
        SetRange("Bank Account No.", BankAccRecon."Bank Account No.");
        SetRange("Statement No.", BankAccRecon."Statement No.");
    end;

    procedure LinesExist(BankAccRecon: Record "Bank Acc. Reconciliation"): Boolean
    begin
        FilterBankRecLines(BankAccRecon);
        exit(FindSet);
    end;

    procedure GetAppliedToDocumentNo(): Text
    var
        ApplyType: Option "Document No.","Entry No.";
    begin
        exit(GetAppliedNo(ApplyType::"Document No."));
    end;

    procedure GetAppliedToEntryNo(): Text
    var
        ApplyType: Option "Document No.","Entry No.";
    begin
        exit(GetAppliedNo(ApplyType::"Entry No."));
    end;

    local procedure GetFirstAppliedToEntryNo(): Integer
    var
        AppliedEntryNumbers: Text;
        AppliedToEntryNo: Integer;
    begin
        AppliedEntryNumbers := GetAppliedToEntryNo;
        if AppliedEntryNumbers = '' then
            exit(0);
        Evaluate(AppliedToEntryNo, SelectStr(1, AppliedEntryNumbers));
        exit(AppliedToEntryNo);
    end;

    local procedure GetAppliedNo(ApplyType: Option "Document No.","Entry No."): Text
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        AppliedNumbers: Text;
    begin
        AppliedPaymentEntry.SetRange("Statement Type", "Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", "Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", "Statement No.");
        AppliedPaymentEntry.SetRange("Statement Line No.", "Statement Line No.");

        AppliedNumbers := '';
        if AppliedPaymentEntry.FindSet then begin
            repeat
                if ApplyType = ApplyType::"Document No." then begin
                    if AppliedPaymentEntry."Document No." <> '' then
                        if AppliedNumbers = '' then
                            AppliedNumbers := AppliedPaymentEntry."Document No."
                        else
                            AppliedNumbers := AppliedNumbers + ', ' + AppliedPaymentEntry."Document No.";
                end else begin
                    if AppliedPaymentEntry."Applies-to Entry No." <> 0 then
                        if AppliedNumbers = '' then
                            AppliedNumbers := Format(AppliedPaymentEntry."Applies-to Entry No.")
                        else
                            AppliedNumbers := AppliedNumbers + ', ' + Format(AppliedPaymentEntry."Applies-to Entry No.");
                end;
            until AppliedPaymentEntry.Next = 0;
        end;

        exit(AppliedNumbers);
    end;

    procedure TransferRemainingAmountToAccount()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        TestField("Account No.");

        SetAppliedPaymentEntryFromRec(AppliedPaymentEntry);
        AppliedPaymentEntry.Validate("Applied Amount", Difference);
        AppliedPaymentEntry.Validate("Match Confidence", AppliedPaymentEntry."Match Confidence"::Manual);
        AppliedPaymentEntry.Insert(true);
    end;

    procedure GetAmountRangeForTolerance(var MinAmount: Decimal; var MaxAmount: Decimal)
    var
        BankAccount: Record "Bank Account";
        TempAmount: Decimal;
    begin
        BankAccount.Get("Bank Account No.");
        case BankAccount."Match Tolerance Type" of
            BankAccount."Match Tolerance Type"::Amount:
                begin
                    MinAmount := "Statement Amount" - BankAccount."Match Tolerance Value";
                    MaxAmount := "Statement Amount" + BankAccount."Match Tolerance Value";

                    if ("Statement Amount" >= 0) and (MinAmount < 0) then
                        MinAmount := 0
                    else
                        if ("Statement Amount" < 0) and (MaxAmount > 0) then
                            MaxAmount := 0;
                end;
            BankAccount."Match Tolerance Type"::Percentage:
                begin
                    MinAmount := "Statement Amount" * (1 - BankAccount."Match Tolerance Value" / 100);
                    MaxAmount := "Statement Amount" * (1 + BankAccount."Match Tolerance Value" / 100);

                    if "Statement Amount" < 0 then begin
                        TempAmount := MinAmount;
                        MinAmount := MaxAmount;
                        MaxAmount := TempAmount;
                    end;
                end;
        end;

        MinAmount := Round(MinAmount);
        MaxAmount := Round(MaxAmount);
    end;

    [Scope('OnPrem')]
    procedure UpdateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    begin
        if "Line Status" <> "Line Status"::"Contractor Confirmed" then
            exit;

        if "Document Type" = "Document Type"::Refund then
            GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Refund)
        else
            GenJnlLine.Validate("Document Type", "Document Type");
        GenJnlLine.Validate("Account Type", "Entity Type");
        GenJnlLine.Validate("Account No.", "Entity No.");
        GenJnlLine.Validate("Document No.", "Document No.");
        if (("Entity Type" = "Entity Type"::Customer) and
            ("Document Type" <> "Document Type"::Refund)) or
           (("Entity Type" = "Entity Type"::Vendor) and
            ("Document Type" = "Document Type"::Refund)) or
           (("Entity Type" = "Entity Type"::"G/L Account") and
            ("Document Type" <> "Document Type"::Refund) and
            ("Payment Direction" = "Payment Direction"::Incoming)) or
           (("Entity Type" = "Entity Type"::"G/L Account") and
            ("Document Type" = "Document Type"::Refund) and
            ("Payment Direction" = "Payment Direction"::Outgoing))
        then
            GenJnlLine.Validate(Amount, GenJnlLine.Amount)
        else
            GenJnlLine.Validate(Amount, -GenJnlLine.Amount);
        GenJnlLine.Validate("Payment Purpose", CopyStr(Description, 1, StrLen(GenJnlLine."Payment Purpose")));
        GenJnlLine.Validate("Payment Code", BankAccReconLine."Payment Code");
    end;

    procedure GetAppliedPmtData(var AppliedPmtEntry: Record "Applied Payment Entry"; var RemainingAmountAfterPosting: Decimal; var DifferenceStatementAmtToApplEntryAmount: Decimal; PmtAppliedToTxt: Text)
    var
        CurrRemAmtAfterPosting: Decimal;
    begin
        AppliedPmtEntry.Init();
        RemainingAmountAfterPosting := 0;
        DifferenceStatementAmtToApplEntryAmount := 0;

        AppliedPmtEntry.FilterAppliedPmtEntry(Rec);
        AppliedPmtEntry.SetFilter("Applies-to Entry No.", '<>0');
        if AppliedPmtEntry.FindSet then begin
            DifferenceStatementAmtToApplEntryAmount := "Statement Amount";
            repeat
                CurrRemAmtAfterPosting :=
                  AppliedPmtEntry.GetRemAmt -
                  AppliedPmtEntry.GetAmtAppliedToOtherStmtLines;

                RemainingAmountAfterPosting += CurrRemAmtAfterPosting - AppliedPmtEntry."Applied Amount";
                DifferenceStatementAmtToApplEntryAmount -= CurrRemAmtAfterPosting - AppliedPmtEntry."Applied Pmt. Discount";
            until AppliedPmtEntry.Next = 0;
        end;

        if "Applied Entries" > 1 then
            AppliedPmtEntry.Description := StrSubstNo(PmtAppliedToTxt, "Applied Entries");
    end;

    local procedure UpdateParentLineStatementAmount()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        if BankAccReconciliationLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Parent Line No.") then begin
            BankAccReconciliationLine.Validate("Statement Amount", "Statement Amount" + BankAccReconciliationLine."Statement Amount");
            BankAccReconciliationLine.Modify(true)
        end
    end;

    procedure IsTransactionPostedAndReconciled(): Boolean
    var
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
        BankAccountStatementLine: Record "Bank Account Statement Line";
    begin
        if "Transaction ID" <> '' then begin
            PostedPaymentReconLine.SetRange("Bank Account No.", "Bank Account No.");
            PostedPaymentReconLine.SetRange("Transaction ID", "Transaction ID");
            PostedPaymentReconLine.SetRange(Reconciled, true);
            if not PostedPaymentReconLine.IsEmpty then
                exit(true);
            BankAccountStatementLine.SetRange("Bank Account No.", "Bank Account No.");
            BankAccountStatementLine.SetRange("Transaction ID", "Transaction ID");
            exit(not BankAccountStatementLine.IsEmpty);
        end;
        exit(false);
    end;

    local procedure IsTransactionPostedAndNotReconciled(): Boolean
    var
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
    begin
        if "Transaction ID" <> '' then begin
            PostedPaymentReconLine.SetRange("Bank Account No.", "Bank Account No.");
            PostedPaymentReconLine.SetRange("Transaction ID", "Transaction ID");
            PostedPaymentReconLine.SetRange(Reconciled, false);
            exit(PostedPaymentReconLine.FindFirst)
        end;
        exit(false);
    end;

    local procedure IsTransactionAlreadyImported(): Boolean
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        if "Transaction ID" <> '' then begin
            BankAccReconciliationLine.SetRange("Statement Type", "Statement Type");
            BankAccReconciliationLine.SetRange("Bank Account No.", "Bank Account No.");
            BankAccReconciliationLine.SetRange("Transaction ID", "Transaction ID");
            exit(BankAccReconciliationLine.FindFirst)
        end;
        exit(false);
    end;

    local procedure AllowImportOfPostedNotReconciledTransactions(): Boolean
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.Get("Statement Type", "Bank Account No.", "Statement No.");
        if BankAccReconciliation."Import Posted Transactions" = BankAccReconciliation."Import Posted Transactions"::" " then begin
            BankAccReconciliation."Import Posted Transactions" := BankAccReconciliation."Import Posted Transactions"::No;
            if GuiAllowed then
                if Confirm(ImportPostedTransactionsQst) then
                    BankAccReconciliation."Import Posted Transactions" := BankAccReconciliation."Import Posted Transactions"::Yes;
            BankAccReconciliation.Modify();
        end;

        exit(BankAccReconciliation."Import Posted Transactions" = BankAccReconciliation."Import Posted Transactions"::Yes);
    end;

    procedure CanImport(): Boolean
    begin
        if IsTransactionPostedAndReconciled or IsTransactionAlreadyImported then
            exit(false);

        if IsTransactionPostedAndNotReconciled then
            exit(AllowImportOfPostedNotReconciledTransactions);

        exit(true);
    end;

    procedure BankStatementLinesListIsEmpty(StatementNo: Code[20]; StatementType: Option; BankAccountNo: Code[20]): Boolean
    var
        BankAccReconciliationLine: record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliationLine.SetRange("Statement No.", StatementNo);
        BankAccReconciliationLine.SetRange("Statement Type", StatementType);

        exit(BankAccReconciliationLine.IsEmpty);
    end;

    local procedure GetSalepersonPurchaserCode(): Code[20]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case "Account Type" of
            "Account Type"::Customer:
                if Customer.Get("Account No.") then
                    exit(Customer."Salesperson Code");
            "Account Type"::Vendor:
                if Vendor.Get("Account No.") then
                    exit(Vendor."Purchaser Code");
        end;
    end;

    procedure GetAppliesToID(): Code[50]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        exit(CopyStr(Format("Statement No.") + '-' + Format("Statement Line No."), 1, MaxStrLen(CustLedgerEntry."Applies-to ID")));
    end;

    procedure GetDescription(): Text[100]
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        if Description <> '' then
            exit(Description);

        AppliedPaymentEntry.FilterAppliedPmtEntry(Rec);
        AppliedPaymentEntry.SetFilter("Applies-to Entry No.", '<>%1', 0);
        if AppliedPaymentEntry.FindSet then
            if AppliedPaymentEntry.Next = 0 then
                exit(AppliedPaymentEntry.Description);

        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var FieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var xBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var xBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}

