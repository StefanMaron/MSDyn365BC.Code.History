report 3010536 "Adjust Exchange Rates G/L"
{
    DefaultLayout = RDLC;
    RDLCLayout = './AdjustExchangeRatesGL.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Adjust Exchange Rates G/L';
    UsageCategory = ReportsAndAnalysis;
    AllowScheduling = false;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Currency Code";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(KeyDate; Format(KeyDate))
            {
            }
            column(No_GLAccount; "No.")
            {
            }
            column(Name_GLAccount; Name)
            {
            }
            column(CurrencyCode_GLAccount; "Currency Code")
            {
            }
            column(BalanceatDateFCY_GLAccount; "Balance at Date (FCY)")
            {
            }
            column(BalanceatDate_GLAccount; "Balance at Date")
            {
            }
            column(AvgExRate; AvgExRate)
            {
                DecimalPlaces = 2 : 5;
            }
            column(CurrRate; CurrRate)
            {
                DecimalPlaces = 2 : 5;
            }
            column(Correction; Correction)
            {
            }
            column(EMU; EMU)
            {
            }
            column(AdjustExchangeRatesGLCaption; AdjustExchangeRatesGLCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(KeyDateCaption; KeyDateCaptionLbl)
            {
            }
            column(CorrectionCaption; CorrectionCaptionLbl)
            {
            }
            column(ExrateOnKeyDateCaption; ExrateOnKeyDateCaptionLbl)
            {
            }
            column(AvgExRateCaption; AvgExRateCaptionLbl)
            {
            }
            column(BalanceAtDateCaption; BalanceAtDateCaptionLbl)
            {
            }
            column(BalanceAtDateFCYCaption; BalanceAtDateFCYCaptionLbl)
            {
            }
            column(EMUCaption; EMUCaptionLbl)
            {
            }
            column(CurrencyCaption; CurrencyCaptionLbl)
            {
            }
            column(NameCaption_GLAccount; FieldCaption(Name))
            {
            }
            column(NoCaption_GLAccount; FieldCaption("No."))
            {
            }
            column(TotalRateAdjustmentCaption; TotalRateAdjustmentCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Currency.Get("Currency Code");
                if Currency."EMU Currency" then
                    EMU := 'x'
                else
                    EMU := '';

                // Calc avg. exrate of existing entries
                CalcFields("Balance at Date (FCY)", "Balance at Date");
                if "Balance at Date (FCY)" <> 0 then
                    AvgExRate := Round("Balance at Date" / "Balance at Date (FCY)", 0.00001)
                else
                    AvgExRate := 0;

                // Calc value of FCY at current exrate
                CurrRate := ExchRate.ExchangeRateAdjmt(KeyDate, Currency.Code);
                if CurrRate <> 0 then
                    CurrRate := Round(1 / CurrRate, 0.00001);
                Correction := Round(("Balance at Date (FCY)" * CurrRate) - "Balance at Date", 0.01);

                // Prepare line in GL journal
                if PrepareGlLines and (Correction <> 0) then begin
                    GlLine.Init();
                    GlLine."Journal Template Name" := GenJourTemplate.Name;
                    GlLine."Journal Batch Name" := GenJourBatch.Name;
                    LastLineNo := LastLineNo + 10000;
                    GlLine."Line No." := LastLineNo;
                    GlLine.Insert(true);

                    GlLine."Account Type" := GlLine."Account Type"::"G/L Account";
                    GlLine."Document No." := Text010 + "G/L Account"."Currency Code";
                    GlLine."Account No." := "G/L Account"."No.";
                    GlLine.Validate("Posting Date", KeyDate);

                    SourceCodeSetup.Get();
                    GlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
                    GlLine.Description :=
                      StrSubstNo(Text007, "Currency Code", "No.", KeyDate);
                    if Correction > 0 then
                        GlLine.Validate("Bal. Account No.", Currency."Realized Gains Acc.")
                    else
                        GlLine.Validate("Bal. Account No.", Currency."Realized Losses Acc.");
                    GlLine."Amount (LCY)" := Correction;
                    GlLine.Validate(Amount, Correction);
                    GlLine.Modify();
                    LinesCreated := LinesCreated + 1;
                end;
            end;

            trigger OnPostDataItem()
            begin
                if PrepareGlLines then
                    Message(Text008, LinesCreated, GenJourBatch.Name);
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Currency Code") <> '' then
                    SetFilter("Currency Code", '<>%1&%2', '', GetFilter("Currency Code"))
                else
                    SetFilter("Currency Code", '<>%1', '');

                SetRange("Date Filter", 0D, KeyDate);
                Clear(Correction);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrepareGlLines; PrepareGlLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Prepare Gain/Loss Postings in G/L Journal';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to transfer the calculated correction as a suggestion in the general ledger register.';
                    }
                    field(JournalBatchName; GenJourBatch.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;
                        TableRelation = "Gen. Journal Batch".Name;
                        ToolTip = 'Specifies the name of the general journal that the entries are posted from.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJourBatch.FilterGroup(2);
                            GenJourBatch.SetRange("Journal Template Name", GenJourTemplate.Name);
                            GenJourBatch.FilterGroup(0);
                            if GenJourBatch.Find('=><') then;
                            if PAGE.RunModal(0, GenJourBatch) = ACTION::LookupOK then
                                GenJourBatch.Get(GenJourTemplate.Name, GenJourBatch.Name);
                        end;

                        trigger OnValidate()
                        begin
                            GenJourBatch.Get(GenJourTemplate.Name, GenJourBatch.Name);
                        end;
                    }
                    field(KeyDate; KeyDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Key Date';
                        ToolTip = 'Specifies the key date for the correction.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GenJourBatch.Name := '';
            GenJourTemplate.SetRange(Type, GenJourTemplate.Type::General);
            GenJourTemplate.SetRange(Recurring, false);
            GenJourTemplate.FindFirst;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        KeyDate := WorkDate;
    end;

    trigger OnPreReport()
    begin
        if KeyDate = 0D then
            Error(Text000);

        if PrepareGlLines then begin
            if GenJourBatch.Name = '' then
                Error(Text001);

            GenJourTemplate.FindFirst;
            GlLine.SetRange("Journal Template Name", GenJourTemplate.Name);
            GlLine.SetRange("Journal Batch Name", GenJourBatch.Name);
            GlLine.SetFilter("Account No.", '<>%1', '');
            if GlLine.FindFirst then
                Error(Text002, GenJourBatch.Name);
            GlLine.SetRange("Account No.");
            GlLine.DeleteAll();
        end;
    end;

    var
        Text000: Label 'The key date must be defined.';
        Text001: Label 'Please define G/L journal name.';
        Text002: Label 'There are already entries in the G/L journal %1. Please post or delete them before you proceed.';
        Text007: Label 'Gain/Loss %1 Acc. %2 of %3';
        Text008: Label '%1 exrate adjustment lines have been prepared in the G/L journal %2.';
        Currency: Record Currency;
        ExchRate: Record "Currency Exchange Rate";
        SourceCodeSetup: Record "Source Code Setup";
        GenJourBatch: Record "Gen. Journal Batch";
        GenJourTemplate: Record "Gen. Journal Template";
        GlLine: Record "Gen. Journal Line";
        Correction: Decimal;
        AvgExRate: Decimal;
        PrepareGlLines: Boolean;
        KeyDate: Date;
        EMU: Text[10];
        LastLineNo: Integer;
        LinesCreated: Integer;
        CurrRate: Decimal;
        Text010: Label 'Corr';
        AdjustExchangeRatesGLCaptionLbl: Label 'Adjust Exchange Rates G/L';
        PageCaptionLbl: Label 'Page';
        KeyDateCaptionLbl: Label 'Key Date';
        CorrectionCaptionLbl: Label 'Correction';
        ExrateOnKeyDateCaptionLbl: Label 'Exrate on Key Date';
        AvgExRateCaptionLbl: Label 'Average Exrate';
        BalanceAtDateCaptionLbl: Label 'Balance in LCY';
        BalanceAtDateFCYCaptionLbl: Label 'Balance in FCY';
        EMUCaptionLbl: Label 'EMU';
        CurrencyCaptionLbl: Label 'Currency';
        TotalRateAdjustmentCaptionLbl: Label 'Total Rate Adjustment';
}

