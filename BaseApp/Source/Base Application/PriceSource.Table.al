table 7005 "Price Source"
{
    fields
    {
        field(1; "Source Type"; Enum "Price Source Type")
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if "Source Type" = xRec."Source Type" then
                    exit;
                InitSource();
                SetGroup();
            end;
        }
        field(2; "Source ID"; Guid)
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if "Source ID" = xRec."Source ID" then
                    exit;
                if IsNullGuid("Source ID") then
                    InitSource()
                else begin
                    PriceSourceInterface := "Source Type";
                    PriceSourceInterface.GetNo(Rec);
                end;
            end;
        }
        field(3; "Source No."; Code[20])
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if "Source No." = xRec."Source No." then
                    exit;
                if "Source No." = '' then
                    InitSource()
                else begin
                    PriceSourceInterface := "Source Type";
                    PriceSourceInterface.GetId(Rec)
                end;
            end;
        }
        field(4; "Parent Source No."; Code[20])
        {
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if "Parent Source No." = xRec."Parent Source No." then
                    exit;
                PriceSourceInterface := "Source Type";
                PriceSourceInterface.VerifyParent(Rec);
                "Source No." := '';
                Clear("Source ID");
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

}