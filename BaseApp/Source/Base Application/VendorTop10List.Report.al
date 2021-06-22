report 311 "Vendor - Top 10 List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VendorTop10List.rdlc';
    ApplicationArea = Suite;
    Caption = 'Vendor - Top 10 List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.", "Vendor Posting Group", "Currency Code", "Date Filter";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                CalcFields("Purchases (LCY)", "Balance (LCY)");
                if ("Purchases (LCY)" = 0) and ("Balance (LCY)" = 0) then
                    CurrReport.Skip();
                VendAmount.Init();
                VendAmount."Vendor No." := "No.";
                if ShowType = ShowType::"Purchases (LCY)" then begin
                    VendAmount."Amount (LCY)" := -"Purchases (LCY)";
                    VendAmount."Amount 2 (LCY)" := -"Balance (LCY)";
                end else begin
                    VendAmount."Amount (LCY)" := -"Balance (LCY)";
                    VendAmount."Amount 2 (LCY)" := -"Purchases (LCY)";
                end;
                VendAmount.Insert();
                if (NoOfRecordsToPrint = 0) or (i < NoOfRecordsToPrint) then
                    i := i + 1
                else begin
                    VendAmount.Find('+');
                    VendAmount.Delete();
                end;

                TotalVenPurchases += "Purchases (LCY)";
                TotalVenBalance += "Balance (LCY)";
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(Text000);
                VendAmount.DeleteAll();
                i := 0;
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(STRSUBSTNO_Text001_VendDateFilter_; StrSubstNo(Text001, VendDateFilter))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(STRSUBSTNO_Text002_SELECTSTR_ShowType_1_Text004__; StrSubstNo(Text002, SelectStr(ShowType + 1, Text004)))
            {
            }
            column(STRSUBSTNO___1___2__Vendor_TABLECAPTION_VendFilter_; StrSubstNo('%1: %2', Vendor.TableCaption, VendFilter))
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(STRSUBSTNO_Text003_SELECTSTR_ShowType_1_Text004__; StrSubstNo(Text003, SelectStr(ShowType + 1, Text004)))
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(Vendor__No__; Vendor."No.")
            {
            }
            column(Vendor_Name; Vendor.Name)
            {
            }
            column(Vendor__Purchases__LCY__; Vendor."Purchases (LCY)")
            {
            }
            column(Vendor__Balance__LCY__; Vendor."Balance (LCY)")
            {
            }
            column(BarText; BarText)
            {
            }
            column(Vendor__Purchases__LCY___Control23; Vendor."Purchases (LCY)")
            {
            }
            column(VendPurchLCY; VendPurchLCY)
            {
                AutoFormatType = 1;
            }
            column(PurchPct; PurchPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(TotalVenBalance; TotalVenBalance)
            {
            }
            column(TotalVenPurchases; TotalVenPurchases)
            {
            }
            column(Vendor___Top_10_ListCaption; Vendor___Top_10_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Integer_NumberCaption; Integer_NumberCaptionLbl)
            {
            }
            column(Vendor__No__Caption; Vendor.FieldCaption("No."))
            {
            }
            column(Vendor_NameCaption; Vendor.FieldCaption(Name))
            {
            }
            column(Vendor__Purchases__LCY__Caption; Vendor.FieldCaption("Purchases (LCY)"))
            {
            }
            column(Vendor__Balance__LCY__Caption; Vendor.FieldCaption("Balance (LCY)"))
            {
            }
            column(Vendor__Purchases__LCY___Control23Caption; Vendor__Purchases__LCY___Control23CaptionLbl)
            {
            }
            column(VendPurchLCYCaption; VendPurchLCYCaptionLbl)
            {
            }
            column(PurchPctCaption; PurchPctCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not VendAmount.Find('-') then
                        CurrReport.Break();
                end else
                    if VendAmount.Next = 0 then
                        CurrReport.Break();
                VendAmount."Amount (LCY)" := -VendAmount."Amount (LCY)";
                Vendor.Get(VendAmount."Vendor No.");
                Vendor.CalcFields("Purchases (LCY)", "Balance (LCY)");
                if MaxAmount = 0 then
                    MaxAmount := VendAmount."Amount (LCY)";
                if (MaxAmount > 0) and (VendAmount."Amount (LCY)" > 0) then
                    BarText := PadStr('', Round(VendAmount."Amount (LCY)" / MaxAmount * 45, 1), '*')
                else
                    BarText := '';
                VendAmount."Amount (LCY)" := -VendAmount."Amount (LCY)";
            end;

            trigger OnPreDataItem()
            begin
                VendPurchLCY := Vendor."Purchases (LCY)";
                Window.Close;
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
                    field(Show; ShowType)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Show';
                        OptionCaption = 'Purchases (LCY),Balance (LCY)';
                        ToolTip = 'Specifies how the report will sort the vendors: Purchases, to sort by purchase volume; or Balance, to sort by balance. In either case, the vendors with the largest amounts will be shown first.';
                    }
                    field(Quantity; NoOfRecordsToPrint)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Quantity';
                        ToolTip = 'Specifies the number of vendors that will be included in the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if NoOfRecordsToPrint = 0 then
                NoOfRecordsToPrint := 10;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        VendFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
        VendDateFilter := Vendor.GetFilter("Date Filter");
    end;

    var
        Text000: Label 'Sorting vendors       #1##########';
        Text001: Label 'Period: %1';
        Text002: Label 'Rank according to %1';
        Text003: Label 'Portion of %1';
        VendAmount: Record "Vendor Amount" temporary;
        Window: Dialog;
        VendFilter: Text;
        VendDateFilter: Text;
        ShowType: Option "Purchases (LCY)","Balance (LCY)";
        NoOfRecordsToPrint: Integer;
        VendPurchLCY: Decimal;
        PurchPct: Decimal;
        MaxAmount: Decimal;
        BarText: Text[50];
        i: Integer;
        Text004: Label 'Purchases (LCY),Balance (LCY)';
        TotalVenPurchases: Decimal;
        TotalVenBalance: Decimal;
        Vendor___Top_10_ListCaptionLbl: Label 'Vendor - Top 10 List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Integer_NumberCaptionLbl: Label 'Rank';
        Vendor__Purchases__LCY___Control23CaptionLbl: Label 'Total';
        VendPurchLCYCaptionLbl: Label 'Total Purchases';
        PurchPctCaptionLbl: Label '% of Total Purchases';

    procedure InitializeRequest(NewShowType: Option; NewNoOfRecordsToPrint: Integer)
    begin
        ShowType := NewShowType;
        NoOfRecordsToPrint := NewNoOfRecordsToPrint;
    end;
}

