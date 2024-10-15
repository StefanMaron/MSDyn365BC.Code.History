page 5660 "Depreciation Table Lines"
{
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Depreciation Table Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Period No."; "Period No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the depreciation period that this line applies to.';
                }
                field("Period Depreciation %"; "Period Depreciation %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the depreciation percentage to apply to the period for this line.';

                    trigger OnValidate()
                    begin
                        TotalDeprPercent := CalcDeprPerc("Depreciation Table Code");
                        CurrPage.Update(true);
                    end;
                }
                field("No. of Units in Period"; "No. of Units in Period")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the units produced by the asset this depreciation table applies to, during the period when this line applies.';
                }
                field("Anticipated %"; "Anticipated %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the anticipated depreciation percentage.';

                    trigger OnValidate()
                    begin
                        TotalDeprPercent := CalcDeprPerc("Depreciation Table Code");
                        CurrPage.Update(true);
                    end;
                }
                field("Accelerated/Reduced %"; "Accelerated/Reduced %")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the accelerated or reduced depreciation percent.';

                    trigger OnValidate()
                    begin
                        TotalDeprPercent := CalcDeprPerc("Depreciation Table Code");
                        CurrPage.Update(true);
                    end;
                }
            }
            group(DeprPanel)
            {
                Caption = 'Depreciation Information';
                field(TotalDepreciationPct; TotalDeprPercent)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Total Depreciation %';
                    Editable = false;
                    ToolTip = 'Specifies the total depreciation percent as the sum of the percentages for period depreciation, anticipated depreciation, and accelerated/reduced depreciation.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        TotalDeprPercent := CalcDeprPerc("Depreciation Table Code");
    end;

    trigger OnAfterGetRecord()
    begin
        CalcDeprPerc("Depreciation Table Code");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        NewRecord;
    end;

    var
        TotalDeprPercent: Decimal;

    [Scope('OnPrem')]
    procedure CalcDeprPerc(DeprCode: Code[10]) TotDepr: Decimal
    var
        DeprTableLine: Record "Depreciation Table Line";
        Depr: Decimal;
    begin
        TotDepr := 0;

        DeprTableLine.Reset();
        DeprTableLine.SetRange("Depreciation Table Code", DeprCode);
        if DeprTableLine.Find('-') then
            repeat
                TotDepr += DeprTableLine."Period Depreciation %" +
                  DeprTableLine."Anticipated %" +
                  DeprTableLine."Accelerated/Reduced %";
            until DeprTableLine.Next = 0;
    end;
}

