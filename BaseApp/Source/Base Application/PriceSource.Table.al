table 7005 "Price Source"
{
#pragma warning disable AS0034
    TableType = Temporary;
#pragma warning restore AS0034

    fields
    {
        field(1; "Source Type"; Enum "Price Source Type")
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                SetGroup();
                InitSource();
            end;
        }
        field(2; "Source ID"; Guid)
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if IsNullGuid("Source ID") then
                    InitSource()
                else begin
                    PriceSourceInterface := "Source Type";
                    PriceSourceInterface.GetNo(Rec);
                    SetFilterSourceNo();
                end;
            end;
        }
        field(3; "Source No."; Code[20])
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if "Source No." = '' then
                    InitSource()
                else begin
                    PriceSourceInterface := "Source Type";
                    PriceSourceInterface.GetId(Rec);
                    SetFilterSourceNo();
                end;
            end;
        }
        field(4; "Parent Source No."; Code[20])
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                PriceSourceInterface := "Source Type";
                PriceSourceInterface.VerifyParent(Rec);
                "Source No." := '';
                Clear("Source ID");
                "Filter Source No." := "Parent Source No.";
            end;
        }
        field(5; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(6; Level; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(7; "Source Group"; Enum "Price Source Group")
        {
            DataClassification = SystemMetadata;
        }
        field(8; "Price Type"; Enum "Price Type")
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Currency Code"; Code[10])
        {
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(12; "Starting Date"; Date)
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                VerifyDates();
            end;
        }
        field(13; "Ending Date"; Date)
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                VerifyDates();
            end;
        }
        field(19; "Filter Source No."; Code[20])
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(21; "Allow Line Disc."; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(22; "Allow Invoice Disc."; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(23; "Price Includes VAT"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(24; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
        }
        key(Level; Level)
        {
        }
    }

    var
        PriceSourceInterface: Interface "Price Source";
        StartingDateErr: Label 'Starting Date cannot be after Ending Date.';
        CampaignDateErr: Label 'If Source Type is Campaign, then you can only change Starting Date and Ending Date from the Campaign Card.';

    trigger OnInsert()
    begin
        "Entry No." := GetLastEntryNo() + 1;
    end;

    procedure NewEntry(SourceType: Enum "Price Source Type"; NewLevel: Integer)
    begin
        Init();
        Level := NewLevel;
        Validate("Source Type", SourceType);
    end;

    local procedure GetLastEntryNo(): Integer;
    var
        TempPriceSource: Record "Price Source" temporary;
    begin
        TempPriceSource.Copy(Rec, true);
        TempPriceSource.Reset();
        if TempPriceSource.FindLast() then
            exit(TempPriceSource."Entry No.");
    end;

    procedure InitSource()
    begin
        Clear("Source ID");
        "Parent Source No." := '';
        "Source No." := '';
        "Filter Source No." := '';
        "Currency Code" := '';
        GetPriceType();
    end;

    local procedure GetPriceType()
    begin
        case "Source Group" of
            "Source Group"::Customer:
                "Price Type" := "Price Type"::Sale;
            "Source Group"::Vendor:
                "Price Type" := "Price Type"::Purchase;
        end;
    end;

    local procedure SetGroup()
    var
        SourceGroupInterface: Interface "Price Source Group";
    begin
        SourceGroupInterface := "Source Type";
        "Source Group" := SourceGroupInterface.GetGroup();
    end;

    procedure GetGroupNo(): Code[20]
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.GetGroupNo(Rec));
    end;

    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.IsForAmountType(AmountType))
    end;

    procedure IsSourceNoAllowed(): Boolean;
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.IsSourceNoAllowed());
    end;

    procedure LookupNo() Result: Boolean;
    begin
        PriceSourceInterface := "Source Type";
        Result := PriceSourceInterface.IsLookupOK(Rec);
    end;

    procedure FilterPriceLines(var PriceListLine: Record "Price List Line") Result: Boolean;
    begin
        PriceListLine.SetRange("Source Type", "Source Type");
        if IsSourceNoAllowed() then begin
            if "Source No." = '' then
                exit;

            PriceListLine.SetRange("Source No.", "Source No.");
            if "Parent Source No." <> '' then
                PriceListLine.SetRange("Parent Source No.", "Parent Source No.");
        end else
            PriceListLine.SetRange("Source No.");
    end;

    local procedure VerifyDates()
    begin
        PriceSourceInterfaceVerifyDate();
        if ("Ending Date" <> 0D) and ("Starting Date" <> 0D) and ("Ending Date" < "Starting Date") then
            Error(StartingDateErr);
    end;

    // Should be a method in Price Source Interface
    local procedure PriceSourceInterfaceVerifyDate()
    begin
        if "Source Type" = "Source Type"::Campaign then
            Error(CampaignDateErr);
    end;

    local procedure SetFilterSourceNo()
    begin
        if "Parent Source No." <> '' then
            "Filter Source No." := "Parent Source No."
        else
            "Filter Source No." := "Source No."
    end;
}