table 10140 "Deposit Header"
{
    Caption = 'Deposit Header';
    DataCaptionFields = "No.";
#pragma warning disable AS0074
#if not CLEAN21
    LookupPageID = "Deposit List";
#endif
    ObsoleteReason = 'Replaced by new Bank Deposits extension';
#if not CLEAN21
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#endif
#pragma warning restore AS0074

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    GLSetup.Get();
                    NoSeriesMgt.TestManual(GLSetup."Deposit Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";

            trigger OnValidate()
            var
                DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
            begin
                BankAccount.Get("Bank Account No.");
                GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                GenJnlLine.ModifyAll("Bal. Account No.", "Bank Account No.", true);

                Validate("Currency Code", BankAccount."Currency Code");
                "Bank Acc. Posting Group" := BankAccount."Bank Acc. Posting Group";
                "Language Code" := BankAccount."Language Code";

                DimMgt.AddDimSource(DefaultDimSource, Database::"Bank Account", Rec."Bank Account No.");
                CreateDim(DefaultDimSource);
            end;
        }
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                UpdateCurrencyFactor();
                if "Currency Code" <> xRec."Currency Code" then begin
                    GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                    GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                    if GenJnlLine.FindSet(true) then
                        repeat
                            GenJnlLine.Validate("Currency Code", "Currency Code");
                            GenJnlLine.Modify(true);
                        until GenJnlLine.Next() = 0;
                end;
            end;
        }
        field(4; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                TestField("Posting Date");
                UpdateCurrencyFactor();
                if "Document Date" = 0D then
                    "Document Date" := "Posting Date";
                GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                if GenJnlLine.FindSet(true) then
                    repeat
                        GenJnlLine.Validate("Posting Date", "Posting Date");
                        GenJnlLine.Modify(true);
                    until GenJnlLine.Next() = 0;
            end;
        }
        field(6; "Total Deposit Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Deposit Amount';
        }
        field(7; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                if "Posting Date" = 0D then
                    Validate("Posting Date", "Document Date");
            end;
        }
        field(8; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                Modify();
            end;
        }
        field(9; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                Modify();
            end;
        }
        field(10; "Bank Acc. Posting Group"; Code[20])
        {
            Caption = 'Bank Acc. Posting Group';
            TableRelation = "Bank Account Posting Group";
        }
        field(11; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(12; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(13; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(14; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(15; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(16; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(17; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            Editable = false;
            TableRelation = "Gen. Journal Template";
        }
        field(18; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            Editable = false;
            TableRelation = "Gen. Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(21; Comment; Boolean)
        {
            CalcFormula = Exist("Bank Comment Line" WHERE("Table Name" = CONST(Deposit),
                                                           "Bank Account No." = FIELD("Bank Account No."),
                                                           "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; "Total Deposit Lines"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = - Sum("Gen. Journal Line".Amount WHERE("Journal Template Name" = FIELD("Journal Template Name"),
                                                                 "Journal Batch Name" = FIELD("Journal Batch Name")));
            Caption = 'Total Deposit Lines';
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
                ShowDocDim();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.")
        {
        }
        key(Key3; "Journal Template Name", "Journal Batch Name")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        GLSetup.Get();
        InitInsert();
    end;

    trigger OnRename()
    begin
        Error(Text003, TableCaption);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        CurrExchRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        DepositHeader2: Record "Deposit Header";
        GenJnlBatch: Record "Gen. Journal Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        GenJnlManagement: Codeunit GenJnlManagement;
        Text000: Label 'Deposit %1 %2';
        Text002: Label 'Only one %1 is allowed for each %2. You can use Deposit, Change Batch if you want to create a new Deposit.';
        Text003: Label 'You cannot rename a %1.';

    local procedure InitInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInitInsertOnBeforeInitSeries(xRec, IsHandled);
        if not IsHandled then
            if "No." = '' then begin
                TestNoSeries();
                NoSeriesMgt.InitSeries(GetNoSeriesCode(), xRec."No. Series", "Posting Date", "No.", "No. Series");
            end;

        OnInitInsertOnBeforeInitRecord(xRec);
        InitRecord();
    end;

    procedure InitRecord()
    begin
        "Journal Template Name" := GetRangeMax("Journal Template Name");
        "Journal Batch Name" := GetRangeMax("Journal Batch Name");
        GenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlManagement.LookupName("Journal Batch Name", GenJnlLine);
        FilterGroup(2);
        SetRange("Journal Batch Name", "Journal Batch Name");
        FilterGroup(0);
        DepositHeader2.Copy(Rec);
        DepositHeader2.Reset();
        DepositHeader2.SetRange("Journal Template Name", "Journal Template Name");
        DepositHeader2.SetRange("Journal Batch Name", "Journal Batch Name");
        if DepositHeader2.FindFirst() then
            Error(Text002, TableCaption(), GenJnlBatch.TableCaption());

        if "Posting Date" = 0D then
            Validate("Posting Date", WorkDate());
        "Posting Description" := StrSubstNo(Text000, FieldName("No."), "No.");

        GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        if (GenJnlBatch."Bal. Account Type" = GenJnlBatch."Bal. Account Type"::"Bank Account") and
           (GenJnlBatch."Bal. Account No." <> '')
        then
            Validate("Bank Account No.", GenJnlBatch."Bal. Account No.");

        "Reason Code" := GenJnlBatch."Reason Code";

        OnAfterInitRecord(Rec);
    end;

    local procedure GetNoSeriesCode(): Code[20]
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        GLSetup.Get();
        IsHandled := false;
        OnBeforeGetNoSeriesCode(Rec, GLSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit;

        NoSeriesCode := GLSetup."Deposit Nos.";
        OnAfterGetNoSeriesCode(Rec, NoSeriesCode);
        exit(NoSeriesCode);
    end;

    local procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        GLSetup.Get();
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, IsHandled);
        if not IsHandled then
            GLSetup.TestField("Deposit Nos.");

        OnAfterTestNoSeries(Rec);
    end;

    local procedure UpdateCurrencyFactor()
    var
        CurrencyDate: Date;
    begin
        if "Currency Code" <> '' then begin
            if "Posting Date" <> 0D then
                CurrencyDate := "Posting Date"
            else
                CurrencyDate := WorkDate();
            "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
        end else
            "Currency Factor" := 0;
    end;

    local procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
            DimMgt.GetDefaultDimID(DefaultDimSource, SourceCodeSetup.Deposits, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

    local procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure AssistEdit(OldDepositHeader: Record "Deposit Header"): Boolean
    var
        DepositHeader: Record "Deposit Header";
    begin
        with DepositHeader do begin
            DepositHeader := Rec;
            GLSetup.Get();
            GLSetup.TestField("Deposit Nos.");
            if NoSeriesMgt.SelectSeries(GLSetup."Deposit Nos.", OldDepositHeader."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := DepositHeader;
                exit(true);
            end;
        end;
        exit(false);
    end;

    procedure ShowDocDim()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2', "Bank Account No.", "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAferShowDocDim(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var DepositHeader: Record "Deposit Header"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var DepositHeader: Record "Deposit Header"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var DepositHeader: Record "Deposit Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestNoSeries(var DepositHeader: Record "Deposit Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var DepositHeader: Record "Deposit Header"; GLSetup: Record "General Ledger Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(var DepositHeader: Record "Deposit Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInitInsertOnBeforeInitSeries(var xDepositHeader: Record "Deposit Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInitInsertOnBeforeInitRecord(var xDepositHeader: Record "Deposit Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAferShowDocDim(var DepositHeader: Record "Deposit Header")
    begin
    end;
}

