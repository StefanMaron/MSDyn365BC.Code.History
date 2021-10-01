table 7000 "Price List Header"
{
    Caption = 'Price List';

    fields
    {
        field(1; Code; Code[20])
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                if Code <> xRec.Code then begin
                    NoSeriesMgt.TestManual(GetNoSeries());
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[250])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(3; "Source Group"; Enum "Price Source Group")
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to Group';
        }
        field(4; "Source Type"; Enum "Price Source Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to Type';
            trigger OnValidate()
            begin
                if xRec."Source Type" = "Source Type" then
                    exit;

                CheckIfLinesExist(FieldCaption("Source Type"));
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source Type", "Source Type");
                CopyFrom(PriceSource);
                "Amount Type" := PriceSource.GetDefaultAmountType();
            end;
        }
        field(5; "Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to No.';
            trigger OnValidate()
            begin
                if xRec."Source No." = "Source No." then
                    exit;

                CheckIfLinesExist(FieldCaption("Source No."));
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source No.", "Source No.");
                CopyFrom(PriceSource);
            end;

            trigger OnLookup()
            begin
                LookupSourceNo();
            end;
        }
        field(6; "Parent Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to Parent No.';
            trigger OnValidate()
            begin
                if xRec."Parent Source No." = "Parent Source No." then
                    exit;

                TestStatusDraft();
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Parent Source No.", "Parent Source No.");
                CopyFrom(PriceSource);
            end;
        }
        field(7; "Source ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to ID';
            trigger OnValidate()
            begin
                if xRec."Source ID" = "Source ID" then
                    exit;

                TestStatusDraft();
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source ID", "Source ID");
                CopyFrom(PriceSource);
            end;
        }
        field(8; "Price Type"; Enum "Price Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Price Type';
        }
        field(9; "Amount Type"; Enum "Price Amount Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Defines';

            trigger OnValidate()
            begin
                CopyTo(PriceSource);
                PriceSource.VerifyAmountTypeForSourceType("Amount Type");
            end;
        }
        field(10; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" <> xRec."Currency Code" then
                    CheckIfLinesExist(FieldCaption("Currency Code"));
            end;
        }
        field(11; "Starting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Starting Date';
            trigger OnValidate()
            begin
                if "Starting Date" = xRec."Starting Date" then
                    exit;

                TestStatusDraft();
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Starting Date", "Starting Date");
                CopyFrom(PriceSource);

                UpdateLines(FieldNo("Starting Date"), FieldCaption("Starting Date"));
            end;
        }
        field(12; "Ending Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Ending Date';
            trigger OnValidate()
            begin
                if "Ending Date" = xRec."Ending Date" then
                    exit;

                TestStatusDraft();
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Ending Date", "Ending Date");
                CopyFrom(PriceSource);

                UpdateLines(FieldNo("Ending Date"), FieldCaption("Ending Date"));
            end;
        }
        field(13; "Price Includes VAT"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Price Includes VAT';

            trigger OnValidate()
            begin
                if "Price Includes VAT" <> xRec."Price Includes VAT" then
                    CheckIfLinesExist(FieldCaption("Price Includes VAT"));
            end;
        }
        field(14; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if "VAT Bus. Posting Gr. (Price)" <> xRec."VAT Bus. Posting Gr. (Price)" then
                    CheckIfLinesExist(FieldCaption("VAT Bus. Posting Gr. (Price)"));
            end;
        }
        field(15; "Allow Line Disc."; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Allow Line Disc.';
            InitValue = true;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(16; "Allow Invoice Disc."; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Allow Invoice Disc.';
            InitValue = true;

            trigger OnValidate()
            begin
                TestStatusDraft();
            end;
        }
        field(17; "No. Series"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(18; Status; Enum "Price Status")
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Status <> xRec.Status then
                    if not UpdateStatus() then
                        Status := xRec.Status;
            end;
        }
        field(19; "Filter Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(20; "Allow Updating Defaults"; Boolean)
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if xRec."Allow Updating Defaults" and not Rec."Allow Updating Defaults" then
                    CheckIfLinesExist(Rec.FieldCaption("Allow Updating Defaults"));
            end;
        }
    }

    keys
    {
        key(PK; Code)
        {
        }
        key(Key1; "Source Type", "Source No.", "Starting Date", "Currency Code")
        {
        }
        key(Key2; Status, "Price Type", "Source Group", "Source Type", "Source No.", "Currency Code", "Starting Date", "Ending Date")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Source Group" = "Source Group"::All then
            TestField(Code);
        if Code = '' then
            NoSeriesMgt.InitSeries(GetNoSeries(), xRec."No. Series", 0D, Code, "No. Series");
    end;

    trigger OnDelete()
    var
        PriceListLine: Record "Price List Line";
    begin
        if (Status = Status::Active) and not IsEditable() then
            Error(CannotDeleteActivePriceListErr, Code);

        PriceListLine.SetRange("Price List Code", Code);
        PriceListLine.DeleteAll();
    end;

    var
        PriceSource: Record "Price Source";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        ConfirmUpdateQst: Label 'Do you want to update %1 in the price list lines?', Comment = '%1 - the field caption';
        LinesExistErr: Label 'You cannot change %1 because one or more lines exist.', Comment = '%1 - the field caption';
        StatusUpdateQst: Label 'Do you want to update status to %1?', Comment = '%1 - status value: Draft, Active, or Inactive';
        CannotDeleteActivePriceListErr: Label 'You cannot delete the active price list %1.', Comment = '%1 - the price list code.';

    procedure IsEditable() Result: Boolean;
    begin
        Result := (Status = Status::Draft) or (Status = Status::Active) and IsAllowedEditingActivePrice();
    end;

    local procedure IsAllowedEditingActivePrice(): Boolean;
    var
        PriceListManagement: Codeunit "Price List Management";
    begin
        exit(PriceListManagement.IsAllowedEditingActivePrice("Price Type"));
    end;

    procedure IsCRMIntegrationAllowed(StatusActiveFilterApplied: Boolean): Boolean;
    begin
        exit(
            ((StatusActiveFilterApplied and (Rec.Status = Rec.Status::Active)) or not StatusActiveFilterApplied) and
            not Rec."Allow Updating Defaults");
    end;

    procedure AssistEditCode(xPriceListHeader: Record "Price List Header"): Boolean
    var
        PriceListHeader: Record "Price List Header";
    begin
        if "Source Group" = "Source Group"::All then
            exit(false);

        PriceListHeader := Rec;
        if NoSeriesMgt.SelectSeries(GetNoSeries(), xPriceListHeader."No. Series", PriceListHeader."No. Series") then begin
            NoSeriesMgt.SetSeries(PriceListHeader.Code);
            Rec := PriceListHeader;
            exit(true);
        end;
    end;

    procedure BlankDefaults()
    begin
        if Rec."Allow Updating Defaults" then begin
            Rec."Source Type" := Rec."Source Type"::All;
            Rec."Parent Source No." := '';
            Rec."Source No." := '';
            Rec."Currency Code" := '';
            Rec."Starting Date" := 0D;
            Rec."Ending Date" := 0D;
        end;
    end;

    local procedure GetNoSeries(): Code[20];
    var
        JobsSetup: Record "Jobs Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        case "Source Group" of
            "Source Group"::Customer:
                begin
                    SalesReceivablesSetup.Get();
                    SalesReceivablesSetup.TestField("Price List Nos.");
                    exit(SalesReceivablesSetup."Price List Nos.");
                end;
            "Source Group"::Vendor:
                begin
                    PurchasesPayablesSetup.Get();
                    PurchasesPayablesSetup.TestField("Price List Nos.");
                    exit(PurchasesPayablesSetup."Price List Nos.");
                end;
            "Source Group"::Job:
                begin
                    JobsSetup.Get();
                    JobsSetup.TestField("Price List Nos.");
                    exit(JobsSetup."Price List Nos.");
                end;
        end;
    end;

    local procedure CheckIfLinesExist(Caption: Text)
    var
        PriceListLine: Record "Price List Line";
        ErrorMsg: Text;
    begin
        if IsTemporary() or (Code = '') then
            exit;
        TestStatusDraft();
        if "Allow Updating Defaults" then
            exit;
        PriceListLine.SetRange("Price List Code", Code);
        if not PriceListLine.IsEmpty() then begin
            ErrorMsg := StrSubstNo(LinesExistErr, Caption);
            Error(ErrorMsg);
        end;
    end;

    procedure CopyFrom(PriceSource: Record "Price Source")
    begin
        "Price Type" := PriceSource."Price Type";
        "Source Group" := PriceSource."Source Group";
        if "Source Group" = "Source Group"::All then
            case "Price Type" of
                "Price Type"::Sale:
                    "Source Group" := "Source Group"::Customer;
                "Price Type"::Purchase:
                    "Source Group" := "Source Group"::Vendor;
            end;
        "Source Type" := PriceSource."Source Type";
        "Source No." := PriceSource."Source No.";
        "Parent Source No." := PriceSource."Parent Source No.";
        "Source ID" := PriceSource."Source ID";
        "Filter Source No." := PriceSource."Filter Source No.";

        "Currency Code" := PriceSource."Currency Code";
        "Starting Date" := PriceSource."Starting Date";
        "Ending Date" := PriceSource."Ending Date";
        "Price Includes VAT" := PriceSource."Price Includes VAT";
        "Allow Invoice Disc." := PriceSource."Allow Invoice Disc.";
        "Allow Line Disc." := PriceSource."Allow Line Disc.";
        "VAT Bus. Posting Gr. (Price)" := PriceSource."VAT Bus. Posting Gr. (Price)";

        OnAfterCopyFromPriceSource(PriceSource);
    end;

    procedure CopyTo(var PriceSource: Record "Price Source")
    begin
        PriceSource."Source Group" := "Source Group";
        PriceSource."Source Type" := "Source Type";
        PriceSource."Source No." := "Source No.";
        PriceSource."Parent Source No." := "Parent Source No.";
        PriceSource."Source ID" := "Source ID";

        PriceSource."Price Type" := "Price Type";
        PriceSource."Currency Code" := "Currency Code";
        PriceSource."Starting Date" := "Starting Date";
        PriceSource."Ending Date" := "Ending Date";
        PriceSource."Price Includes VAT" := "Price Includes VAT";
        PriceSource."Allow Invoice Disc." := "Allow Invoice Disc.";
        PriceSource."Allow Line Disc." := "Allow Line Disc.";
        PriceSource."VAT Bus. Posting Gr. (Price)" := "VAT Bus. Posting Gr. (Price)";

        OnAfterCopyToPriceSource(PriceSource);
    end;

    procedure IsSourceNoAllowed(): Boolean;
    var
        PriceSourceInterface: Interface "Price Source";
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.IsSourceNoAllowed());
    end;

    procedure UpdateAmountType()
    var
        xAmountType: Enum "Price Amount Type";
    begin
        xAmountType := "Amount Type";
        "Amount Type" := CalcAmountType();
        if "Amount Type" <> xAmountType then
            Modify()
    end;

    local procedure CalcAmountType(): Enum "Price Amount Type";
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Price List Code", Code);
        if PriceListLine.IsEmpty() then
            exit("Amount Type"::Any);

        PriceListLine.SetRange("Amount Type", "Amount Type"::Any);
        if not PriceListLine.IsEmpty() then
            exit("Amount Type"::Any);

        PriceListLine.SetRange("Amount Type", "Amount Type"::Price);
        if PriceListLine.IsEmpty() then
            exit("Amount Type"::Discount);

        PriceListLine.SetRange("Amount Type", "Amount Type"::Discount);
        if PriceListLine.IsEmpty() then
            exit("Amount Type"::Price);

        exit("Amount Type"::Any);
    end;

    local procedure UpdateLines(FieldId: Integer; Caption: Text)
    var
        PriceListLine: Record "Price List Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if IsTemporary() then
            exit;
        PriceListLine.SetRange("Price List Code", Code);
        if PriceListLine.IsEmpty() then
            exit;

        if "Allow Updating Defaults" then
            if not ConfirmManagement.GetResponse(StrSubstNo(ConfirmUpdateQst, Caption), true) then
                exit;

        case FieldId of
            FieldNo("Starting Date"):
                PriceListLine.ModifyAll("Starting Date", "Starting Date");
            FieldNo("Ending Date"):
                PriceListLine.ModifyAll("Ending Date", "Ending Date");
        end
    end;

    local procedure TestStatusDraft()
    begin
        if not IsEditable() then
            TestField(Status, Status::Draft);
    end;

    procedure HasDraftLines(): Boolean;
    var
        PriceListLine: Record "Price List Line";
    begin
        exit(HasDraftLines(PriceListLine));
    end;

    procedure HasDraftLines(var PriceListLine: Record "Price List Line") Result: Boolean;
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasDraftLines(PriceListLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if (Status <> Status::Active) or not IsEditable() then
            exit(false);
        PriceListLine.SetRange("Price List Code", Code);
        PriceListLine.SetRange(Status, Status::Draft);
        exit(not PriceListLine.IsEmpty());
    end;

    procedure LookupSourceNo() Result: Boolean;
    begin
        CopyTo(PriceSource);
        if PriceSource.LookupNo() then begin
            CheckIfLinesExist(FieldCaption("Source No."));
            CopyFrom(PriceSource);
            Result := true;
        end;
    end;

    local procedure UpdateStatus() Updated: Boolean;
    var
        PriceListLine: Record "Price List Line";
        ConfirmManagement: Codeunit "Confirm Management";
        PriceListManagement: Codeunit "Price List Management";
    begin
        if Status = Status::Active then
            VerifySource();

        Updated := true;
        PriceListLine.SetRange("Price List Code", Code);
        if PriceListLine.IsEmpty() then
            exit;

        if Status = Status::Active then begin
            PriceListManagement.VerifyLines(PriceListLine);
            if not PriceListManagement.ResolveDuplicatePrices(Rec) then
                exit(false);
        end;

        if ConfirmManagement.GetResponse(StrSubstNo(StatusUpdateQst, Status), true) then
            PriceListLine.ModifyAll(Status, Status)
        else
            Updated := false
    end;

    local procedure VerifyParentSource() Result: Boolean;
    var
        PriceSourceLocal: Record "Price Source";
        PriceSourceInterface: Interface "Price Source";
    begin
        CopyTo(PriceSourceLocal);
        PriceSourceInterface := "Source Type";
        Result := PriceSourceInterface.VerifyParent(PriceSourceLocal);
    end;

    local procedure VerifySource()
    begin
        if VerifyParentSource() then
            TestField("Parent Source No.")
        else
            TestField("Parent Source No.", '');

        if IsSourceNoAllowed() then
            TestField("Source No.")
        else
            TestField("Source No.", '');
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyFromPriceSource(PriceSource: Record "Price Source")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCopyToPriceSource(var PriceSource: Record "Price Source")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasDraftLines(var PriceListLine: Record "Price List Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}