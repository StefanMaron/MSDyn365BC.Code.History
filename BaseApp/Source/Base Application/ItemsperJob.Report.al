report 1013 "Items per Job"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ItemsperJob.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Items per Job';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = SORTING("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Posting Date Filter";
            column(TodayFormatted; Format(Today))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(JobTableCaptionJobFilter; TableCaption + ': ' + JobFilter)
            {
            }
            column(JobFilter; JobFilter)
            {
            }
            column(ItemTableCaptItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(No_Job; "No.")
            {
            }
            column(Description_Job; Description)
            {
            }
            column(Amount3_JobBuffer; JobBuffer."Amount 3")
            {
            }
            column(Amount1_JobBuffer; JobBuffer."Amount 2")
            {
            }
            column(ItemsperJobCaption; ItemsperJobCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(AllamountsareinLCYCaption; AllamountsareinLCYCaptionLbl)
            {
            }
            column(JobBufferLineAmountCaption; JobBufferLineAmountCaptionLbl)
            {
            }
            column(JobBufferTotalCostCaption; JobBufferTotalCostCaptionLbl)
            {
            }
            column(JobBuffeUOMCaption; JobBuffeUOMCaptionLbl)
            {
            }
            column(JobBufferQuantityCaption; JobBufferQuantityCaptionLbl)
            {
            }
            column(JobBufferDescriptionCaption; JobBufferDescriptionCaptionLbl)
            {
            }
            column(ItemNoCaption; ItemNoCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(ActNo1_JobBuffer; JobBuffer."Account No. 1")
                {
                }
                column(Description_JobBuffer; JobBuffer.Description)
                {
                }
                column(ActNo2_JobBuffer; JobBuffer."Account No. 2")
                {
                }
                column(Amount2_JobBuffer; JobBuffer."Amount 1")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TableCaptionJobNo; Text000 + ' ' + Job.TableCaption + ' ' + Job."No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then begin
                        if not JobBuffer.Find('-') then
                            CurrReport.Break();
                    end else
                        if JobBuffer.Next = 0 then
                            CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                JobBuffer2.ReportJobItem(Job, Item, JobBuffer);
            end;
        }
        dataitem(Item2; Item)
        {
            RequestFilterFields = "No.";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
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
        Item.CopyFilters(Item2);
        JobFilter := Job.GetFilters;
        ItemFilter := Item.GetFilters;
    end;

    var
        Item: Record Item;
        JobBuffer2: Record "Job Buffer" temporary;
        JobBuffer: Record "Job Buffer" temporary;
        JobFilter: Text;
        ItemFilter: Text;
        Text000: Label 'Total for';
        ItemsperJobCaptionLbl: Label 'Items per Job';
        CurrReportPageNoCaptionLbl: Label 'Page';
        AllamountsareinLCYCaptionLbl: Label 'All amounts are in LCY';
        JobBufferLineAmountCaptionLbl: Label 'Line Amount';
        JobBufferTotalCostCaptionLbl: Label 'Total Cost';
        JobBuffeUOMCaptionLbl: Label 'Unit of Measure';
        JobBufferQuantityCaptionLbl: Label 'Quantity';
        JobBufferDescriptionCaptionLbl: Label 'Description';
        ItemNoCaptionLbl: Label 'Item No.';
        TotalCaptionLbl: Label 'Total';
}

