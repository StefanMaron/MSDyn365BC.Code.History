page 5603 "Main Asset Statistics"
{
    Caption = 'Main Asset Statistics';
    DataCaptionExpression = Caption();
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "FA Depreciation Book";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(NoOfComponents; NoOfComponents)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'No. of Components';
                    ToolTip = 'Specifies the number of components in the main asset.';
                }
                field(NoOfSoldComponents; NoOfSoldComponents)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'No. of Sold Components';
                    ToolTip = 'Specifies the number of components from the main asset that the company has sold.';
                }
                field("NoOfComponents + NoOfSoldComponents"; NoOfComponents + NoOfSoldComponents)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Total Components';
                    ToolTip = 'Specifies the number of components that either have been or are part of the main asset.';
                }
                field(FAAcqDate; FAAcqDate)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Acquisition Date';
                    ToolTip = 'Specifies the FA posting date of the first posted acquisition cost.';
                }
                field(GLAcqDate; GLAcqDate)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'G/L Acquisition Date';
                    ToolTip = 'Specifies G/L posting date of the first posted acquisition cost.';
                }
                field(DispDate; DisposalDate)
                {
                    ApplicationArea = All;
                    Caption = 'Disposal Date';
                    ToolTip = 'Specifies the date when the fixed asset was disposed of.';
                    Visible = DispDateVisible;
                }
                field(DispPrice; DisposalPrice)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Proceeds on Disposal';
                    ToolTip = 'Specifies the total proceeds on disposals for the fixed asset. The value is calculated using the entries in the FA Ledger Entries window.';
                    Visible = DispPriceVisible;
                }
                field(GLPrice; GainLoss)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Gain/Loss';
                    ToolTip = 'Specifies the total gain (credit) or loss (debit) for the fixed asset. The field is calculated using the entries in the FA Ledger Entries window. To see the ledger entries that make up the amount shown, click the field.';
                    Visible = GLPriceVisible;
                }
                fixed(Control1903895301)
                {
                    ShowCaption = false;
                    group("Last FA Posting Date")
                    {
                        Caption = 'Last FA Posting Date';
                        field(LastAcqCost; LastAcqCost)
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Acquisition Cost';
                            ToolTip = 'Specifies the total percentage of acquisition cost that can be allocated when acquisition cost is posted.';
                        }
                        field(LastDepreciation; LastDepreciation)
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Depreciation';
                            ToolTip = 'Specifies the total depreciation for the fixed asset.';
                        }
                        field(LastWriteDown; LastWriteDown)
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Write-Down';
                            ToolTip = 'Specifies the total LCY amount of write-down entries for the fixed asset.';
                        }
                        field(LastAppreciation; LastAppreciation)
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Appreciation';
                            ToolTip = 'Specifies the sum that applies to appreciations.';
                        }
                        field(LastCustom1; LastCustom1)
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Custom 1';
                            ToolTip = 'Specifies the total LCY amount for custom 1 entries for the fixed asset.';
                        }
                        field(LastSalvageValue; LastSalvageValue)
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Salvage Value';
                            ToolTip = 'Specifies the salvage value for the fixed asset.';
                        }
                        field(LastCustom2; LastCustom2)
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Custom 2';
                            ToolTip = 'Specifies the total LCY amount for custom 2 entries for the fixed asset.';
                        }
                    }
                    group(Amount)
                    {
                        Caption = 'Amount';
                        field(AcquisitionCost; AcquisitionCost)
                        {
                            ApplicationArea = FixedAssets;
                            AutoFormatType = 1;
                            Caption = 'Acquisition Cost';
                            ToolTip = 'Specifies the total percentage of acquisition cost that can be allocated when acquisition cost is posted.';
                        }
                        field(Depreciation2; Depreciation2)
                        {
                            ApplicationArea = FixedAssets;
                            AutoFormatType = 1;
                            Caption = 'Depreciation';
                            ToolTip = 'Specifies the total depreciation for the fixed asset.';
                        }
                        field(WriteDown; WriteDown)
                        {
                            ApplicationArea = FixedAssets;
                            AutoFormatType = 1;
                            Caption = 'Write-Down';
                            ToolTip = 'Specifies the total LCY amount of write-down entries for the fixed asset.';
                        }
                        field(Appreciation2; Appreciation2)
                        {
                            ApplicationArea = FixedAssets;
                            AutoFormatType = 1;
                            Caption = 'Appreciation';
                            ToolTip = 'Specifies the sum that applies to appreciations.';
                        }
                        field(Custom1; Custom1)
                        {
                            ApplicationArea = FixedAssets;
                            AutoFormatType = 1;
                            Caption = 'Custom 1';
                            ToolTip = 'Specifies the total LCY amount for custom 1 entries for the fixed asset.';
                        }
                        field(SalvageValue; SalvageValue)
                        {
                            ApplicationArea = FixedAssets;
                            AutoFormatType = 1;
                            Caption = 'Salvage Value';
                            ToolTip = 'Specifies the salvage value for the fixed asset.';
                        }
                        field(Custom2; Custom2)
                        {
                            ApplicationArea = FixedAssets;
                            AutoFormatType = 1;
                            Caption = 'Custom 2';
                            ToolTip = 'Specifies the total LCY amount for custom 2 entries for the fixed asset.';
                        }
                    }
                }
                fixed(Control3)
                {
                    ShowCaption = false;
                    group(Control5)
                    {
                        ShowCaption = false;
                        field(BookValue; BookValue)
                        {
                            ApplicationArea = FixedAssets;
                            AutoFormatType = 1;
                            Caption = 'Book Value';
                            ToolTip = 'Specifies the sum that applies to book values.';
                        }
                        field(DeprBasis; DeprBasis)
                        {
                            ApplicationArea = FixedAssets;
                            AutoFormatType = 1;
                            Caption = 'Depreciation Basis';
                            ToolTip = 'Specifies the depreciation basis amount for the fixed asset.';
                        }
                        field(Maintenance2; Maintenance2)
                        {
                            ApplicationArea = FixedAssets;
                            AutoFormatType = 1;
                            Caption = 'Maintenance';
                            ToolTip = 'Specifies the total maintenance cost for the fixed asset. This is calculated from the maintenance ledger entries.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DispPriceVisible := false;
        GLPriceVisible := false;
        DispDateVisible := false;

        ClearAll();
        if "Main Asset/Component" <> "Main Asset/Component"::"Main Asset" then
            exit;
        with FADeprBook do begin
            SetCurrentKey("Depreciation Book Code", "Component of Main Asset");
            SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
            SetRange("Component of Main Asset", Rec."Component of Main Asset");
            if Find('-') then
                repeat
                    if "Disposal Date" > 0D then begin
                        NoOfSoldComponents := NoOfSoldComponents + 1;
                        CalcFields("Proceeds on Disposal", "Gain/Loss");
                        DisposalPrice := DisposalPrice + "Proceeds on Disposal";
                        GainLoss := GainLoss + "Gain/Loss";
                        DisposalDate := GetMinDate(DisposalDate, "Disposal Date");
                    end;
                    if "Disposal Date" = 0D then begin
                        if "Last Acquisition Cost Date" > 0D then begin
                            NoOfComponents := NoOfComponents + 1;
                            CalcFields("Book Value", "Depreciable Basis");
                            BookValue := BookValue + "Book Value";
                            DeprBasis := DeprBasis + "Depreciable Basis";
                            GLAcqDate := GetMinDate(GLAcqDate, "G/L Acquisition Date");
                            FAAcqDate := GetMinDate(FAAcqDate, "Acquisition Date");
                        end;
                        CalcAmount(LastAcqCost, AcquisitionCost, "Last Acquisition Cost Date", "FA Journal Line FA Posting Type"::"Acquisition Cost");
                        CalcAmount(LastDepreciation, Depreciation2, "Last Depreciation Date", "FA Journal Line FA Posting Type"::Depreciation);
                        CalcAmount(LastWriteDown, WriteDown, "Last Write-Down Date", "FA Journal Line FA Posting Type"::"Write-Down");
                        CalcAmount(LastAppreciation, Appreciation2, "Last Appreciation Date", "FA Journal Line FA Posting Type"::Appreciation);
                        CalcAmount(LastCustom1, Custom1, "Last Custom 1 Date", "FA Journal Line FA Posting Type"::"Custom 1");
                        CalcAmount(LastCustom2, Custom2, "Last Custom 2 Date", "FA Journal Line FA Posting Type"::"Custom 2");
                        CalcAmount(LastMaintenance, Maintenance2, "Last Maintenance Date", "FA Journal Line FA Posting Type"::Maintenance);
                        CalcAmount(LastSalvageValue, SalvageValue, "Last Salvage Value Date", "FA Journal Line FA Posting Type"::"Salvage Value");
                    end;
                until Next() = 0;
        end;
        DispPriceVisible := DisposalDate > 0D;
        GLPriceVisible := DisposalDate > 0D;
        DispDateVisible := DisposalDate > 0D;
    end;

    trigger OnInit()
    begin
        DispDateVisible := true;
        GLPriceVisible := true;
        DispPriceVisible := true;
    end;

    var
        FADeprBook: Record "FA Depreciation Book";
        AcquisitionCost: Decimal;
        Depreciation2: Decimal;
        WriteDown: Decimal;
        Appreciation2: Decimal;
        Custom1: Decimal;
        Custom2: Decimal;
        BookValue: Decimal;
        DisposalPrice: Decimal;
        GainLoss: Decimal;
        DeprBasis: Decimal;
        SalvageValue: Decimal;
        Maintenance2: Decimal;
        GLAcqDate: Date;
        FAAcqDate: Date;
        LastAcqCost: Date;
        LastDepreciation: Date;
        LastWriteDown: Date;
        LastAppreciation: Date;
        LastCustom1: Date;
        LastCustom2: Date;
        LastSalvageValue: Date;
        LastMaintenance: Date;
        DisposalDate: Date;
        NoOfComponents: Integer;
        NoOfSoldComponents: Integer;
        [InDataSet]
        DispPriceVisible: Boolean;
        [InDataSet]
        GLPriceVisible: Boolean;
        [InDataSet]
        DispDateVisible: Boolean;

    local procedure CalcAmount(var FADate: Date; var Amount: Decimal; FADate2: Date; FAPostingType: Enum "FA Journal Line FA Posting Type")
    var
        OldAmount: Decimal;
    begin
        OldAmount := Amount;
        if FADate2 = 0D then
            exit;
        with FADeprBook do
            case FAPostingType of
                FAPostingType::"Acquisition Cost":
                    begin
                        CalcFields("Acquisition Cost");
                        Amount := Amount + "Acquisition Cost";
                    end;
                FAPostingType::Depreciation:
                    begin
                        CalcFields(Depreciation);
                        Amount := Amount + Depreciation;
                    end;
                FAPostingType::"Write-Down":
                    begin
                        CalcFields("Write-Down");
                        Amount := Amount + "Write-Down";
                    end;
                FAPostingType::Appreciation:
                    begin
                        CalcFields(Appreciation);
                        Amount := Amount + Appreciation;
                    end;
                FAPostingType::"Custom 1":
                    begin
                        CalcFields("Custom 1");
                        Amount := Amount + "Custom 1";
                    end;
                FAPostingType::"Custom 2":
                    begin
                        CalcFields("Custom 2");
                        Amount := Amount + "Custom 2";
                    end;
                FAPostingType::Maintenance:
                    begin
                        CalcFields(Maintenance);
                        Amount := Amount + Maintenance;
                    end;
                FAPostingType::"Salvage Value":
                    begin
                        CalcFields("Salvage Value");
                        Amount := Amount + "Salvage Value";
                    end;
            end;
        if FADate < FADate2 then
            FADate := FADate2;

        OnAfterCalcAmount(Amount, OldAmount, FAPostingType, FADeprBook);
    end;

    local procedure GetMinDate(Date1: Date; Date2: Date): Date
    begin
        if (Date1 = 0D) or (Date2 < Date1) then
            exit(Date2);

        exit(Date1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcAmount(var Amount: Decimal; OldAmount: Decimal; FAPostingType: Enum "FA Journal Line FA Posting Type"; FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;
}

