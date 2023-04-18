report 1014 "Jobs per Item"
{
    DefaultLayout = RDLC;
    RDLCLayout = './ProjectMgt/Jobs/JobsperItem.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Jobs per Item';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(TodayFormatted; Format(Today))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTableCaptiontemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(JobTableCaptionJobFilter; Job.TableCaption + ': ' + JobFilter)
            {
            }
            column(JobFilter; JobFilter)
            {
            }
            column(Description_Item; Description)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(Amount3_JobBuffer; TempJobBuffer."Amount 3")
            {
            }
            column(Amount2_JobBuffer; TempJobBuffer."Amount 2")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(JobsperItemCaption; JobsperItemCaptionLbl)
            {
            }
            column(AllamountsareinLCYCaption; AllamountsareinLCYCaptionLbl)
            {
            }
            column(JobNoCaption; JobNoCaptionLbl)
            {
            }
            column(JobBufferDscrptnCaption; JobBufferDscrptnCaptionLbl)
            {
            }
            column(JobBufferQuantityCaption; JobBufferQuantityCaptionLbl)
            {
            }
            column(JobBufferUOMCaption; JobBufferUOMCaptionLbl)
            {
            }
            column(JobBufferTotalCostCaption; JobBufferTotalCostCaptionLbl)
            {
            }
            column(JobBufferLineAmountCaption; JobBufferLineAmountCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(AccountNo1_JobBuffer; TempJobBuffer."Account No. 1")
                {
                }
                column(Description_JobBuffer; TempJobBuffer.Description)
                {
                }
                column(AccountNo2_JobBuffer; TempJobBuffer."Account No. 2")
                {
                }
                column(Amount1_JobBuffer; TempJobBuffer."Amount 1")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TableCapionItemNo; Text000 + ' ' + Item.TableCaption + ' ' + Item."No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then begin
                        if not TempJobBuffer.Find('-') then
                            CurrReport.Break();
                    end else
                        if TempJobBuffer.Next() = 0 then
                            CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TempJobBuffer2.ReportItemJob(Item, Job, TempJobBuffer);
            end;
        }
        dataitem(Job2; Job)
        {
            RequestFilterFields = "No.", "Bill-to Customer No.", "Posting Date Filter";

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
        ItemFilter := Item.GetFilters();

        Job.CopyFilters(Job2);
        JobFilter := Job.GetFilters();
    end;

    var
        Job: Record Job;
        TempJobBuffer2: Record "Job Buffer" temporary;
        TempJobBuffer: Record "Job Buffer" temporary;
        JobFilter: Text;
        ItemFilter: Text;
        Text000: Label 'Total for';
        CurrReportPageNoCaptionLbl: Label 'Page';
        JobsperItemCaptionLbl: Label 'Jobs per Item';
        AllamountsareinLCYCaptionLbl: Label 'All amounts are in LCY';
        JobNoCaptionLbl: Label 'Job No.';
        JobBufferDscrptnCaptionLbl: Label 'Description';
        JobBufferQuantityCaptionLbl: Label 'Quantity';
        JobBufferUOMCaptionLbl: Label 'Unit of Measure';
        JobBufferTotalCostCaptionLbl: Label 'Total Cost';
        JobBufferLineAmountCaptionLbl: Label 'Line Amount';
        TotalCaptionLbl: Label 'Total';
}

