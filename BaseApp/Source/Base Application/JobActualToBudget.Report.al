report 1009 "Job Actual To Budget"
{
    DefaultLayout = RDLC;
    RDLCLayout = './JobActualToBudget.rdlc';
    ApplicationArea = Jobs;
    Caption = 'Job Actual To Budget';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Job; Job)
        {
            RequestFilterFields = "No.", "Posting Date Filter", "Planning Date Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(JobTableCaptionFilter; TableCaption + ': ' + JobFilter)
            {
            }
            column(JobFilter; JobFilter)
            {
            }
            column(JobTaskTableCaptionFilter; "Job Task".TableCaption + ': ' + JobTaskFilter)
            {
            }
            column(JobTaskFilter; JobTaskFilter)
            {
            }
            column(EmptyString; '')
            {
            }
            column(JobCalcBatchesCurrencyField; JobCalcBatches.GetCurrencyCode(Job, 0, CurrencyField))
            {
            }
            column(JobCalcBatches3CurrencyField; JobCalcBatches.GetCurrencyCode(Job, 3, CurrencyField))
            {
            }
            column(No_Job; "No.")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(JobActualToBudgetCaption; JobActualToBudgetCaptionLbl)
            {
            }
            column(QuantityCaption; QuantityCaptionLbl)
            {
            }
            column(ScheduleCaption; ScheduleCaptionLbl)
            {
            }
            column(UsageCaption; UsageCaptionLbl)
            {
            }
            column(DifferenceCaption; DifferenceCaptionLbl)
            {
            }
            dataitem("Job Task"; "Job Task")
            {
                DataItemLink = "Job No." = FIELD("No.");
                DataItemTableView = SORTING("Job No.", "Job Task No.");
                RequestFilterFields = "Job Task No.";
                column(Desc_Job; Job.Description)
                {
                }
                column(JobTaskNo_JobTask; "Job Task No.")
                {
                }
                column(Description_JobTask; Description)
                {
                }
                column(JobTaskNoCaption; JobTaskNoCaptionLbl)
                {
                }
                dataitem(FirstBuffer; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    column(Amt1; Amt[1])
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amt2; Amt[2])
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amt3; Amt[3])
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amt4; Amt[4])
                    {
                    }
                    column(Amt5; Amt[5])
                    {
                    }
                    column(Amt6; Amt[6])
                    {
                    }
                    column(Amt7; Amt[7])
                    {
                    }
                    column(Amt8; Amt[8])
                    {
                    }
                    column(Amt9; Amt[9])
                    {
                    }
                    column(JobDiffBufferType1; JobDiffBuffer.Type)
                    {
                    }
                    column(JobDiffBufferNo; JobDiffBuffer."No.")
                    {
                    }
                    column(JobDiffBufferUOMcode; JobDiffBuffer."Unit of Measure code")
                    {
                    }
                    column(JobDiffBufferWorkTypeCode; JobDiffBuffer."Work Type Code")
                    {
                    }
                    column(ShowFirstBuffer; ShowFirstBuffer)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Clear(ShowFirstBuffer);

                        Clear(Amt);
                        if Number = 1 then begin
                            if not JobDiffBuffer.Find('-') then
                                CurrReport.Break();
                        end else
                            if JobDiffBuffer.Next() = 0 then
                                CurrReport.Break();
                        Amt[1] := JobDiffBuffer.Quantity;
                        Amt[4] := JobDiffBuffer."Total Cost";
                        Amt[7] := JobDiffBuffer."Line Amount";

                        JobDiffBuffer2 := JobDiffBuffer;
                        if JobDiffBuffer2.Find then begin
                            Amt[2] := JobDiffBuffer2.Quantity;
                            Amt[5] := JobDiffBuffer2."Total Cost";
                            Amt[8] := JobDiffBuffer2."Line Amount";
                            JobDiffBuffer2.Delete();
                        end;
                        Amt[3] := Amt[1] - Amt[2];
                        Amt[6] := Amt[4] - Amt[5];
                        Amt[9] := Amt[7] - Amt[8];

                        PrintJobTask := false;
                        for I := 1 to 9 do
                            if Amt[I] <> 0 then
                                PrintJobTask := true;
                        if not PrintJobTask then
                            CurrReport.Skip();
                        for I := 2 to 9 do begin
                            JTTotalAmt[I] := JTTotalAmt[I] + Amt[I];
                            JobTotalAmt[I] := JobTotalAmt[I] + Amt[I];
                        end;

                        ShowFirstBuffer := 1;
                    end;
                }
                dataitem(SecondBuffer; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    column(JobDiffBuffer2Type1; JobDiffBuffer2.Type)
                    {
                    }
                    column(JobDiffBuffer2No; JobDiffBuffer2."No.")
                    {
                    }
                    column(JobDiffBuffer2UOMcode; JobDiffBuffer2."Unit of Measure code")
                    {
                    }
                    column(JobDiffBuffer2WorkTypeCode; JobDiffBuffer2."Work Type Code")
                    {
                    }
                    column(Amt12; Amt[1])
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amt21; Amt[2])
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amt39; Amt[3])
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amt40; Amt[4])
                    {
                    }
                    column(Amt55; Amt[5])
                    {
                    }
                    column(Amt66; Amt[6])
                    {
                    }
                    column(Amt77; Amt[7])
                    {
                    }
                    column(Amt88; Amt[8])
                    {
                    }
                    column(Amt99; Amt[9])
                    {
                    }
                    column(ShowSecondBuffer; ShowSecondBuffer)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Clear(ShowSecondBuffer);

                        Clear(Amt);
                        if Number = 1 then begin
                            if not JobDiffBuffer2.Find('-') then
                                CurrReport.Break();
                        end else
                            if JobDiffBuffer2.Next() = 0 then
                                CurrReport.Break();
                        Amt[2] := JobDiffBuffer2.Quantity;
                        Amt[5] := JobDiffBuffer2."Total Cost";
                        Amt[8] := JobDiffBuffer2."Line Amount";
                        Amt[3] := Amt[1] - Amt[2];
                        Amt[6] := Amt[4] - Amt[5];
                        Amt[9] := Amt[7] - Amt[8];

                        PrintJobTask := false;
                        for I := 1 to 9 do
                            if Amt[I] <> 0 then
                                PrintJobTask := true;
                        if not PrintJobTask then
                            CurrReport.Skip();
                        for I := 2 to 9 do begin
                            JTTotalAmt[I] := JTTotalAmt[I] + Amt[I];
                            JobTotalAmt[I] := JobTotalAmt[I] + Amt[I];
                        end;

                        ShowSecondBuffer := 2;
                    end;
                }
                dataitem(JobTaskTotal; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                    column(JTTotalAmt4; JTTotalAmt[4])
                    {
                    }
                    column(JTTotalAmt5; JTTotalAmt[5])
                    {
                    }
                    column(JTTotalAmt6; JTTotalAmt[6])
                    {
                    }
                    column(JTTotalAmt7; JTTotalAmt[7])
                    {
                    }
                    column(JTTotalAmt8; JTTotalAmt[8])
                    {
                    }
                    column(JTTotalAmt9; JTTotalAmt[9])
                    {
                    }
                    column(JobTaskTableCaptionJobTask; Text001 + ' ' + "Job Task".TableCaption + ' ' + "Job Task"."Job Task No.")
                    {
                    }
                    column(ShowTotalJobTask; (Text001 + ' ' + "Job Task".TableCaption + ' ' + "Job Task"."Job Task No.") <> '')
                    {
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if "Job Task Type" <> "Job Task Type"::Posting then
                        CurrReport.Skip();
                    Clear(JobCalcBatches);
                    JobCalcBatches.CalculateActualToBudget(
                      Job, "Job Task", JobDiffBuffer, JobDiffBuffer2, CurrencyField);
                    if not JobDiffBuffer.Find('-') then
                        if not JobDiffBuffer2.Find('-') then
                            CurrReport.Skip();
                    for I := 1 to 9 do
                        JTTotalAmt[I] := 0;
                end;
            }
            dataitem(JobTotal; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
                column(JobTotalAmt4; JobTotalAmt[4])
                {
                }
                column(JobTotalAmt5; JobTotalAmt[5])
                {
                }
                column(JobTotalAmt6; JobTotalAmt[6])
                {
                }
                column(JobTotalAmt7; JobTotalAmt[7])
                {
                }
                column(JobTotalAmt8; JobTotalAmt[8])
                {
                }
                column(JobTotalAmt9; JobTotalAmt[9])
                {
                }
                column(ShowTotalJob; Text001 + ' ' + Job.TableCaption + ' ' + Job."No." <> '')
                {
                }
                column(JobTableCaptionNo_Job; Text001 + ' ' + Job.TableCaption + ' ' + Job."No.")
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                for I := 1 to 9 do
                    JobTotalAmt[I] := 0;
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
        JobTaskFilter := "Job Task".GetFilters;
    end;

    var
        JobDiffBuffer: Record "Job Difference Buffer" temporary;
        JobDiffBuffer2: Record "Job Difference Buffer" temporary;
        JobCalcBatches: Codeunit "Job Calculate Batches";
        Amt: array[9] of Decimal;
        JTTotalAmt: array[9] of Decimal;
        JobTotalAmt: array[9] of Decimal;
        CurrencyField: Option "Local Currency","Foreign Currency";
        JobFilter: Text;
        JobTaskFilter: Text;
        PrintJobTask: Boolean;
        I: Integer;
        Text001: Label 'Total for';
        ShowFirstBuffer: Integer;
        ShowSecondBuffer: Integer;
        CurrReportPageNoCaptionLbl: Label 'Page';
        JobActualToBudgetCaptionLbl: Label 'Job Actual To Budget';
        QuantityCaptionLbl: Label 'Quantity';
        ScheduleCaptionLbl: Label 'Budget';
        UsageCaptionLbl: Label 'Usage';
        DifferenceCaptionLbl: Label 'Difference';
        JobTaskNoCaptionLbl: Label 'Job Task No.';

    procedure InitializeRequest(NewCurrencyField: Option "Local Currency","Foreign Currency")
    begin
        CurrencyField := NewCurrencyField;
    end;
}

