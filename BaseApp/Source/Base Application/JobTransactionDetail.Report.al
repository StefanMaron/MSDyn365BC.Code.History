report 1007 "Job - Transaction Detail"
{
    DefaultLayout = RDLC;
    RDLCLayout = './JobTransactionDetail.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Job Task - Transaction Detail';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            column(No_Job; "No.")
            {
            }
            column(JobTotalCost1; JobTotalCost[1])
            {
            }
            column(JobTotalCost2; JobTotalCost[2])
            {
            }
            column(JobTotalPrice1; JobTotalPrice[1])
            {
            }
            column(JobTotalPrice2; JobTotalPrice[2])
            {
            }
            column(JobTotalLineDiscAmount1; JobTotalLineDiscAmount[1])
            {
            }
            column(JobTotalLineDiscAmount2; JobTotalLineDiscAmount[2])
            {
            }
            column(JobTotalLineAmount1; JobTotalLineAmount[1])
            {
            }
            column(JobTotalLineAmount2; JobTotalLineAmount[2])
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(CompanyName; COMPANYPROPERTY.DisplayName)
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(JobFilterCaption; Job.TableCaption + ': ' + JobFilter)
                {
                }
                column(JobFilter; JobFilter)
                {
                }
                column(JobLedgEntryFilterCaption; "Job Ledger Entry".TableCaption + ': ' + JobLedgEntryFilter)
                {
                }
                column(JobLedgEntryFilter; JobLedgEntryFilter)
                {
                }
                column(Description_Job; Job.Description)
                {
                }
                column(CurrencyField0; JobCalcBatches.GetCurrencyCode(Job, 0, CurrencyField))
                {
                }
                column(CurrencyField1; JobCalcBatches.GetCurrencyCode(Job, 1, CurrencyField))
                {
                }
                column(CurrencyField2; JobCalcBatches.GetCurrencyCode(Job, 2, CurrencyField))
                {
                }
                column(CurrencyField3; JobCalcBatches.GetCurrencyCode(Job, 3, CurrencyField))
                {
                }
                column(JobTransactionDetailCaption; JobTransactionDetailCaptionLbl)
                {
                }
                column(PageNoCaption; PageNoCaptionLbl)
                {
                }
                column(JobNoCaption; JobNoCaptionLbl)
                {
                }
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                column(JobLedgEntryEntryTypeCaption; "Job Ledger Entry".FieldCaption("Entry Type"))
                {
                }
                column(JobLedgEntryDocNoCaption; "Job Ledger Entry".FieldCaption("Document No."))
                {
                }
                column(JobLedgEntryTypeCaption; "Job Ledger Entry".FieldCaption(Type))
                {
                }
                column(JobLedgEntryNoCaption; "Job Ledger Entry".FieldCaption("No."))
                {
                }
                column(JobLedgEntryQtyCaption; "Job Ledger Entry".FieldCaption(Quantity))
                {
                }
                column(JobLedgEntryUOMCodeCaption; "Job Ledger Entry".FieldCaption("Unit of Measure Code"))
                {
                }
                column(JobLedgEntryEntryNoCaption; "Job Ledger Entry".FieldCaption("Entry No."))
                {
                }
            }
            dataitem("Job Task"; "Job Task")
            {
                DataItemLink = "Job No." = FIELD("No.");
                DataItemTableView = SORTING("Job No.", "Job Task No.");
                PrintOnlyIfDetail = true;
                column(JobTaskNo_JobTask; "Job Task No.")
                {
                }
                column(Description_JobTask; Description)
                {
                }
                column(CurrencyField; CurrencyField)
                {
                }
                column(TotalCostTotal1; TotalCostTotal[1])
                {
                    AutoFormatType = 1;
                }
                column(TotalCostTotal2; TotalCostTotal[2])
                {
                    AutoFormatType = 1;
                }
                column(TotalPriceTotal1; TotalPriceTotal[1])
                {
                    AutoFormatType = 1;
                }
                column(TotalPriceTotal2; TotalPriceTotal[2])
                {
                    AutoFormatType = 1;
                }
                column(TotalLineDiscAmt1; TotalLineDiscAmount[1])
                {
                    AutoFormatType = 1;
                }
                column(TotalLineDiscAmt2; TotalLineDiscAmount[2])
                {
                    AutoFormatType = 1;
                }
                column(TotalLineAmt1; TotalLineAmount[1])
                {
                    AutoFormatType = 1;
                }
                column(JobNo_JobTask; "Job No.")
                {
                }
                column(JobTaskJobTaskNoCaption; FieldCaption("Job Task No."))
                {
                }
                column(TotalUsageCaption; TotalUsageCaptionLbl)
                {
                }
                column(TotalSaleCaption; TotalSaleCaptionLbl)
                {
                }
                dataitem("Job Ledger Entry"; "Job Ledger Entry")
                {
                    DataItemLink = "Job No." = FIELD("Job No."), "Job Task No." = FIELD("Job Task No.");
                    DataItemTableView = SORTING("Job No.", "Job Task No.", "Entry Type", "Posting Date");
                    RequestFilterFields = "Posting Date";
                    column(EntryNo_JobLedgEntry; "Entry No.")
                    {
                    }
                    column(LineAmtLCY_JobLedgEntry; "Line Amount (LCY)")
                    {
                    }
                    column(LineDiscAmtLCY_JobLedgEntry; "Line Discount Amount (LCY)")
                    {
                    }
                    column(TotalPriceLCY_JobLedgEntry; "Total Price (LCY)")
                    {
                    }
                    column(TotalCostLCY_JobLedgEntry; "Total Cost (LCY)")
                    {
                    }
                    column(UOMCode_JobLedgEntry; "Unit of Measure Code")
                    {
                    }
                    column(Quantity_JobLedgEntry; Quantity)
                    {
                    }
                    column(No_JobLedgEntry; "No.")
                    {
                    }
                    column(Type_JobLedgEntry; Type)
                    {
                    }
                    column(DocNo_JobLedgEntry; "Document No.")
                    {
                    }
                    column(EntryType_JobLedgEntry; "Entry Type")
                    {
                    }
                    column(PostDate_JobLedgEntry; Format("Posting Date"))
                    {
                    }
                    column(LineAmt_JobLedgEntry; "Line Amount")
                    {
                    }
                    column(LineDiscAmt_JobLedgEntry; "Line Discount Amount")
                    {
                    }
                    column(TotalPrice_JobLedgEntry; "Total Price")
                    {
                    }
                    column(TotalCost_JobLedgEntry; "Total Cost")
                    {
                    }
                    column(TotalCostTotal11; TotalCostTotal[1])
                    {
                        AutoFormatType = 1;
                    }
                    column(TotalCostTotal21; TotalCostTotal[2])
                    {
                        AutoFormatType = 1;
                    }
                    column(TotalPriceTotal11; TotalPriceTotal[1])
                    {
                        AutoFormatType = 1;
                    }
                    column(TotalPriceTotal21; TotalPriceTotal[2])
                    {
                        AutoFormatType = 1;
                    }
                    column(TotalLineDiscAmt11; TotalLineDiscAmount[1])
                    {
                        AutoFormatType = 1;
                    }
                    column(TotalLineDiscAmt21; TotalLineDiscAmount[2])
                    {
                        AutoFormatType = 1;
                    }
                    column(TotalLineAmt11; TotalLineAmount[1])
                    {
                        AutoFormatType = 1;
                    }
                    column(JobNo_JobLedgEntry; "Job No.")
                    {
                    }
                    column(JobTaskNo_JobLedgEntry; "Job Task No.")
                    {
                    }
                    column(UsageCaption; UsageCaptionLbl)
                    {
                    }
                    column(SalesCaption; SalesCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if "Entry Type" = "Entry Type"::Usage then
                            I := 1
                        else
                            I := 2;
                        if CurrencyField = CurrencyField::"Local Currency" then begin
                            TotalCostTotal[I] += "Total Cost (LCY)";
                            TotalPriceTotal[I] += "Total Price (LCY)";
                            TotalLineDiscAmount[I] += "Line Discount Amount (LCY)";
                            TotalLineAmount[I] += "Line Amount (LCY)";
                            JobTotalCost[I] += "Total Cost (LCY)";
                            JobTotalLineAmount[I] += "Line Amount (LCY)";
                            JobTotalLineDiscAmount[I] += "Line Discount Amount (LCY)";
                            JobTotalPrice[I] += "Total Price (LCY)";
                        end else begin
                            TotalCostTotal[I] += "Total Cost";
                            TotalPriceTotal[I] += "Total Price";
                            TotalLineDiscAmount[I] += "Line Discount Amount";
                            TotalLineAmount[I] += "Line Amount";
                            JobTotalCost[I] += "Total Cost";
                            JobTotalLineAmount[I] += "Line Amount";
                            JobTotalLineDiscAmount[I] += "Line Discount Amount";
                            JobTotalPrice[I] += "Total Price";
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(TotalCostTotal);
                        Clear(TotalPriceTotal);
                        Clear(TotalLineDiscAmount);
                        Clear(TotalLineAmount);
                    end;
                }

                trigger OnPreDataItem()
                begin
                    Clear(TotalCostTotal);
                    Clear(TotalPriceTotal);
                    Clear(TotalLineDiscAmount);
                    Clear(TotalLineAmount);
                end;
            }

            trigger OnAfterGetRecord()
            var
                JobLedgEntry: Record "Job Ledger Entry";
            begin
                Clear(JobTotalCost);
                Clear(JobTotalPrice);
                Clear(JobTotalLineAmount);
                Clear(JobTotalLineDiscAmount);

                JobLedgEntry.SetCurrentKey("Job No.", "Entry Type");
                JobLedgEntry.SetRange("Job No.", "No.");
                JobLedgEntry.SetRange("Entry Type", JobLedgEntry."Entry Type"::Usage);
                if not JobLedgEntry.FindFirst then
                    CurrReport.Skip;
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
                    field(CurrencyField; CurrencyField)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Currency';
                        OptionCaption = 'Local Currency,Foreign Currency';
                        ToolTip = 'Specifies the currency that amounts are shown in.';
                    }
                }
            }
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
        JobFilter := Job.GetFilters;
        JobLedgEntryFilter := "Job Ledger Entry".GetFilters;
    end;

    var
        JobCalcBatches: Codeunit "Job Calculate Batches";
        TotalCostTotal: array[2] of Decimal;
        TotalPriceTotal: array[2] of Decimal;
        TotalLineDiscAmount: array[2] of Decimal;
        TotalLineAmount: array[2] of Decimal;
        JobTotalCost: array[2] of Decimal;
        JobTotalPrice: array[2] of Decimal;
        JobTotalLineDiscAmount: array[2] of Decimal;
        JobTotalLineAmount: array[2] of Decimal;
        JobFilter: Text;
        JobLedgEntryFilter: Text;
        CurrencyField: Option "Local Currency","Foreign Currency";
        I: Integer;
        JobTransactionDetailCaptionLbl: Label 'Job - Transaction Detail';
        PageNoCaptionLbl: Label 'Page';
        JobNoCaptionLbl: Label 'Job No.';
        PostingDateCaptionLbl: Label 'Posting Date';
        TotalUsageCaptionLbl: Label 'Total Usage';
        TotalSaleCaptionLbl: Label 'Total Sale';
        UsageCaptionLbl: Label 'Usage';
        SalesCaptionLbl: Label 'Sales';

    procedure InitializeRequest(NewCurrencyField: Option "Local Currency","Foreign Currency")
    begin
        CurrencyField := NewCurrencyField;
    end;
}

