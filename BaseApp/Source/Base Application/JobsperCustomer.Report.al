report 1012 "Jobs per Customer"
{
    DefaultLayout = RDLC;
    RDLCLayout = './JobsperCustomer.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Jobs per Customer';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = SORTING("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Customer Posting Group";
            column(TodayFormatted; Format(Today))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(CustCustFilter; TableCaption + ': ' + CustFilter)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(JobFilterCaptn_Cust; Job.TableCaption + ': ' + JobFilter)
            {
            }
            column(JobFilter_Cust; JobFilter)
            {
            }
            column(No_Cust; "No.")
            {
            }
            column(Name_Cust; Name)
            {
            }
            column(Amt6; Amt[6])
            {
            }
            column(Amt4; Amt[4])
            {
            }
            column(Amt3; Amt[3])
            {
            }
            column(Amt5; Amt[5])
            {
            }
            column(Amt2; Amt[2])
            {
            }
            column(Amt1; Amt[1])
            {
            }
            column(JobsperCustCaption; JobsperCustCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(AllAmtAreInLCYCaption; AllAmtAreInLCYCaptionLbl)
            {
            }
            column(JobNoCaption; JobNoCaptionLbl)
            {
            }
            column(EndingDateCaption; EndingDateCaptionLbl)
            {
            }
            column(ScheduleLineAmtCaption; ScheduleLineAmtCaptionLbl)
            {
            }
            column(UsageLineAmtCaption; UsageLineAmtCaptionLbl)
            {
            }
            column(CompletionCaption; CompletionCaptionLbl)
            {
            }
            column(ContractInvLineAmtCaption; ContractInvLineAmtCaptionLbl)
            {
            }
            column(ContractLineAmtCaption; ContractLineAmtCaptionLbl)
            {
            }
            column(InvoicingCaption; InvoicingCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem(Job; Job)
            {
                DataItemLink = "Bill-to Customer No." = FIELD("No.");
                DataItemTableView = SORTING("Bill-to Customer No.");
                RequestFilterFields = "No.", "Posting Date Filter", "Planning Date Filter", Blocked;
                column(Endingdate_Job; Format("Ending Date"))
                {
                }
                column(No_Job; "No.")
                {
                }
                column(Desc_Job; Description)
                {
                    IncludeCaption = true;
                }
                column(TableCaptnCustNo; Text000 + ' ' + Customer.TableCaption + ' ' + Customer."No.")
                {
                }
                column(BilltoCustomerNo_Job; "Bill-to Customer No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    JobCalcStatistics.RepJobCustomer(Job, Amt);
                end;

                trigger OnPreDataItem()
                begin
                    Clear(Amt[1]);
                    Clear(Amt[2]);
                    Clear(Amt[3]);
                    Clear(Amt[4]);
                end;
            }

            trigger OnPreDataItem()
            begin
                Clear(Amt);
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
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
        JobFilter := Job.GetFilters;
    end;

    var
        JobCalcStatistics: Codeunit "Job Calculate Statistics";
        CustFilter: Text;
        JobFilter: Text;
        Amt: array[8] of Decimal;
        Text000: Label 'Total for';
        JobsperCustCaptionLbl: Label 'Jobs per Customer';
        PageCaptionLbl: Label 'Page';
        AllAmtAreInLCYCaptionLbl: Label 'All amounts are in LCY';
        JobNoCaptionLbl: Label 'Job No.';
        EndingDateCaptionLbl: Label 'Ending Date';
        ScheduleLineAmtCaptionLbl: Label 'Budget Line Amount';
        UsageLineAmtCaptionLbl: Label 'Usage Line Amount';
        CompletionCaptionLbl: Label 'Completion %';
        ContractInvLineAmtCaptionLbl: Label 'Billable Invoice Line Amount';
        ContractLineAmtCaptionLbl: Label 'Billable Line Amount';
        InvoicingCaptionLbl: Label 'Invoicing %';
        TotalCaptionLbl: Label 'Total';
}

