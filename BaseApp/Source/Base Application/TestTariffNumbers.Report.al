#if not CLEAN18
report 31063 "Test Tariff Numbers"
{
    DefaultLayout = RDLC;
    RDLCLayout = './TestTariffNumbers.rdlc';
    Caption = 'Test Tariff Numbers (Obsolete)';
    UsageCategory = Tasks;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = WHERE("Tariff No." = FILTER(<> ''));
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                if GuiAllowed then begin
                    RecNo += 1;
                    Window.Update(1, "No.");
                    Window.Update(2, Round(RecNo / RecCount * 10000, 1));
                end;

                if TempTariffNoBuffer.Get("Tariff No.") then begin
                    TempTariffNoBuffer."Total Amount" += 1;
                    TempTariffNoBuffer.Modify();
                end else
                    if not TariffNo.Get("Tariff No.") then begin
                        TempTariffNoBuffer.Init();
                        TempTariffNoBuffer."Currency Code" := "Tariff No.";
                        TempTariffNoBuffer."Total Amount" := 1;
                        TempTariffNoBuffer.Insert();
                    end;
            end;

            trigger OnPostDataItem()
            begin
                if GuiAllowed then
                    Window.Close;
            end;

            trigger OnPreDataItem()
            begin
                if GuiAllowed then begin
                    RecCount := Count;
                    Window.Open(Text000);
                end;
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number);
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(gteFilters; Filters)
            {
            }
            column(Test_Tariff_NumbersCaption; Test_Tariff_NumbersCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(greTempTariffNoBuffer__Currency_Code_; TempTariffNoBuffer."Currency Code")
            {
            }
            column(greTempTariffNoBuffer__Total_Amount_; TempTariffNoBuffer."Total Amount")
            {
                DecimalPlaces = 0 : 0;
            }
            column(gtcText010; Text010)
            {
            }
            column(greTempTariffNoBuffer__Currency_Code_Caption; TempTariffNoBuffer__Currency_Code_CaptionLbl)
            {
            }
            column(gtcText010Caption; Text010CaptionLbl)
            {
            }
            column(greTempTariffNoBuffer__Total_Amount_Caption; TempTariffNoBuffer__Total_Amount_CaptionLbl)
            {
            }
            column(Integer_Number; Number)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempTariffNoBuffer.Find('-')
                else
                    TempTariffNoBuffer.Next;
            end;

            trigger OnPreDataItem()
            begin
                TempTariffNoBuffer.Reset();
                SetRange(Number, 1, TempTariffNoBuffer.Count);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        Filters := Item.GetFilters;
        if Filters <> '' then
            Filters := StrSubstNo('%1: %2', Item.TableCaption, Filters);
    end;

    var
        TariffNo: Record "Tariff Number";
        TempTariffNoBuffer: Record "Currency Total Buffer" temporary;
        Window: Dialog;
        Filters: Text;
        RecNo: Integer;
        RecCount: Integer;
        Text000: Label 'Checking item #1############\@2@@@@@@@@@@@@@@@@@@@@@@@@@@';
        Text010: Label 'Not exist in tariff numbers';
        Test_Tariff_NumbersCaptionLbl: Label 'Test Tariff Numbers';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        TempTariffNoBuffer__Currency_Code_CaptionLbl: Label 'Tariff Number';
        Text010CaptionLbl: Label 'Description';
        TempTariffNoBuffer__Total_Amount_CaptionLbl: Label 'No. of Items';
}


#endif