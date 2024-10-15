table 10121 "Bank Rec. Line"
{
    Caption = 'Bank Rec. Line';
#if not CLEAN20
    DrillDownPageID = "Bank Rec. Lines";
    LookupPageID = "Bank Rec. Lines";
#endif
    ObsoleteReason = 'Deprecated in favor of W1 Bank Reconciliation';
#if not CLEAN20
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
#endif

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
            TableRelation = "Bank Rec. Header"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Record Type"; Option)
        {
            Caption = 'Record Type';
            OptionCaption = 'Check,Deposit,Adjustment';
            OptionMembers = Check,Deposit,Adjustment;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnValidate()
            begin
                if "Document No." = '' then
                    GenerateDocNo;
            end;
        }
        field(8; "Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';

            trigger OnValidate()
            begin
                CheckAccountType();
            end;
        }
        field(9; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Account Type" = CONST("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            begin
                if "Account No." = '' then begin
                    CreateDimFromDefaultDim(FieldNo("Account No."));
                    exit;
                end;

                case "Account Type" of
                    "Account Type"::"G/L Account":
                        begin
                            GLAcc.Get("Account No.");
                            CheckGLAcc;
                            ReplaceInfo := "Bal. Account No." = '';
                            if ReplaceInfo then
                                Description := GLAcc.Name;

                            if "Bal. Account No." = '' then
                                "Currency Code" := '';
                        end;
                    "Account Type"::Customer:
                        begin
                            Cust.Get("Account No.");
                            if Cust."Privacy Blocked" then
                                Error(PrivacyBlockedErr, "Account Type");
                            if Cust.Blocked in [Cust.Blocked::All] then
                                Error(Text1020100, "Account Type", Cust.Blocked);
                            Description := Cust.Name;
                            if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
                                Cust.TestField("Currency Code", "Currency Code")
                            else
                                "Currency Code" := Cust."Currency Code";
                            if Cust."Bill-to Customer No." <> '' then begin
                                Ok := Confirm(Text014, false, Cust.TableCaption, Cust."No.", Cust.FieldCaption("Bill-to Customer No."),
                                    Cust."Bill-to Customer No.");
                                if not Ok then
                                    Error('');
                            end;
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vend.Get("Account No.");
                            Vend.TestField("Privacy Blocked", false);
                            Vend.TestField(Blocked, Vend.Blocked::" ");
                            Description := Vend.Name;
                            if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
                                Vend.TestField("Currency Code", "Currency Code")
                            else
                                "Currency Code" := Vend."Currency Code";
                            if Vend."Pay-to Vendor No." <> '' then begin
                                Ok := Confirm(Text014, false, Vend.TableCaption, Vend."No.", Vend.FieldCaption("Pay-to Vendor No."),
                                    Vend."Pay-to Vendor No.");
                                if not Ok then
                                    Error('');
                            end;
                        end;
                    "Account Type"::"Bank Account":
                        begin
                            BankAcc.Get("Account No.");
                            BankAcc.TestField(Blocked, false);
                            ReplaceInfo := "Bal. Account No." = '';
                            if ReplaceInfo then
                                Description := BankAcc.Name;

                            if BankAcc."Currency Code" = '' then begin
                                if "Bal. Account No." = '' then
                                    "Currency Code" := '';
                            end else
                                if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
                                    BankAcc.TestField("Currency Code", "Currency Code")
                                else
                                    "Currency Code" := BankAcc."Currency Code";
                        end;
                    "Account Type"::"Fixed Asset":
                        begin
                            FA.Get("Account No.");
                            FA.TestField(Blocked, false);
                            FA.TestField(Inactive, false);
                            FA.TestField("Budgeted Asset", false);
                            Description := FA.Description;
                        end;
                end;

                Validate("Currency Code");
                CreateDimFromDefaultDim(FieldNo("Account No."));
            end;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; Amount; Decimal)
        {
            Caption = 'Amount';

            trigger OnValidate()
            begin
                if Cleared and ("Record Type" = "Record Type"::Adjustment) then
                    "Cleared Amount" := Amount;
            end;
        }
        field(12; Cleared; Boolean)
        {
            Caption = 'Cleared';

            trigger OnValidate()
            begin
                if Cleared then
                    "Cleared Amount" := Amount
                else
                    "Cleared Amount" := 0;
            end;
        }
        field(13; "Cleared Amount"; Decimal)
        {
            Caption = 'Cleared Amount';
        }
        field(14; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';

            trigger OnValidate()
            begin
                CheckBalAccountType();
            end;
        }
        field(15; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Bal. Account Type" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Bal. Account Type" = CONST(Customer)) Customer
            ELSE
            IF ("Bal. Account Type" = CONST(Vendor)) Vendor
            ELSE
            IF ("Bal. Account Type" = CONST("Bank Account")) "Bank Account"
            ELSE
            IF ("Bal. Account Type" = CONST("Fixed Asset")) "Fixed Asset";

            trigger OnValidate()
            begin
                if "Bal. Account No." = '' then begin
                    CreateDimFromDefaultDim(FieldNo("Bal. Account No."));
                    exit;
                end;

                case "Bal. Account Type" of
                    "Bal. Account Type"::"G/L Account":
                        begin
                            GLAcc.Get("Bal. Account No.");
                            CheckGLAcc;
                            if "Account No." = '' then begin
                                Description := GLAcc.Name;
                                "Currency Code" := '';
                            end;
                        end;
                    "Bal. Account Type"::Customer:
                        begin
                            Cust.Get("Bal. Account No.");
                            if Cust."Privacy Blocked" then
                                Error(PrivacyBlockedErr, "Account Type");
                            if Cust.Blocked in [Cust.Blocked::All] then
                                Error(Text1020100, "Account Type", Cust.Blocked);
                            if "Account No." = '' then
                                Description := Cust.Name;

                            if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
                                "Currency Code" := Cust."Currency Code";
                            if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
                                "Currency Code" := Cust."Currency Code";
                            if Cust."Bill-to Customer No." <> '' then begin
                                Ok := Confirm(Text014, false, Cust.TableCaption, Cust."No.", Cust.FieldCaption("Bill-to Customer No."),
                                    Cust."Bill-to Customer No.");
                                if not Ok then
                                    Error('');
                            end;
                        end;
                    "Bal. Account Type"::Vendor:
                        begin
                            Vend.Get("Bal. Account No.");
                            Vend.TestField("Privacy Blocked", false);
                            Vend.TestField(Blocked, Vend.Blocked::" ");
                            if "Account No." = '' then
                                Description := Vend.Name;

                            if ("Account No." = '') or ("Account Type" = "Account Type"::"G/L Account") then
                                "Currency Code" := Vend."Currency Code";
                            if ("Account Type" = "Account Type"::"Bank Account") and ("Currency Code" = '') then
                                "Currency Code" := Vend."Currency Code";
                            if Vend."Pay-to Vendor No." <> '' then begin
                                Ok := Confirm(Text014, false, Vend.TableCaption, Vend."No.", Vend.FieldCaption("Pay-to Vendor No."),
                                    Vend."Pay-to Vendor No.");
                                if not Ok then
                                    Error('');
                            end;
                        end;
                    "Bal. Account Type"::"Bank Account":
                        begin
                            BankAcc.Get("Bal. Account No.");
                            BankAcc.TestField(Blocked, false);
                            if "Account No." = '' then begin
                                Description := BankAcc.Name;
                                "Currency Code" := BankAcc."Currency Code";
                            end;
                            if BankAcc."Currency Code" = '' then begin
                                if "Account No." = '' then
                                    "Currency Code" := '';
                            end else
                                if SetCurrencyCode("Bal. Account Type", "Bal. Account No.") then
                                    BankAcc.TestField("Currency Code", "Currency Code")
                                else
                                    "Currency Code" := BankAcc."Currency Code";
                        end;
                    "Bal. Account Type"::"Fixed Asset":
                        begin
                            FA.Get("Bal. Account No.");
                            FA.TestField(Blocked, false);
                            FA.TestField(Inactive, false);
                            FA.TestField("Budgeted Asset", false);
                            if "Account No." = '' then
                                Description := FA.Description;
                        end;
                end;

                Validate("Currency Code");
                CreateDimFromDefaultDim(FieldNo("Bal. Account No."));
            end;
        }
        field(16; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" <> '' then begin
                    BankRecHdr.Get("Bank Account No.", "Statement No.");
                    Currency.Get("Currency Code");
                    "Currency Factor" := CurrExchRate.ExchangeRate(BankRecHdr."Statement Date", "Currency Code");
                end else
                    "Currency Factor" := 0;
                Validate("Currency Factor");
            end;
        }
        field(17; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';

            trigger OnValidate()
            begin
                if ("Currency Code" = '') and ("Currency Factor" <> 0) then
                    FieldError("Currency Factor", StrSubstNo(Text002, FieldCaption("Currency Code")));
            end;
        }
        field(18; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(19; "Bank Ledger Entry No."; Integer)
        {
            Caption = 'Bank Ledger Entry No.';
            TableRelation = "Bank Account Ledger Entry"."Entry No.";
        }
        field(20; "Check Ledger Entry No."; Integer)
        {
            Caption = 'Check Ledger Entry No.';
            TableRelation = "Check Ledger Entry"."Entry No.";
        }
        field(21; "Adj. Source Record ID"; Option)
        {
            Caption = 'Adj. Source Record ID';
            OptionCaption = 'Check,Deposit,Adjustment';
            OptionMembers = Check,Deposit,Adjustment;
        }
        field(22; "Adj. Source Document No."; Code[20])
        {
            Caption = 'Adj. Source Document No.';
        }
        field(23; "Adj. No. Series"; Code[20])
        {
            Caption = 'Adj. No. Series';
            TableRelation = "No. Series";
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
        field(26; "Collapse Status"; Option)
        {
            Caption = 'Collapse Status';
            Editable = false;
            OptionCaption = ' ,Collapsed Deposit,Expanded Deposit Line';
            OptionMembers = " ","Collapsed Deposit","Expanded Deposit Line";
        }
        field(27; Positive; Boolean)
        {
            Caption = 'Positive';
            Editable = false;
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

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Statement No.", "Record Type", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount;
        }
        key(Key2; "Bank Account No.", "Statement No.", "Record Type", Cleared)
        {
            SumIndexFields = Amount, "Cleared Amount";
        }
        key(Key3; "Bank Account No.", "Statement No.", "Record Type", Positive)
        {
            SumIndexFields = Amount;
        }
        key(Key4; "Bank Account No.", "Statement No.", "Posting Date", "Document Type", "Document No.", "External Document No.")
        {
        }
        key(Key5; "Bank Account No.", "Statement No.", Cleared)
        {
        }
        key(Key6; "Bank Account No.", "Statement No.", "Record Type", "Bal. Account No.")
        {
            SumIndexFields = Amount;
        }
        key(Key7; "Bank Account No.", "Statement No.", "Record Type", "Account Type", "Bal. Account Type", "Bal. Account No.", Positive)
        {
            SumIndexFields = Amount;
        }
        key(Key8; "Bank Account No.", "Statement No.", "Record Type", "Account Type", "Account No.", Positive)
        {
            SumIndexFields = Amount;
        }
        key(Key9; "Bank Account No.", "Statement No.", "Record Type", "External Document No.")
        {
        }
    }

    fieldgroups
    {
    }
#if not CLEAN20
    trigger OnDelete()
    var
        BankRecSubLine: Record "Bank Rec. Sub-line";
    begin
        BankRecCommentLine.SetRange("Table Name", BankRecCommentLine."Table Name"::"Bank Rec.");
        BankRecCommentLine.SetRange("Bank Account No.", "Bank Account No.");
        BankRecCommentLine.SetRange("No.", "Statement No.");
        BankRecCommentLine.SetRange("Line No.", "Line No.");
        BankRecCommentLine.DeleteAll();
        BankRecPost.UpdateLedgers(Rec, SetStatus::Open);

        if "Record Type" = "Record Type"::Deposit then begin
            BankRecSubLine.SetRange("Bank Account No.", "Bank Account No.");
            BankRecSubLine.SetRange("Statement No.", "Statement No.");
            BankRecSubLine.SetRange("Bank Rec. Line No.", "Line No.");
            BankRecSubLine.DeleteAll();
        end;
    end;
#endif

    trigger OnInsert()
    begin
        if "Document No." = '' then
            GenerateDocNo;
        UpdateLedgers;
    end;

    trigger OnModify()
    begin
        UpdateLedgers;
    end;

    trigger OnRename()
    begin
        Error(Text003, TableCaption);
    end;

    var
        Ok: Boolean;
        ReplaceInfo: Boolean;
#if not CLEAN20
        SetStatus: Option Open,Cleared,Posted;
#endif
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
        GLSetup: Record "General Ledger Setup";
        BankRecHdr: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
#if not CLEAN20
        BankRecCommentLine: Record "Bank Comment Line";
#endif
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        DimMgt: Codeunit DimensionManagement;
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text002: Label 'cannot be specified without %1';
        Text003: Label 'You cannot rename a %1.';
        Text014: Label 'The %1 %2 has a %3 %4.\Do you still want to use %1 %2 in this journal line?';
        Text1020100: Label '%1 is blocked for %2 processing.', Comment = '%1 = account type, %2 = Customer.blocked';
        PrivacyBlockedErr: Label '%1 is blocked for privacy.', Comment = '%1 = customer';
        UnsupportedTypeNotificationMsg: Label '%1 is not supported account type. You can enter and post the adjustment entry in a General Journal instead.', Comment = '%1=account type';
#if not CLEAN20
        BankRecPost: Codeunit "Bank Rec.-Post";
#endif

    procedure SetUpNewLine(LastBankRecLine: Record "Bank Rec. Line"; Balance: Decimal; BottomLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetUpNewLine(Rec, LastBankRecLine, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        BankRecLine.SetRange("Bank Account No.", "Bank Account No.");
        BankRecLine.SetRange("Statement No.", "Statement No.");
        BankRecLine.SetRange("Record Type", "Record Type");
        if BankRecLine.FindLast() then begin
            "Posting Date" := LastBankRecLine."Posting Date";
            "Document No." := LastBankRecLine."Document No.";
            "Document No." := IncStr("Document No.");
            "Account Type" := LastBankRecLine."Account Type";
        end else begin
            "Posting Date" := WorkDate;
            if GLSetup."Bank Rec. Adj. Doc. Nos." <> '' then begin
                Clear(NoSeriesMgt);
                "Document No." := NoSeriesMgt.TryGetNextNo(GLSetup."Bank Rec. Adj. Doc. Nos.", "Posting Date");
            end;
            "Account Type" := "Account Type"::"Bank Account";
            Validate("Account No.", "Bank Account No.");
        end;
        "Adj. No. Series" := GLSetup."Bank Rec. Adj. Doc. Nos.";
        "Bal. Account Type" := LastBankRecLine."Bal. Account Type";
        "Document Type" := LastBankRecLine."Document Type";
        if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset"]) and
           ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset"])
        then begin
            "Account Type" := "Account Type"::"G/L Account";
            "Account No." := '';
            Description := '';
        end;
        if "Record Type" = "Record Type"::Adjustment then begin
            Cleared := true;
            "Cleared Amount" := Amount;
        end;
    end;

    local procedure GenerateDocNo()
    begin
        if "Posting Date" = 0D then
            "Posting Date" := WorkDate;
        GLSetup.Get();
        Clear(NoSeriesMgt);
        "Document No." := NoSeriesMgt.TryGetNextNo(GLSetup."Bank Rec. Adj. Doc. Nos.", "Posting Date");
        OnAfterGenerateDocNo(Rec);
    end;

    local procedure CheckGLAcc()
    begin
        GLAcc.CheckGLAcc;
        if GLAcc."Direct Posting" then
            exit;
        if "Posting Date" <> 0D then
            if "Posting Date" = ClosingDate("Posting Date") then
                exit;
        GLAcc.TestField("Direct Posting", true);
    end;

    local procedure CheckAccountType()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAccountType(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Account Type" in ["Account Type"::Employee, "Account Type"::"IC Partner"] then
            ShowUnsupportedTypeNotification("Account Type");
    end;

    local procedure CheckBalAccountType()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBalAccountType(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Bal. Account Type" in ["Bal. Account Type"::Employee, "Bal. Account Type"::"IC Partner"] then
            ShowUnsupportedTypeNotification("Bal. Account Type");
    end;

    local procedure ShowUnsupportedTypeNotification(AccountType: Enum "Gen. Journal Account Type")
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        UnsupportedTypeNotification: Notification;
    begin
        UnsupportedTypeNotification.Id := GetUnsupportedTypeNotificationId();
        UnsupportedTypeNotification.Message := StrSubstNo(UnsupportedTypeNotificationMsg, AccountType);
        UnsupportedTypeNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        NotificationLifecycleMgt.SendNotification(UnsupportedTypeNotification, RecordId);
    end;

    procedure GetUnsupportedTypeNotificationId(): Guid
    begin
        exit('a346701b-edfb-4145-8f23-a928b2796001');
    end;

    local procedure SetCurrencyCode(AccType2: Enum "Gen. Journal Account Type"; AccNo2: Code[20]): Boolean
    var
        Cust2: Record Customer;
        Vend2: Record Vendor;
        BankAcc2: Record "Bank Account";
    begin
        "Currency Code" := '';
        if AccNo2 <> '' then
            case AccType2 of
                AccType2::Customer:
                    if Cust2.Get(AccNo2) then
                        "Currency Code" := Cust2."Currency Code";
                AccType2::Vendor:
                    if Vend2.Get(AccNo2) then
                        "Currency Code" := Vend2."Currency Code";
                AccType2::"Bank Account":
                    if BankAcc2.Get(AccNo2) then
                        "Currency Code" := BankAcc2."Currency Code";
            end;
        exit("Currency Code" <> '');
    end;

#if not CLEAN20
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20]; Type5: Integer; No5: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
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
        ClearAndAssignDefaultDimSetID(TableID, No);
    end;
#endif

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN20
        RunEventOnBeforeClearAndAssignDefaultDimSetID(DefaultDimSource, IsHandled);
#endif
        OnBeforeCreateDim(Rec, DefaultDimSource, IsHandled);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" := DimMgt.GetDefaultDimID(DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

#if not CLEAN20
    local procedure ClearAndAssignDefaultDimSetID(var TableID: array[10] of Integer; var No: array[10] of Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearAndAssignDefaultDimSetID(Rec, TableID, No, IsHandled);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" := DimMgt.GetDefaultDimID(TableID, No, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;
#endif

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure ExpandLine(var DepositBankRecLine: Record "Bank Rec. Line")
    var
        BankRecLine: Record "Bank Rec. Line";
        BankRecSubLine: Record "Bank Rec. Sub-line";
        BankLedgerEntry: Record "Bank Account Ledger Entry";
        NextBankRecLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExpandLine(Rec, DepositBankRecLine, IsHandled);
        if IsHandled then
            exit;

        with DepositBankRecLine do begin
            if ("Record Type" <> "Record Type"::Deposit) or
               ("Collapse Status" <> "Collapse Status"::"Collapsed Deposit") or
               ("External Document No." = '')
            then
                exit;
            Delete;

            BankRecLine.SetCurrentKey("Bank Account No.", "Statement No.", "Record Type", "Line No.");
            BankRecLine.SetRange("Bank Account No.", "Bank Account No.");
            BankRecLine.SetRange("Statement No.", "Statement No.");
            BankRecLine.SetRange("Record Type", "Record Type");
            BankRecLine.LockTable();
            if BankRecLine.FindLast() then
                NextBankRecLineNo := BankRecLine."Line No." + 10000
            else
                NextBankRecLineNo := 10000;
            BankRecLine.Reset();

            BankRecSubLine.SetRange("Bank Account No.", "Bank Account No.");
            BankRecSubLine.SetRange("Statement No.", "Statement No.");
            BankRecSubLine.SetRange("Bank Rec. Line No.", "Line No.");
            BankRecSubLine.Find('-');
            repeat
                BankRecLine.Init();
                BankRecLine."Bank Account No." := "Bank Account No.";
                BankRecLine."Statement No." := "Statement No.";
                BankRecLine."Record Type" := "Record Type"::Deposit;
                BankRecLine."Line No." := NextBankRecLineNo;
                BankRecLine."Posting Date" := BankRecSubLine."Posting Date";
                BankRecLine."Document Type" := BankRecSubLine."Document Type";
                BankRecLine."Document No." := BankRecSubLine."Document No.";
                BankRecLine.Description := BankRecSubLine.Description;
                BankRecLine.Amount := BankRecSubLine.Amount;
                BankRecLine.Validate("Currency Code", BankRecSubLine."Currency Code");
                BankRecLine."External Document No." := BankRecSubLine."External Document No.";
                BankRecLine."Bank Ledger Entry No." := BankRecSubLine."Bank Ledger Entry No.";
                BankRecLine."Collapse Status" := "Collapse Status"::"Expanded Deposit Line";
                BankLedgerEntry.Get(BankRecLine."Bank Ledger Entry No.");
                BankRecLine."Shortcut Dimension 1 Code" := BankLedgerEntry."Global Dimension 1 Code";
                BankRecLine."Shortcut Dimension 2 Code" := BankLedgerEntry."Global Dimension 2 Code";
                BankRecLine."Dimension Set ID" := BankLedgerEntry."Dimension Set ID";
                BankRecLine.Validate(Cleared, Cleared);
                BankRecLine.Insert(true);
                BankRecSubLine.Delete();
                NextBankRecLineNo := NextBankRecLineNo + 10000;
            until BankRecSubLine.Next() = 0;
        end;
        DepositBankRecLine := BankRecLine;
    end;

    procedure CollapseLines(var DepositBankRecLine: Record "Bank Rec. Line")
    var
        BankRecLine: Record "Bank Rec. Line";
        BankRecSubLine: Record "Bank Rec. Sub-line";
        TempBankRecSubLine: Record "Bank Rec. Sub-line" temporary;
        TotalDepositAmount: Decimal;
        NextSubLineNo: Integer;
        CollapsedCleared: Boolean;
    begin
        with DepositBankRecLine do begin
            if ("Record Type" <> "Record Type"::Deposit) or
               ("Collapse Status" <> "Collapse Status"::"Expanded Deposit Line") or
               ("External Document No." = '')
            then
                exit;

            BankRecLine.SetCurrentKey("Bank Account No.", "Statement No.", "Record Type", "External Document No.");
            BankRecLine.SetRange("Bank Account No.", "Bank Account No.");
            BankRecLine.SetRange("Statement No.", "Statement No.");
            BankRecLine.SetRange("Record Type", "Record Type");
            BankRecLine.SetRange("External Document No.", "External Document No.");
            if BankRecLine.Count > 1 then begin
                BankRecSubLine.SetRange("Bank Account No.", "Bank Account No.");
                BankRecSubLine.SetRange("Statement No.", "Statement No.");

                TotalDepositAmount := 0;
                CollapsedCleared := true;
                NextSubLineNo := 1;
                BankRecLine.FindSet();
                repeat
                    BankRecSubLine.SetRange("Bank Rec. Line No.", BankRecLine."Line No.");
                    if not BankRecSubLine.FindSet() then begin
                        BankRecSubLine.Init();
                        BankRecSubLine.TransferFields(BankRecLine, false);
                        BankRecSubLine."Bank Account No." := "Bank Account No.";
                        BankRecSubLine."Statement No." := "Statement No.";
                        BankRecSubLine."Bank Rec. Line No." := "Line No.";
                        BankRecSubLine."Line No." := NextSubLineNo;
                        BankRecSubLine.Insert();
                        NextSubLineNo += 1;
                        CopyBankRecSubLineToTemp(TempBankRecSubLine, BankRecSubLine);
                        BankRecSubLine.Delete();
                    end else
                        repeat
                            CopyBankRecSubLineToTemp(TempBankRecSubLine, BankRecSubLine);
                        until BankRecSubLine.Next() = 0;
                    BankRecSubLine.DeleteAll();
                    if not BankRecLine.Cleared then
                        CollapsedCleared := false;
                    TotalDepositAmount := TotalDepositAmount + BankRecLine.Amount;
                    BankRecLine.Delete();
                until BankRecLine.Next() = 0;
                CopyBankRecSubLineFromTemp(TempBankRecSubLine, "Line No.");

                UpdateLedgers;
                "Document Type" := "Document Type"::" ";
                "Document No." := '';
                Amount := TotalDepositAmount;
                Cleared := CollapsedCleared;
                if Cleared then
                    "Cleared Amount" := Amount
                else
                    "Cleared Amount" := 0;
                OnCollapseLinesOnAfterAssignClearedAmount(Rec, DepositBankRecLine);

                "Bank Ledger Entry No." := 0;
                "Check Ledger Entry No." := 0;
                "Shortcut Dimension 1 Code" := '';
                "Shortcut Dimension 2 Code" := '';
                "Collapse Status" := "Collapse Status"::"Collapsed Deposit";

                Insert;
            end else begin
                "Collapse Status" := 0;
                Modify;
            end;
        end;
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec);
    end;

    local procedure UpdateLedgers()
    begin
#if not CLEAN20
        Positive := (Amount > 0);
        BankRecPost.UpdateLedgers(Rec, SetStatus::Cleared);
#endif
    end;

    local procedure CopyBankRecSubLineToTemp(var TempBankRecSubLine: Record "Bank Rec. Sub-line" temporary; BankRecSubLine: Record "Bank Rec. Sub-line")
    begin
        TempBankRecSubLine := BankRecSubLine;
        TempBankRecSubLine.Insert();
    end;

    local procedure CopyBankRecSubLineFromTemp(var TempBankRecSubLine: Record "Bank Rec. Sub-line" temporary; LineNo: Integer)
    var
        BankRecSubLine: Record "Bank Rec. Sub-line";
        NextSubLineNo: Integer;
    begin
        if TempBankRecSubLine.FindSet() then begin
            repeat
                NextSubLineNo += 1;
                BankRecSubLine := TempBankRecSubLine;
                BankRecSubLine."Bank Rec. Line No." := LineNo;
                BankRecSubLine."Line No." := NextSubLineNo;
                BankRecSubLine.Insert();
            until TempBankRecSubLine.Next() = 0;
            TempBankRecSubLine.DeleteAll();
        end;
    end;

    procedure CreateDimFromDefaultDim()
    begin
        CreateDimFromDefaultDim(0);
    end;

    procedure CreateDimFromDefaultDim(FromFieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FromFieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FromFieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1("Account Type".AsInteger()), Rec."Account No.", FromFieldNo = Rec.Fieldno("Account No."));
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1("Bal. Account Type".AsInteger()), Rec."Bal. Account No.", FromFieldNo = Rec.Fieldno("Bal. Account No."));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

#if not CLEAN20
    local procedure RunEventOnBeforeClearAndAssignDefaultDimSetID(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var IsHandled: Boolean)
    var
        DimArrayConversionHelper: Codeunit "Dim. Array Conversion Helper";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        DimArrayConversionHelper.CreateDimTableIDs(Rec, DefaultDimSource, TableID, No);
        OnBeforeClearAndAssignDefaultDimSetID(Rec, TableID, No, IsHandled);
        DimArrayConversionHelper.CreateDefaultDimSourcesFromDimArray(Database::"Bank Rec. Line", DefaultDimSource, TableID, No);
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var BankRecLine: Record "Bank Rec. Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var BankRecLine: Record "Bank Rec. Line"; xBankRecLine: Record "Bank Rec. Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAccountType(var BankRecLine: Record "Bank Rec. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBalAccountType(var BankRecLine: Record "Bank Rec. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUpNewLine(var BankRecLine: Record "Bank Rec. Line"; var LastBankRecLine: Record "Bank Rec. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGenerateDocNo(var BankRecLine: Record "Bank Rec. Line")
    begin
    end;

#if not CLEAN20
    [Obsolete('Replaced by OnBeforeCreateDim()', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearAndAssignDefaultDimSetID(var BankAccRecLine: Record "Bank Rec. Line"; TableID: array[10] of Integer; No: array[10] of Code[20]; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var BankAccRecLine: Record "Bank Rec. Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var BankAccRecLine: Record "Bank Rec. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExpandLine(var BankRecLineRec: Record "Bank Rec. Line"; var DepositBankRecLine: Record "Bank Rec. Line"; IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollapseLinesOnAfterAssignClearedAmount(var BankRecLineRec: Record "Bank Rec. Line"; var DepositBankRecLine: Record "Bank Rec. Line");
    begin
    end;
}

