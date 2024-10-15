table 11730 "Cash Document Header"
{
    Caption = 'Cash Document Header';
    DataCaptionFields = "Cash Desk No.", "Cash Document Type", "No.", "Pay-to/Receive-from Name";
    DrillDownPageID = "Cash Document List";
    LookupPageID = "Cash Document List";

    fields
    {
        field(1; "Cash Desk No."; Code[20])
        {
            Caption = 'Cash Desk No.';
            Editable = false;
            TableRelation = "Bank Account" WHERE("Account Type" = CONST("Cash Desk"));

            trigger OnLookup()
            begin
                if not BankAccount.Get("Cash Desk No.") then
                    BankAccount."Account Type" := BankAccount."Account Type"::"Cash Desk";
                BankAccount.Lookup;
            end;

            trigger OnValidate()
            begin
                TestField("Cash Desk No.");
                TestField("No.", '');
                BankAccount.Get("Cash Desk No.");
                BankAccount.TestField(Blocked, false);
            end;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if xRec."No." <> '' then
                    TestField("No.", "No.");

                if "No." <> xRec."No." then begin
                    BankAccount.Get("Cash Desk No.");
                    NoSeriesMgt.TestManual(GetNoSeriesCode);
                    "No. Series" := '';
                end;
            end;
        }
        field(3; "Pay-to/Receive-from Name"; Text[100])
        {
            Caption = 'Pay-to/Receive-from Name';
        }
        field(4; "Pay-to/Receive-from Name 2"; Text[50])
        {
            Caption = 'Pay-to/Receive-from Name 2';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                if "Currency Code" <> '' then begin
                    UpdateCurrencyFactor;
                    if "Currency Factor" <> xRec."Currency Factor" then
                        ConfirmUpdateCurrencyFactor;
                end;

                "Document Date" := "Posting Date";
                "VAT Date" := "Posting Date";
            end;
        }
        field(7; Amount; Decimal)
        {
            CalcFormula = Sum ("Cash Document Line".Amount WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                                 "Cash Document No." = FIELD("No.")));
            Caption = 'Amount';
            FieldClass = FlowField;
        }
        field(8; "Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Cash Document Line"."Amount (LCY)" WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                                         "Cash Document No." = FIELD("No.")));
            Caption = 'Amount (LCY)';
            FieldClass = FlowField;
        }
        field(14; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released,Pending Approval,Approved';
            OptionMembers = Open,Released,"Pending Approval",Approved;
        }
        field(15; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        field(17; "Created ID"; Code[50])
        {
            Caption = 'Created ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(18; "Released ID"; Code[50])
        {
            Caption = 'Released ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(20; "Cash Document Type"; Option)
        {
            Caption = 'Cash Document Type';
            OptionCaption = ' ,Receipt,Withdrawal';
            OptionMembers = " ",Receipt,Withdrawal;

            trigger OnValidate()
            begin
                if "Cash Document Type" <> xRec."Cash Document Type" then
                    TestField("No.", '');
            end;
        }
        field(21; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date")]) then;
                if CurrFieldNo <> FieldNo("Currency Code") then
                    UpdateCurrencyFactor
                else
                    if "Currency Code" <> xRec."Currency Code" then
                        UpdateCurrencyFactor
                    else
                        if "Currency Code" <> '' then begin
                            UpdateCurrencyFactor;
                            if "Currency Factor" <> xRec."Currency Factor" then
                                ConfirmUpdateCurrencyFactor;
                        end;
            end;
        }
        field(23; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(24; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(25; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';

            trigger OnValidate()
            begin
                UpdateDocLines(FieldCaption("Currency Factor"), false);
            end;
        }
        field(30; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(35; "VAT Date"; Date)
        {
            Caption = 'VAT Date';
        }
        field(38; "Created Date"; Date)
        {
            Caption = 'Created Date';
        }
        field(40; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(42; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                BankAccount.Get("Cash Desk No.");
                CreateDim(
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::"Bank Account", "Cash Desk No.",
                  GetPartnerTab, "Partner No.");
            end;
        }
        field(45; "Amounts Including VAT"; Boolean)
        {
            Caption = 'Amounts Including VAT';

            trigger OnValidate()
            begin
                UpdateDocLines(FieldCaption("Amounts Including VAT"), true);
            end;
        }
        field(50; "Released Amount"; Decimal)
        {
            Caption = 'Released Amount';
            Editable = false;
        }
        field(51; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Cash Document Line"."VAT Base Amount" WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                                            "Cash Document No." = FIELD("No.")));
            Caption = 'VAT Base Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Cash Document Line"."Amount Including VAT" WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                                                 "Cash Document No." = FIELD("No.")));
            Caption = 'Amount Including VAT';
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "VAT Base Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Cash Document Line"."VAT Base Amount (LCY)" WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                                                  "Cash Document No." = FIELD("No.")));
            Caption = 'VAT Base Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Amount Including VAT (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Cash Document Line"."Amount Including VAT (LCY)" WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                                                       "Cash Document No." = FIELD("No.")));
            Caption = 'Amount Including VAT (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(61; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(62; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            begin
                if not UserSetupMgt.CheckRespCenter(3, "Responsibility Center") then
                    Error(RespCenterErr, FieldCaption("Responsibility Center"), UserSetupMgt.GetCashFilter);

                BankAccount.Get("Cash Desk No.");
                CreateDim(
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::"Bank Account", "Cash Desk No.",
                  GetPartnerTab, "Partner No.");
            end;
        }
        field(65; "Payment Purpose"; Text[100])
        {
            Caption = 'Payment Purpose';
        }
        field(70; "Received By"; Text[100])
        {
            Caption = 'Received By';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Cash Document Type", "Cash Document Type"::Receipt);
            end;
        }
        field(71; "Identification Card No."; Code[10])
        {
            Caption = 'Identification Card No.';
        }
        field(72; "Paid By"; Text[100])
        {
            Caption = 'Paid By';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
                TestField("Cash Document Type", "Cash Document Type"::Withdrawal);
            end;
        }
        field(73; "Received From"; Text[100])
        {
            Caption = 'Received From';

            trigger OnValidate()
            begin
                TestField("Cash Document Type", "Cash Document Type"::Receipt);
            end;
        }
        field(74; "Paid To"; Text[100])
        {
            Caption = 'Paid To';

            trigger OnValidate()
            begin
                TestField("Cash Document Type", "Cash Document Type"::Withdrawal);
            end;
        }
        field(80; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
        }
        field(81; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(90; "Partner Type"; Option)
        {
            Caption = 'Partner Type';
            OptionCaption = ' ,Customer,Vendor,Contact,Salesperson/Purchaser,Employee';
            OptionMembers = " ",Customer,Vendor,Contact,"Salesperson/Purchaser",Employee;

            trigger OnValidate()
            begin
                if "Partner Type" <> xRec."Partner Type" then
                    Validate("Partner No.", '');
            end;
        }
        field(91; "Partner No."; Code[20])
        {
            Caption = 'Partner No.';
            TableRelation = IF ("Partner Type" = CONST(Customer)) Customer
            ELSE
            IF ("Partner Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Partner Type" = CONST(Contact)) Contact
            ELSE
            IF ("Partner Type" = CONST("Salesperson/Purchaser")) "Salesperson/Purchaser"
            ELSE
            IF ("Partner Type" = CONST(Employee)) Employee;

            trigger OnLookup()
            begin
                case "Partner Type" of
                    "Partner Type"::Customer:
                        begin
                            Clear(Customer);
                            if PAGE.RunModal(0, Customer) = ACTION::LookupOK then
                                Validate("Partner No.", Customer."No.");
                        end;
                    "Partner Type"::Vendor:
                        begin
                            Clear(Vendor);
                            if PAGE.RunModal(0, Vendor) = ACTION::LookupOK then
                                Validate("Partner No.", Vendor."No.");
                        end;
                    "Partner Type"::Contact:
                        begin
                            Clear(Contact);
                            if PAGE.RunModal(0, Contact) = ACTION::LookupOK then
                                Validate("Partner No.", Contact."No.");
                        end;
                    "Partner Type"::"Salesperson/Purchaser":
                        begin
                            Clear(Salesperson);
                            if PAGE.RunModal(0, Salesperson) = ACTION::LookupOK then
                                Validate("Partner No.", Salesperson.Code);
                        end;
                    "Partner Type"::Employee:
                        begin
                            Clear(Employee);
                            if PAGE.RunModal(0, Employee) = ACTION::LookupOK then
                                Validate("Partner No.", Employee."No.");
                        end;
                end;
            end;

            trigger OnValidate()
            begin
                if "Partner No." = '' then begin
                    case "Cash Document Type" of
                        "Cash Document Type"::Receipt:
                            "Received From" := '';
                        "Cash Document Type"::Withdrawal:
                            "Paid To" := '';
                    end;
                    "Registration No." := '';
                    "VAT Registration No." := '';
                end else
                    case "Partner Type" of
                        "Partner Type"::" ":
                            begin
                                case "Cash Document Type" of
                                    "Cash Document Type"::Receipt:
                                        "Received From" := '';
                                    "Cash Document Type"::Withdrawal:
                                        "Paid To" := '';
                                end;
                                "Registration No." := '';
                                "VAT Registration No." := '';
                            end;
                        "Partner Type"::Customer:
                            begin
                                Customer.Get("Partner No.");
                                case "Cash Document Type" of
                                    "Cash Document Type"::Receipt:
                                        "Received From" := Customer.Name;
                                    "Cash Document Type"::Withdrawal:
                                        "Paid To" := Customer.Name;
                                end;
                                "VAT Registration No." := Customer."VAT Registration No.";
                                "Registration No." := Customer."Registration No.";
                            end;
                        "Partner Type"::Vendor:
                            begin
                                Vendor.Get("Partner No.");
                                case "Cash Document Type" of
                                    "Cash Document Type"::Receipt:
                                        "Received From" := Vendor.Name;
                                    "Cash Document Type"::Withdrawal:
                                        "Paid To" := Vendor.Name;
                                end;
                                "VAT Registration No." := Vendor."VAT Registration No.";
                                "Registration No." := Vendor."Registration No.";
                            end;
                        "Partner Type"::Contact:
                            begin
                                Contact.Get("Partner No.");
                                case "Cash Document Type" of
                                    "Cash Document Type"::Receipt:
                                        "Received From" := Contact.Name;
                                    "Cash Document Type"::Withdrawal:
                                        "Paid To" := Contact.Name;
                                end;
                                "VAT Registration No." := Contact."VAT Registration No.";
                                "Registration No." := Contact."Registration No.";
                            end;
                        "Partner Type"::"Salesperson/Purchaser":
                            begin
                                Salesperson.Get("Partner No.");
                                case "Cash Document Type" of
                                    "Cash Document Type"::Receipt:
                                        "Received From" := Salesperson.Name;
                                    "Cash Document Type"::Withdrawal:
                                        "Paid To" := Salesperson.Name;
                                end;
                            end;
                        "Partner Type"::Employee:
                            begin
                                Employee.Get("Partner No.");
                                case "Cash Document Type" of
                                    "Cash Document Type"::Receipt:
                                        "Received From" := CopyStr(Employee.FullName, 1, MaxStrLen("Received From"));
                                    "Cash Document Type"::Withdrawal:
                                        "Paid To" := CopyStr(Employee.FullName, 1, MaxStrLen("Paid To"));
                                end;
                            end;
                    end;

                CreateDim(
                  GetPartnerTab, "Partner No.",
                  DATABASE::"Responsibility Center", "Responsibility Center",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::"Bank Account", "Cash Desk No.");
            end;
        }
        field(98; "Canceled Document"; Boolean)
        {
            Caption = 'Canceled Document';
            Editable = false;
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
        field(31120; "EET Cash Register"; Boolean)
        {
            CalcFormula = Exist ("EET Cash Register" WHERE("Register Type" = CONST("Cash Desk"),
                                                           "Register No." = FIELD("Cash Desk No.")));
            Caption = 'EET Cash Register';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31125; "EET Transaction"; Boolean)
        {
            CalcFormula = Exist ("Cash Document Line" WHERE("Cash Desk No." = FIELD("Cash Desk No."),
                                                            "Cash Document No." = FIELD("No."),
                                                            "EET Transaction" = CONST(true)));
            Caption = 'EET Transaction';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Cash Desk No.", "No.")
        {
            Clustered = true;
        }
        key(Key2; "Cash Desk No.", "Posting Date")
        {
        }
        key(Key3; "External Document No.")
        {
        }
        key(Key4; "No.", "Posting Date")
        {
        }
        key(Key5; "Cash Desk No.", "Cash Document Type", Status, "Posting Date")
        {
            SumIndexFields = "Released Amount";
        }
        key(Key6; "Cash Document Type", "No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CashDocPost: Codeunit "Cash Document-Post";
    begin
        TestField(Status, Status::Open);
        if not Confirm(DeleteQst, false) then
            Error('');

        ApprovalsMgmt.DeleteApprovalEntryForRecord(Rec);

        CashDeskMgt.CheckCashDesks;
        if not UserSetupMgt.CheckRespCenter(3, "Responsibility Center") then
            Error(RespCenterDeleteErr, FieldCaption("Responsibility Center"), UserSetupMgt.GetCashFilter);

        CashDocPost.DeleteCashDocHeader(Rec);

        CashDocLine.Reset();
        CashDocLine.SetRange("Cash Desk No.", "Cash Desk No.");
        CashDocLine.SetRange("Cash Document No.", "No.");
        CashDocLine.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        CashDeskUser: Record "Cash Desk User";
    begin
        TestField("Cash Desk No.");
        TestField("Cash Document Type");

        BankAccount.Get("Cash Desk No.");
        BankAccount.TestField(Blocked, false);
        if BankAccount."Responsibility ID (Release)" <> '' then
            if BankAccount."Responsibility ID (Release)" <> UserId then
                Error(RespCreateErr, TableCaption, BankAccount.TableCaption, "Cash Desk No.");

        CashDeskMgt.CheckUserRights("Cash Desk No.", 1, false);

        if BankAccount."Confirm Inserting of Document" then
            if not Confirm(CreateQst, true, "Cash Document Type", "Cash Desk No.") then
                Error('');

        if "No." = '' then
            case "Cash Document Type" of
                "Cash Document Type"::Receipt:
                    begin
                        BankAccount.TestField("Cash Document Receipt Nos.");
                        NoSeriesMgt.InitSeries(BankAccount."Cash Document Receipt Nos.", xRec."No. Series", WorkDate, "No.", "No. Series");
                    end;
                "Cash Document Type"::Withdrawal:
                    begin
                        BankAccount.TestField("Cash Document Withdrawal Nos.");
                        NoSeriesMgt.InitSeries(BankAccount."Cash Document Withdrawal Nos.", xRec."No. Series", WorkDate, "No.", "No. Series");
                    end;
            end;

        "Posting Date" := WorkDate;
        "Document Date" := "Posting Date";
        "VAT Date" := "Posting Date";
        "Created ID" := UserId;
        "Created Date" := WorkDate;

        "Responsibility Center" := BankAccount."Responsibility Center";
        "Amounts Including VAT" := BankAccount."Amounts Including VAT";
        "Reason Code" := BankAccount."Reason Code";
        Validate("Currency Code", BankAccount."Currency Code");

        case "Cash Document Type" of
            "Cash Document Type"::Receipt:
                "Received By" := CashDeskUser.GetUserName(UserId);
            "Cash Document Type"::Withdrawal:
                "Paid By" := CashDeskUser.GetUserName(UserId);
        end;

        CreateDim(
          DATABASE::"Responsibility Center", "Responsibility Center",
          DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
          DATABASE::"Bank Account", "Cash Desk No.",
          GetPartnerTab, "Partner No.");
    end;

    trigger OnModify()
    begin
        if not UserSetupMgt.CheckRespCenter(3, "Responsibility Center") then
            Error(RespCenterModifyErr, FieldCaption("Responsibility Center"), UserSetupMgt.GetCashFilter);
    end;

    trigger OnRename()
    begin
        Error(RenameErr, TableCaption);
    end;

    var
        CashDocHeader: Record "Cash Document Header";
        BankAccount: Record "Bank Account";
        CashDocLine: Record "Cash Document Line";
        CurrExchRate: Record "Currency Exchange Rate";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        Employee: Record Employee;
        RenameErr: Label 'You cannot rename a %1.', Comment = '%1=TABLECAPTION';
        UpdateExchRateQst: Label 'Do you want to update the exchange rate?';
        UpdateLinesQst: Label 'You have modified %1.\Do you want to update lines?', Comment = '%1=Changed Field Name';
        UpdateLinesDimQst: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        RespCenterErr: Label 'Your identification is set up to process from %1 %2 only.', Comment = '%1 = fieldcaption of Responsibility Center; %2 = Responsibility Center';
        RespCenterModifyErr: Label 'You cannot modify this document. Your identification is set up to process from %1 %2 only.', Comment = '%1 = fieldcaption of Responsibility Center; %2 = Responsibility Center';
        RespCenterDeleteErr: Label 'You cannot delete this document. Your identification is set up to process from %1 %2 only.', Comment = '%1 = fieldcaption of Responsibility Center; %2 = Responsibility Center';
        RespCreateErr: Label 'You are not alloved create %1 on %2 %3.', Comment = '%1=TABLECAPTION,%2=CashDesk.TABLECAPTION,%3="Cash Desk No."';
        CreateQst: Label 'Do you want to create %1 at Cash Desk %2?', Comment = '%1="Cash Document Type",%2="Cash Desk No."';
        DeleteQst: Label 'Deleting this document will cause a gap in the number series for posted cash documents.\Do you want continue?';
        ConfirmMgt: Codeunit "Confirm Management";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        UserSetupMgt: Codeunit "User Setup Management";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        CashDeskMgt: Codeunit CashDeskManagement;
        CurrencyDate: Date;
        SkipLineNo: Integer;
        HideValidationDialog: Boolean;

    [Scope('OnPrem')]
    procedure AssistEdit(OldCashDocHeader: Record "Cash Document Header"): Boolean
    begin
        with OldCashDocHeader do begin
            Copy(Rec);
            TestNoSeries;
            if NoSeriesMgt.SelectSeries(GetNoSeriesCode, "No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := OldCashDocHeader;
                exit(true);
            end;
        end;
    end;

    local procedure TestNoSeries()
    begin
        BankAccount.Get("Cash Desk No.");
        case "Cash Document Type" of
            "Cash Document Type"::Receipt:
                BankAccount.TestField("Cash Document Receipt Nos.");
            "Cash Document Type"::Withdrawal:
                BankAccount.TestField("Cash Document Withdrawal Nos.");
        end;
    end;

    local procedure GetNoSeriesCode(): Code[20]
    begin
        BankAccount.Get("Cash Desk No.");
        case "Cash Document Type" of
            "Cash Document Type"::Receipt:
                exit(BankAccount."Cash Document Receipt Nos.");
            "Cash Document Type"::Withdrawal:
                exit(BankAccount."Cash Document Withdrawal Nos.");
        end;
    end;

    local procedure UpdateCurrencyFactor()
    begin
        if "Currency Code" <> '' then begin
            if "Posting Date" = 0D then
                CurrencyDate := WorkDate
            else
                CurrencyDate := "Posting Date";
            "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
        end else
            "Currency Factor" := 0;

        Validate("Currency Factor");
    end;

    local procedure ConfirmUpdateCurrencyFactor()
    begin
        if GuiAllowed then begin
            if Confirm(UpdateExchRateQst, false) then
                Validate("Currency Factor")
            else
                Validate("Currency Factor", xRec."Currency Factor")
        end else
            Validate("Currency Factor");
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
          DimMgt.GetDefaultDimID(TableID, No, SourceCodeSetup."Cash Desk", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        if (OldDimSetID <> "Dimension Set ID") and CashDocLinesExist then begin
            Modify;
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify;

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if CashDocLinesExist then
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
            "Dimension Set ID", StrSubstNo('%1 %2', TableCaption, "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify;
            if CashDocLinesExist then
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

        CashDocLine.Reset();
        CashDocLine.SetRange("Cash Desk No.", "Cash Desk No.");
        CashDocLine.SetRange("Cash Document No.", "No.");
        if SkipLineNo <> 0 then
            CashDocLine.SetFilter("Line No.", '<>%1', SkipLineNo);
        if CashDocLine.IsEmpty then
            exit;

        if not HideValidationDialog then
            if not ConfirmMgt.GetResponse(UpdateLinesDimQst, false) then
                exit;

        CashDocLine.LockTable();
        if CashDocLine.FindSet then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(CashDocLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if CashDocLine."Dimension Set ID" <> NewDimSetID then begin
                    CashDocLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      CashDocLine."Dimension Set ID", CashDocLine."Shortcut Dimension 1 Code", CashDocLine."Shortcut Dimension 2 Code");
                    CashDocLine.Modify();
                end;
            until CashDocLine.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure UpdateDocLines(ChangedFieldName: Text[30]; AskQuestion: Boolean)
    begin
        if CashDocLinesExist and AskQuestion then
            if not Confirm(UpdateLinesQst, true, ChangedFieldName) then
                Error('');

        if CashDocLinesExist then begin
            CashDocLine.LockTable();
            Modify;

            CashDocLine.Reset();
            CashDocLine.SetRange("Cash Desk No.", "Cash Desk No.");
            CashDocLine.SetRange("Cash Document No.", "No.");
            if CashDocLine.FindSet(true) then
                repeat
                    case ChangedFieldName of
                        FieldCaption("Currency Factor"):
                            if CashDocLine.Amount <> 0 then
                                CashDocLine.Validate(Amount);
                        FieldCaption("Amounts Including VAT"):
                            if CashDocLine.Amount <> 0 then
                                CashDocLine.Validate(Amount);
                    end;
                    CashDocLine.Modify(true);
                until CashDocLine.Next = 0;
        end;

        CalcFields("VAT Base Amount", "Amount Including VAT", "VAT Base Amount (LCY)", "Amount Including VAT (LCY)");
    end;

    [Scope('OnPrem')]
    procedure VATRounding()
    var
        BankAccount2: Record "Bank Account";
        RoundingMethod: Record "Rounding Method";
        CashDocLine2: Record "Cash Document Line";
        Direction: Text[1];
        RoundedAmount: Decimal;
        LastLineNo: Integer;
    begin
        BankAccount2.Get("Cash Desk No.");
        BankAccount2.TestField("Rounding Method Code");
        BankAccount2.TestField("Debit Rounding Account");
        BankAccount2.TestField("Credit Rounding Account");

        CashDocLine.Reset();
        CashDocLine.SetRange("Cash Desk No.", "Cash Desk No.");
        CashDocLine.SetRange("Cash Document No.", "No.");
        if CashDocLine.IsEmpty then
            exit;

        CashDocLine.CalcSums("Amount Including VAT");

        RoundingMethod.Reset();
        RoundingMethod.SetRange(Code, BankAccount2."Rounding Method Code");
        RoundingMethod.SetFilter("Minimum Amount", '..%1', Abs(CashDocLine."Amount Including VAT"));
        RoundingMethod.FindLast;
        RoundingMethod.TestField(Precision);
        case RoundingMethod.Type of
            RoundingMethod.Type::Nearest:
                Direction := '=';
            RoundingMethod.Type::Up:
                Direction := '>';
            RoundingMethod.Type::Down:
                Direction := '<';
        end;

        RoundedAmount :=
          Round(CashDocLine."Amount Including VAT", RoundingMethod.Precision, Direction) - CashDocLine."Amount Including VAT";

        CashDocLine2.Reset();
        CashDocLine2.SetRange("Cash Desk No.", "Cash Desk No.");
        CashDocLine2.SetRange("Cash Document No.", "No.");
        if CashDocLine2.FindLast then
            LastLineNo := CashDocLine2."Line No.";

        CashDocLine2.SetRange("Account Type", CashDocLine."Account Type"::"G/L Account");
        CashDocLine2.SetFilter("Account No.", '%1|%2',
          BankAccount2."Debit Rounding Account", BankAccount2."Credit Rounding Account");
        CashDocLine2.SetRange("System-Created Entry", true);
        if not CashDocLine2.FindFirst then
            CashDocLine2.Init();

        if (RoundedAmount <> 0) and (CashDocLine2.Amount <> RoundedAmount) then begin
            LastLineNo += 10000;

            CashDocLine2.SetRange("Account Type", CashDocLine."Account Type"::"G/L Account");
            CashDocLine2.SetFilter("Account No.", '%1|%2',
              BankAccount2."Debit Rounding Account", BankAccount2."Credit Rounding Account");
            CashDocLine2.SetRange("System-Created Entry", true);
            if not CashDocLine2.IsEmpty then
                CashDocLine2.DeleteAll(true);

            CashDocLine2.Init();
            CashDocLine2."Cash Desk No." := "Cash Desk No.";
            CashDocLine2."Cash Document No." := "No.";
            CashDocLine2."Line No." := LastLineNo;
            CashDocLine2.Validate("Account Type", CashDocLine2."Account Type"::"G/L Account");
            case "Cash Document Type" of
                "Cash Document Type"::Receipt:
                    if RoundedAmount < 0 then
                        CashDocLine2.Validate("Account No.", BankAccount2."Debit Rounding Account")
                    else
                        CashDocLine2.Validate("Account No.", BankAccount2."Credit Rounding Account");
                "Cash Document Type"::Withdrawal:
                    if RoundedAmount > 0 then
                        CashDocLine2.Validate("Account No.", BankAccount2."Debit Rounding Account")
                    else
                        CashDocLine2.Validate("Account No.", BankAccount2."Credit Rounding Account");
            end;
            CashDocLine2.Validate("Currency Code", "Currency Code");
            if "Amounts Including VAT" then
                CashDocLine2.Validate(Amount, RoundedAmount)
            else begin
                CashDocLine2.Validate("Amount Including VAT", RoundedAmount);
                CashDocLine2.Amount := CashDocLine2."VAT Base Amount";
                CashDocLine2."Amount (LCY)" := Round(CashDocLine2.Amount);
                if "Currency Code" <> '' then
                    CashDocLine2."Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code", CashDocLine2.Amount, "Currency Factor"));
            end;
            CashDocLine2."System-Created Entry" := true;
            CashDocLine2.Insert(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPartnerTab(): Integer
    begin
        case "Partner Type" of
            "Partner Type"::Customer:
                exit(DATABASE::Customer);
            "Partner Type"::Vendor:
                exit(DATABASE::Vendor);
            "Partner Type"::Contact:
                exit(DATABASE::Contact);
            "Partner Type"::"Salesperson/Purchaser":
                exit(DATABASE::"Salesperson/Purchaser");
            "Partner Type"::Employee:
                exit(DATABASE::Employee);
            else
                exit(0);
        end;
    end;

    [Scope('OnPrem')]
    procedure CashDocLinesExist(): Boolean
    begin
        CashDocLine.Reset();
        CashDocLine.SetRange("Cash Desk No.", "Cash Desk No.");
        CashDocLine.SetRange("Cash Document No.", "No.");
        exit(not CashDocLine.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        ReportSelection: Record "Cash Desk Report Selections";
    begin
        TestField("Cash Document Type");
        with CashDocHeader do begin
            Copy(Rec);
            case "Cash Document Type" of
                "Cash Document Type"::Receipt:
                    ReportSelection.SetRange(Usage, ReportSelection.Usage::"C.Rcpt");
                "Cash Document Type"::Withdrawal:
                    ReportSelection.SetRange(Usage, ReportSelection.Usage::"C.Wdrwl");
            end;
            ReportSelection.SetFilter("Report ID", '<>0');
            ReportSelection.FindSet;
            repeat
                REPORT.RunModal(ReportSelection."Report ID", ShowRequestForm, false, CashDocHeader);
            until ReportSelection.Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetSkipLineNoToUpdateLine(LineNo: Integer)
    begin
        SkipLineNo := LineNo;
    end;

    [Scope('OnPrem')]
    procedure SignAmount(): Integer
    begin
        if "Cash Document Type" = "Cash Document Type"::Receipt then
            exit(-1);
        exit(1);
    end;

    [Scope('OnPrem')]
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure IsApprovedForPosting(): Boolean
    begin
        if ApprovalsMgmt.PrePostApprovalCheckCashDoc(Rec) then
            exit(true);
    end;

    [Scope('OnPrem')]
    procedure SendToPosting(PostingCodeunitID: Integer)
    begin
        if not IsApprovedForPosting then
            exit;
        CODEUNIT.Run(PostingCodeunitID, Rec);
    end;

    [Scope('OnPrem')]
    procedure IsEETCashRegister(): Boolean
    begin
        CalcFields("EET Cash Register");
        exit("EET Cash Register");
    end;

    [Scope('OnPrem')]
    procedure TestNotEETCashRegister()
    begin
        if IsEETCashRegister then
            FieldError("EET Cash Register");
    end;

    [Scope('OnPrem')]
    procedure IsEETTransaction(): Boolean
    begin
        CalcFields("EET Transaction");
        exit("EET Transaction");
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnCheckCashDocReleaseRestrictions()
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    [Scope('OnPrem')]
    procedure OnCheckCashDocPostRestrictions()
    begin
    end;
}

