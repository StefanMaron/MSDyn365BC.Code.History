table 7008 "Dtld. Price Calculation Setup"
{
    Caption = 'Detailed Price Calculation Setup';
    DrillDownPageID = "Dtld. Price Calculation Setup";
    LookupPageID = "Dtld. Price Calculation Setup";

    fields
    {
        field(1; "Line No."; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Setup Code"; Code[100])
        {
            TableRelation = "Price Calculation Setup".Code where(Enabled = const(true));

            trigger OnValidate()
            var
                PriceCalculationSetup: Record "Price Calculation Setup";
            begin
                PriceCalculationSetup.Get("Setup Code");
                Type := PriceCalculationSetup.Type;
                Method := PriceCalculationSetup.Method;
                Implementation := PriceCalculationSetup.Implementation;
                "Group Id" := PriceCalculationSetup."Group Id";
                Validate("Asset Type", PriceCalculationSetup."Asset Type");
                Enabled := true;
            end;
        }
        field(3; Method; Enum "Price Calculation Method")
        {
            Editable = false;
        }
        field(4; Type; Enum "Price Type")
        {
            Editable = false;
        }
        field(5; "Asset Type"; Enum "Price Asset Type")
        {
            Caption = 'Product Type';
            Editable = false;

            trigger OnValidate()
            begin
                if "Asset Type" <> xRec."Asset Type" then
                    "Asset No." := '';
            end;
        }
        field(6; "Asset No."; Code[20])
        {
            Caption = 'Product No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                xRec.CopyTo(PriceAsset);
                PriceAsset.Validate("Asset No.", "Asset No.");
                CopyFrom(PriceAsset);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupNo() then
                    CopyFrom(PriceAsset);
            end;
        }
        field(7; "Source Group"; Enum "Price Source Group")
        {
            Caption = 'Applies-to Group';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Source Group" <> xRec."Source Group" then begin
                    Validate("Source Type", "Source Group".AsInteger());
                    "Source No." := '';
                end;
            end;
        }

        field(8; "Source Type"; Enum "Price Source Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to Type';
            Editable = false;
            trigger OnValidate()
            begin
                VerifySourceType();
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source Type", "Source Type");
                CopyFrom(PriceSource);
            end;
        }
        field(9; "Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Applies-to No.';
            trigger OnValidate()
            begin
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source No.", "Source No.");
                CopyFrom(PriceSource);
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceSource);
                PriceSource.LookupNo();
                CopyFrom(PriceSource);
            end;
        }
        field(10; Implementation; Enum "Price Calculation Handler")
        {
            Editable = false;
        }
        field(11; "Group Id"; Code[100])
        {
            DataClassification = SystemMetadata;
        }
        field(12; Enabled; Boolean)
        {
        }
    }
    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Group Id", Enabled)
        {
        }
    }

    trigger OnInsert()
    begin
        Enabled := true;
    end;

    protected var
        PriceAsset: Record "Price Asset";
        PriceSource: Record "Price Source";

    var
        NotSupportedSourceTypeErr: label 'Not supported source type %1 for the source group %2.',
            Comment = '%1 - source type value, %2 - source group value';

    local procedure CopyFrom(PriceAsset: Record "Price Asset")
    begin
        "Asset Type" := PriceAsset."Asset Type";
        "Asset No." := PriceAsset."Asset No.";
    end;

    local procedure CopyFrom(PriceSource: Record "Price Source")
    begin
        "Source Type" := PriceSource."Source Type";
        "Source No." := PriceSource."Source No.";
    end;

    procedure CopyTo(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Asset Type" := "Asset Type";
        PriceAsset."Asset No." := "Asset No.";
    end;

    procedure CopyTo(var PriceSource: Record "Price Source")
    begin
        PriceSource."Source Type" := "Source Type";
        PriceSource."Source No." := "Source No.";
    end;

    local procedure VerifySourceType()
    var
        PriceSourceGroup: Interface "Price Source Group";
    begin
        PriceSourceGroup := "Source Group";
        if not PriceSourceGroup.IsSourceTypeSupported("Source Type") then
            Error(NotSupportedSourceTypeErr, "Source Type", "Source Group");
    end;
}

