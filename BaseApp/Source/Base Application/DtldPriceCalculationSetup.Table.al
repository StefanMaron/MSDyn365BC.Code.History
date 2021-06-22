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
            Editable = false;
            trigger OnValidate()
            begin
                if "Asset Type" <> xRec."Asset Type" then
                    "Asset No." := '';
            end;
        }
        field(6; "Asset No."; Code[20])
        {
        }
        field(7; "Source Group"; Enum "Price Source Group")
        {
            DataClassification = CustomerContent;
            Caption = 'Source Group';
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
            Caption = 'Source Type';
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
            Caption = 'Source No.';
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
    }

    trigger OnInsert()
    begin
        Enabled := true;
    end;

    protected var
        PriceSource: Record "Price Source";

    var
        NotSupportedSourceTypeErr: label 'Not supported source type %1 for the source group %2.',
            Comment = '%1 - source type value, %2 - source group value';

    local procedure CopyFrom(PriceSource: Record "Price Source")
    begin
        "Source Type" := PriceSource."Source Type";
        "Source No." := PriceSource."Source No.";
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

