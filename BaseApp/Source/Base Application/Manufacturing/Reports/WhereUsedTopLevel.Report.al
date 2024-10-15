namespace Microsoft.Manufacturing.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using System.Utilities;

report 99000757 "Where-Used (Top Level)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/WhereUsedTopLevel.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Where-Used (Top Level)';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description";
            column(FormattedToday; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CalcDateFormatted; Text000 + Format(CalculateDate))
            {
            }
            column(ItemTableCaptionItemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(WhereUsedListTopLevelCapt; WhereUsedListTopLevelCaptLbl)
            {
            }
            column(CurrReportPageNoCapt; CurrReportPageNoCaptLbl)
            {
            }
            column(LevelCodeCaption; LevelCodeCaptionLbl)
            {
            }
            column(WhereUsedListItemNoCapt; WhereUsedListItemNoCaptLbl)
            {
            }
            column(WhereUsedListDescCapt; WhereUsedListDescCaptLbl)
            {
            }
            column(WhereUsedListQtyNeededCapt; WhereUsedListQtyNeededCaptLbl)
            {
            }
            dataitem(BOMLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(WhereUsedListItemNo; WhereUsedList."Item No.")
                {
                }
                column(WhereUsedListDesc; WhereUsedList.Description)
                {
                }
                column(WhereUsedListQtyNeeded; WhereUsedList."Quantity Needed")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(WhereUsedListLevelCode; PadStr('', WhereUsedList."Level Code", ' ') + Format(WhereUsedList."Level Code"))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if First then begin
                        if not WhereUsedMgt.FindRecord('-', WhereUsedList) then
                            CurrReport.Break();
                        First := false;
                    end else
                        if WhereUsedMgt.NextRecord(1, WhereUsedList) = 0 then
                            CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    First := true;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                WhereUsedMgt.WhereUsedFromItem(Item, CalculateDate, true);
            end;

            trigger OnPreDataItem()
            begin
                OnBeforeOnPreDataItemItem(Item);

                ItemFilter := GetFilters();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CalculateDate; CalculateDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Calculation Date';
                        ToolTip = 'Specifies the date that you want the calculation done by. Note that the date filter takes version dates into account. The program automatically enters the working date.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CalculateDate := WorkDate();
        end;
    }

    labels
    {
    }

    var
        WhereUsedList: Record "Where-Used Line";
        WhereUsedMgt: Codeunit "Where-Used Management";
        ItemFilter: Text;
        CalculateDate: Date;
        First: Boolean;

#pragma warning disable AA0074
        Text000: Label 'As of ';
#pragma warning restore AA0074
        WhereUsedListTopLevelCaptLbl: Label 'Where-Used List (Top Level)';
        CurrReportPageNoCaptLbl: Label 'Page';
        LevelCodeCaptionLbl: Label 'Level';
        WhereUsedListItemNoCaptLbl: Label 'No.';
        WhereUsedListDescCaptLbl: Label 'Description';
        WhereUsedListQtyNeededCaptLbl: Label 'Exploded Quantity.';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreDataItemItem(var Item: Record Item)
    begin
    end;
}

