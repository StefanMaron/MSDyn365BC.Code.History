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
        }
        field(3; "Source Group"; Enum "Price Source Group")
        {
            DataClassification = CustomerContent;
            Caption = 'Source Group';
        }
        field(4; "Source Type"; Enum "Price Source Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Source Type';
            trigger OnValidate()
            begin
                if xRec."Source Type" = "Source Type" then
                    exit;
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source Type", "Source Type");
                CopyFrom(PriceSource);
            end;
        }
        field(5; "Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Source No.';
            trigger OnValidate()
            begin
                if xRec."Source No." = "Source No." then
                    exit;
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
        field(6; "Parent Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Source No.';
            trigger OnValidate()
            begin
                if xRec."Parent Source No." = "Parent Source No." then
                    exit;
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Parent Source No.", "Parent Source No.");
                CopyFrom(PriceSource);
            end;
        }
        field(7; "Source ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Source ID';
            trigger OnValidate()
            begin
                if xRec."Source ID" = "Source ID" then
                    exit;
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
            Caption = 'Amount Type';
        }

        field(10; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(11; "Starting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Starting Date';
            trigger OnValidate()
            begin
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Starting Date", "Starting Date");
                CopyFrom(PriceSource);
            end;
        }
        field(12; "Ending Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Ending Date';
            trigger OnValidate()
            begin
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Ending Date", "Ending Date");
                CopyFrom(PriceSource);
            end;
        }
        field(13; "Price Includes VAT"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Price Includes VAT';
        }
        field(14; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";
        }
        field(15; "Allow Line Disc."; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Allow Line Disc.';
            InitValue = true;
        }
        field(16; "Allow Invoice Disc."; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Allow Invoice Disc.';
            InitValue = true;
        }
        field(17; "No. Series"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
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
    }

    trigger OnInsert()
    begin
        if "Source Group" = "Source Group"::All then
            TestField(Code);
        if Code = '' then
            NoSeriesMgt.InitSeries(GetNoSeries(), xRec."No. Series", 0D, Code, "No. Series");
    end;

    var
        PriceSource: Record "Price Source";
        NoSeriesMgt: Codeunit NoSeriesManagement;

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

    procedure CopyFrom(PriceSource: Record "Price Source")
    begin
        "Source Group" := PriceSource."Source Group";
        "Source Type" := PriceSource."Source Type";
        "Source No." := PriceSource."Source No.";
        "Parent Source No." := PriceSource."Parent Source No.";
        "Source ID" := PriceSource."Source ID";

        "Price Type" := PriceSource."Price Type";
        "Currency Code" := PriceSource."Currency Code";
        "Starting Date" := PriceSource."Starting Date";
        "Ending Date" := PriceSource."Ending Date";
        "Price Includes VAT" := PriceSource."Price Includes VAT";
        "Allow Invoice Disc." := PriceSource."Allow Invoice Disc.";
        "Allow Line Disc." := PriceSource."Allow Line Disc.";
        "VAT Bus. Posting Gr. (Price)" := PriceSource."VAT Bus. Posting Gr. (Price)";
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
    end;

    procedure IsSourceNoAllowed(): Boolean;
    var
        PriceSourceInterface: Interface "Price Source";
    begin
        PriceSourceInterface := "Source Type";
        exit(PriceSourceInterface.IsSourceNoAllowed());
    end;
}