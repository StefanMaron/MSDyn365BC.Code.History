report 10887 "Payment Practices Reporting"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PaymentPracticesReporting.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Practices Reporting';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(ShowInvoices; ShowInvoices)
            {
            }
            column(CurrDate; Format(CurrentDateTime))
            {
            }
            column(CompanyNameCaption; CompanyName)
            {
            }
            column(ReportNameLbl; ReportNameLbl)
            {
            }
            column(PageLbl; PageLbl)
            {
            }
            column(StartingDate; Format(StartingDate))
            {
            }
            column(EndingDate; Format(EndingDate))
            {
            }
            column(WorkDate; Format(WorkDate))
            {
            }
            column(StartingDateLbl; StartingDateLbl)
            {
            }
            column(EndingDateLbl; EndingDateLbl)
            {
            }
            column(WorkDateLbl; WorkDateLbl)
            {
            }
            column(TotalNotPaidLbl; TotalInvoicesLbl)
            {
            }
            column(InvoicesReceivedNotPaidLbl; InvoicesReceivedNotPaidLbl)
            {
            }
            column(InvoicesIssuedNotPaidLbl; InvoicesIssuedNotPaidLbl)
            {
            }
            column(InvoicedReceivedDelayedLbl; InvoicedReceivedDelayedLbl)
            {
            }
            column(InvoicesIssuedDelayedLbl; InvoicesIssuedDelayedLbl)
            {
            }
            column(AmountLbl; AmountLbl)
            {
            }
            column(TotalAmountLbl; TotalAmountLbl)
            {
            }
            column(PercentLbl; PercentLbl)
            {
            }
            column(TotalPercentLbl; TotalPercentLbl)
            {
            }
            column(TotalAmountOfInvoicesLbl; TotalAmountOfInvoicesLbl)
            {
            }
            column(TotalVendAmount; TotalVendAmount)
            {
            }
            column(TotalCustAmount; TotalCustAmount)
            {
            }
            column(VendPeriodLbl; PeriodLbl)
            {
            }
            column(VendPeriodAmountLbl; AmountLbl)
            {
            }
            column(VendPercentLbl; PercentLbl)
            {
            }
        }
        dataitem(VendNotPaidInDays; "Payment Period Setup")
        {
            DataItemTableView = SORTING(ID);
            column(NotPaidVendShowInvoices; ShowInvoices)
            {
            }
            column(NotPaidVendPeriod; Format("Days From") + '-' + Format("Days To"))
            {
            }
            column(NotPaidVendAmount; AmountByPeriod)
            {
            }
            column(NotPaidVendPct; PctByPeriod)
            {
            }
            column(NotPaidVendPctGrpNumber; GroupingNum)
            {
            }
            column(NotPaidVendPeriodLbl; PeriodLbl)
            {
            }
            column(NotPaidVendPeriodAmountLbl; AmountLbl)
            {
            }
            column(NotPaidVendPercentLbl; PercentLbl)
            {
            }
            dataitem(VendEntriesNotPaidInDays; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(NotPaidVendEntryNoLbl; EntryNoLbl)
                {
                }
                column(NotPaidVendNoLbl; VendNoLbl)
                {
                }
                column(NotPaidVendInvNoLbl; InvNoLbl)
                {
                }
                column(NotPaidVendExtDocNolbl; ExtDocNoLbl)
                {
                }
                column(NotPaidVendDueDateLbl; DueDateLbl)
                {
                }
                column(NotPaidVendAmountLbl; InitialAmountLbl)
                {
                }
                column(NotPaidVendAmountCorrectedLbl; AmountCorrectedLbl)
                {
                }
                column(NotPaidVendRemainingAmountLbl; RemainingAmountLbl)
                {
                }
                column(NotPaidVendInvEntryNo; TempVendPmtApplicationBuffer."Invoice Entry No.")
                {
                }
                column(NotPaidVendNo; TempVendPmtApplicationBuffer."CV No.")
                {
                }
                column(NotPaidVendDocNo; TempVendPmtApplicationBuffer."Invoice Doc. No.")
                {
                }
                column(NotPaidVendExtDocNo; TempVendPmtApplicationBuffer."Inv. External Document No.")
                {
                }
                column(NotPaidVendDueDate; Format(TempVendPmtApplicationBuffer."Due Date"))
                {
                }
                column(NotPaidVendInvAmount; TempVendPmtApplicationBuffer."Entry Amount (LCY)")
                {
                }
                column(NotPaidVendInvAmountCorrected; TempVendPmtApplicationBuffer."Entry Amount Corrected (LCY)")
                {
                }
                column(NotPaidVendRemainingAmount; TempVendPmtApplicationBuffer."Remaining Amount (LCY)")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number <> 1 then
                        if TempVendPmtApplicationBuffer.Next = 0 then
                            CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    if ShowInvoices then
                        TempVendPmtApplicationBuffer.FindSet
                    else
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not PaymentReportingMgt.PrepareNotPaidInDaysSource(TempVendPmtApplicationBuffer, "Days From", "Days To") then
                    CurrReport.Skip();

                TempVendPmtApplicationBuffer.CalcSumOfAmountFields;
                AmountByPeriod := TempVendPmtApplicationBuffer."Remaining Amount (LCY)";
                PctByPeriod := PaymentReportingMgt.GetPctOfPmtsNotPaidInDays(TempVendPmtApplicationBuffer, TotalVendAmount);
                TotalInvoices += TempVendPmtApplicationBuffer.Count();
                TotalAmtByPeriod += AmountByPeriod;
                TotalPctByPeriod += PctByPeriod;
                GroupingNum += 1;
            end;

            trigger OnPreDataItem()
            begin
                TotalInvoices := 0;
                TotalAmtByPeriod := 0;
                TotalPctByPeriod := 0;
            end;
        }
        dataitem(NotPaidVendTotal; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(NotPaidVendTotalInvoices; TotalInvoices)
            {
            }
            column(NotPaidVendTotalAmtByPeriod; TotalAmtByPeriod)
            {
            }
            column(NotPaidVendTotalPctByPeriod; TotalPctByPeriod)
            {
            }
        }
        dataitem(VendDelayedInDays; "Payment Period Setup")
        {
            DataItemTableView = SORTING(ID);
            column(DelayedVendShowInvoices; ShowInvoices)
            {
            }
            column(DelayedVendPeriod; Format("Days From") + '-' + Format("Days To"))
            {
            }
            column(DelayedVendAmount; AmountByPeriod)
            {
            }
            column(DelayedVendPct; PctByPeriod)
            {
            }
            column(DelayedVendPctGrpNumber; GroupingNum)
            {
            }
            column(DelayedVendPeriodLbl; PeriodLbl)
            {
            }
            column(DelayedVendPeriodAmountLbl; AmountLbl)
            {
            }
            column(DelayedVendPercentLbl; PercentLbl)
            {
            }
            dataitem(VendEntriesDelayedInDays; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(DelayedVendEntryNoLbl; EntryNoLbl)
                {
                }
                column(DelayedVendPmtEntryNoLbl; PmtEntryNoLbl)
                {
                }
                column(DelayedVendNoLbl; VendNoLbl)
                {
                }
                column(DelayedVendInvNoLbl; InvNoLbl)
                {
                }
                column(DelayedVendPmtNoLbl; PmtNoLbl)
                {
                }
                column(DelayedVendExtDocNolbl; ExtDocNoLbl)
                {
                }
                column(DelayedVendDueDateLbl; DueDateLbl)
                {
                }
                column(DelayedVendPmtPostingDateLbl; PmtPostingDateLbl)
                {
                }
                column(DelayedVendPmtAmountLbl; PmtAmountLbl)
                {
                }
                column(DelayedVendInvEntryNo; TempVendPmtApplicationBuffer."Invoice Entry No.")
                {
                }
                column(DelayedVendNo; TempVendPmtApplicationBuffer."CV No.")
                {
                }
                column(DelayedVendDocNo; TempVendPmtApplicationBuffer."Invoice Doc. No.")
                {
                }
                column(DelayedVendExtDocNo; TempVendPmtApplicationBuffer."Inv. External Document No.")
                {
                }
                column(DelayedVendDueDate; Format(TempVendPmtApplicationBuffer."Due Date"))
                {
                }
                column(DelayedVendPmtPostingDate; Format(TempVendPmtApplicationBuffer."Pmt. Posting Date"))
                {
                }
                column(DelayedVendPmtEntryNo; TempVendPmtApplicationBuffer."Pmt. Entry No.")
                {
                }
                column(DelayedVendPmtNo; TempVendPmtApplicationBuffer."Pmt. Doc. No.")
                {
                }
                column(DelayedVendPmtAmount; TempVendPmtApplicationBuffer."Pmt. Amount (LCY)")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number <> 1 then
                        if TempVendPmtApplicationBuffer.Next = 0 then
                            CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    if ShowInvoices then
                        TempVendPmtApplicationBuffer.FindSet
                    else
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not PaymentReportingMgt.PrepareDelayedPmtInDaysSource(TempVendPmtApplicationBuffer, "Days From", "Days To") then
                    CurrReport.Skip();

                TempVendPmtApplicationBuffer.CalcSumOfAmountFields;
                AmountByPeriod := TempVendPmtApplicationBuffer."Pmt. Amount (LCY)";
                PctByPeriod := PaymentReportingMgt.GetPctOfPmtsDelayedInDays(TempVendPmtApplicationBuffer, TotalVendAmount);
                TotalInvoices += TempVendPmtApplicationBuffer.Count();
                TotalAmtByPeriod += AmountByPeriod;
                TotalPctByPeriod += PctByPeriod;
                GroupingNum += 1;
            end;

            trigger OnPreDataItem()
            begin
                TotalInvoices := 0;
                TotalAmtByPeriod := 0;
                TotalPctByPeriod := 0;
            end;
        }
        dataitem(VendDelayedTotal; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(DelayedVendTotalInvoices; TotalInvoices)
            {
            }
            column(DelayedVendTotalAmtByPeriod; TotalAmtByPeriod)
            {
            }
            column(DelayedVendTotalPctByPeriod; TotalPctByPeriod)
            {
            }

            trigger OnPostDataItem()
            begin
                TotalInvoices := 0;
                TotalAmtByPeriod := 0;
                TotalPctByPeriod := 0;
            end;
        }
        dataitem(CustNotPaidInDays; "Payment Period Setup")
        {
            DataItemTableView = SORTING(ID);
            column(NotPaidCustShowInvoices; ShowInvoices)
            {
            }
            column(NotPaidCustPeriod; Format("Days From") + '-' + Format("Days To"))
            {
            }
            column(NotPaidCustAmount; AmountByPeriod)
            {
            }
            column(NotPaidCustPct; PctByPeriod)
            {
            }
            column(NotPaidCustPctGrpNumber; GroupingNum)
            {
            }
            column(NotPaidCustPeriodLbl; PeriodLbl)
            {
            }
            column(NotPaidCustPeriodAmountLbl; AmountLbl)
            {
            }
            column(NotPaidCustPercentLbl; PercentLbl)
            {
            }
            dataitem(CustEntriesNotPaidInDays; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(NotPaidCustEntryNoLbl; EntryNoLbl)
                {
                }
                column(NotPaidCustNoLbl; CustNoLbl)
                {
                }
                column(NotPaidCustInvNoLbl; InvNoLbl)
                {
                }
                column(NotPaidCustDueDateLbl; DueDateLbl)
                {
                }
                column(NotPaidCustAmountLbl; InitialAmountLbl)
                {
                }
                column(NotPaidCustAmountCorrectedLbl; AmountCorrectedLbl)
                {
                }
                column(NotPaidCustRemainingAmountLbl; RemainingAmountLbl)
                {
                }
                column(NotPaidCustInvEntryNo; TempCustPmtApplicationBuffer."Invoice Entry No.")
                {
                }
                column(NotPaidCustNo; TempCustPmtApplicationBuffer."CV No.")
                {
                }
                column(NotPaidCustDocNo; TempCustPmtApplicationBuffer."Invoice Doc. No.")
                {
                }
                column(NotPaidCustDueDate; Format(TempCustPmtApplicationBuffer."Due Date"))
                {
                }
                column(NotPaidCustInvAmount; TempCustPmtApplicationBuffer."Entry Amount (LCY)")
                {
                }
                column(NotPaidCustInvAmountCorrected; TempCustPmtApplicationBuffer."Entry Amount Corrected (LCY)")
                {
                }
                column(NotPaidCustRemainingAmount; TempCustPmtApplicationBuffer."Remaining Amount (LCY)")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number <> 1 then
                        if TempCustPmtApplicationBuffer.Next = 0 then
                            CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    if ShowInvoices then
                        TempCustPmtApplicationBuffer.FindSet
                    else
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not PaymentReportingMgt.PrepareNotPaidInDaysSource(TempCustPmtApplicationBuffer, "Days From", "Days To") then
                    CurrReport.Skip();

                TempCustPmtApplicationBuffer.CalcSumOfAmountFields;
                AmountByPeriod := TempCustPmtApplicationBuffer."Remaining Amount (LCY)";
                PctByPeriod := PaymentReportingMgt.GetPctOfPmtsNotPaidInDays(TempCustPmtApplicationBuffer, TotalCustAmount);
                TotalInvoices += TempCustPmtApplicationBuffer.Count();
                TotalAmtByPeriod += AmountByPeriod;
                TotalPctByPeriod += PctByPeriod;
                GroupingNum += 1;
            end;

            trigger OnPreDataItem()
            begin
                TotalInvoices := 0;
                TotalAmtByPeriod := 0;
                TotalPctByPeriod := 0;
            end;
        }
        dataitem(NotPaidCustTotal; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(NotPaidCustTotalInvoices; TotalInvoices)
            {
            }
            column(NotPaidCustTotalAmtByPeriod; TotalAmtByPeriod)
            {
            }
            column(NotPaidCustTotalPctByPeriod; TotalPctByPeriod)
            {
            }
        }
        dataitem(CustDelayedInDays; "Payment Period Setup")
        {
            DataItemTableView = SORTING(ID);
            column(DelayedCustShowInvoices; ShowInvoices)
            {
            }
            column(DelayedCustPeriod; Format("Days From") + '-' + Format("Days To"))
            {
            }
            column(DelayedCustAmount; AmountByPeriod)
            {
            }
            column(DelayedCustPct; PctByPeriod)
            {
            }
            column(DelayedCustPctGrpNumber; GroupingNum)
            {
            }
            column(DelayedCustPeriodLbl; PeriodLbl)
            {
            }
            column(DelayedCustPeriodAmountLbl; AmountLbl)
            {
            }
            column(DelayedCustPercentLbl; PercentLbl)
            {
            }
            dataitem(CustEntriesDelayedInDays; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(DelayedCustEntryNoLbl; EntryNoLbl)
                {
                }
                column(DelayedCustPmtEntryNoLbl; PmtEntryNoLbl)
                {
                }
                column(DelayedCustNoLbl; CustNoLbl)
                {
                }
                column(DelayedCustInvNoLbl; InvNoLbl)
                {
                }
                column(DelayedCustPmtNoLbl; PmtNoLbl)
                {
                }
                column(DelayedCustDueDateLbl; DueDateLbl)
                {
                }
                column(DelayedCustPmtPostingDateLbl; PmtPostingDateLbl)
                {
                }
                column(DelayedCustPmtAmountLbl; PmtAmountLbl)
                {
                }
                column(DelayedCustInvEntryNo; TempCustPmtApplicationBuffer."Invoice Entry No.")
                {
                }
                column(DelayedCustNo; TempCustPmtApplicationBuffer."CV No.")
                {
                }
                column(DelayedCustDocNo; TempCustPmtApplicationBuffer."Invoice Doc. No.")
                {
                }
                column(DelayedCustDueDate; Format(TempCustPmtApplicationBuffer."Due Date"))
                {
                }
                column(DelayedCustPmtPostingDate; Format(TempCustPmtApplicationBuffer."Pmt. Posting Date"))
                {
                }
                column(DelayedCustPmtEntryNo; TempCustPmtApplicationBuffer."Pmt. Entry No.")
                {
                }
                column(DelayedCustPmtNo; TempCustPmtApplicationBuffer."Pmt. Doc. No.")
                {
                }
                column(DelayedCustPmtAmount; TempCustPmtApplicationBuffer."Pmt. Amount (LCY)")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number <> 1 then
                        if TempCustPmtApplicationBuffer.Next = 0 then
                            CurrReport.Break();
                end;

                trigger OnPreDataItem()
                begin
                    if ShowInvoices then
                        TempCustPmtApplicationBuffer.FindSet
                    else
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not PaymentReportingMgt.PrepareDelayedPmtInDaysSource(TempCustPmtApplicationBuffer, "Days From", "Days To") then
                    CurrReport.Skip();

                TempCustPmtApplicationBuffer.CalcSumOfAmountFields;
                AmountByPeriod := TempCustPmtApplicationBuffer."Pmt. Amount (LCY)";
                PctByPeriod := PaymentReportingMgt.GetPctOfPmtsDelayedInDays(TempCustPmtApplicationBuffer, TotalCustAmount);
                TotalInvoices += TempCustPmtApplicationBuffer.Count();
                TotalAmtByPeriod += AmountByPeriod;
                TotalPctByPeriod += PctByPeriod;
                GroupingNum += 1;
            end;

            trigger OnPreDataItem()
            begin
                TotalInvoices := 0;
                TotalAmtByPeriod := 0;
                TotalPctByPeriod := 0;
            end;
        }
        dataitem(CustDelayedTotal; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
            column(DelayedCustTotalInvoices; TotalInvoices)
            {
            }
            column(DelayedCustTotalAmtByPeriod; TotalAmtByPeriod)
            {
            }
            column(DelayedCustTotalPctByPeriod; TotalPctByPeriod)
            {
            }

            trigger OnPostDataItem()
            begin
                TotalInvoices := 0;
                TotalAmtByPeriod := 0;
                TotalPctByPeriod := 0;
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
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the starting date of period to report';

                        trigger OnValidate()
                        begin
                            CheckDateConsistency;
                        end;
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the ending date of period to report';

                        trigger OnValidate()
                        begin
                            CheckDateConsistency;
                        end;
                    }
                    field(ShowInvoices; ShowInvoices)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Invoices';
                        ToolTip = 'Specifies that list of invoices for each value has to be print.';
                    }
                    field(PaymentsWithinPeriod; PaymentsWithinPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payments within period';
                        ToolTip = 'Specifies to consider only payments within the period from starting date to ending date.';
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
    var
        PaymentPeriodSetup: Record "Payment Period Setup";
    begin
        if (StartingDate = 0D) or (EndingDate = 0D) then
            Error(DatesNotSpecifiedErr);
        if PaymentPeriodSetup.IsEmpty then
            Error(PaymentPeriodSetupEmptyErr);
        PaymentReportingMgt.BuildVendPmtApplicationBuffer(TempVendPmtApplicationBuffer, StartingDate, EndingDate, PaymentsWithinPeriod);
        PaymentReportingMgt.BuildCustPmtApplicationBuffer(TempCustPmtApplicationBuffer, StartingDate, EndingDate, PaymentsWithinPeriod);
        if TempVendPmtApplicationBuffer.IsEmpty and TempCustPmtApplicationBuffer.IsEmpty then
            Error(NoInvoicesForPeriodErr);
        TotalVendAmount := PaymentReportingMgt.GetTotalAmount(TempVendPmtApplicationBuffer);
        TotalCustAmount := PaymentReportingMgt.GetTotalAmount(TempCustPmtApplicationBuffer);
    end;

    var
        TempVendPmtApplicationBuffer: Record "Payment Application Buffer" temporary;
        TempCustPmtApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentReportingMgt: Codeunit "Payment Reporting Mgt.";
        StartingDate: Date;
        EndingDate: Date;
        ShowInvoices: Boolean;
        StartingDateLaterThanEndingDateErr: Label 'Starting date cannot be later than ending date.';
        DatesNotSpecifiedErr: Label 'Both starting date and ending date must be specified.';
        PaymentPeriodSetupEmptyErr: Label 'You must update Payment Period Setup before running this report.';
        NoInvoicesForPeriodErr: Label 'No invoices posted for specified period.';
        PaymentsWithinPeriod: Boolean;
        TotalVendAmount: Decimal;
        TotalCustAmount: Decimal;
        AmountByPeriod: Decimal;
        PctByPeriod: Decimal;
        TotalInvoices: Integer;
        TotalAmtByPeriod: Decimal;
        TotalPctByPeriod: Decimal;
        GroupingNum: Integer;
        StartingDateLbl: Label 'Starting date';
        EndingDateLbl: Label 'Ending date';
        WorkDateLbl: Label 'Work date';
        ReportNameLbl: Label 'Payment Practices Reporting';
        PageLbl: Label 'Page';
        InvoicesReceivedNotPaidLbl: Label 'Invoices received not paid on the closing date of the year in which the term has expired:';
        InvoicesIssuedNotPaidLbl: Label 'Invoices issued not paid on the closing date of the year in which the term has expired:';
        InvoicedReceivedDelayedLbl: Label 'Invoices received that have been delayed in payment during the year:';
        InvoicesIssuedDelayedLbl: Label 'Invoices issued that have been delayed in payment during the year:';
        PeriodLbl: Label 'Period';
        VendNoLbl: Label 'Vendor No.';
        CustNoLbl: Label 'Customer No.';
        InvNoLbl: Label 'Invoice No.';
        PmtNoLbl: Label 'Payment No.';
        DueDateLbl: Label 'Due Date';
        PercentLbl: Label '%', Locked = true;
        TotalPercentLbl: Label 'Total %';
        EntryNoLbl: Label 'Entry No.';
        PmtEntryNoLbl: Label 'Pmt. Entry No.';
        ExtDocNoLbl: Label 'External Doc. No.';
        InitialAmountLbl: Label 'Amount';
        AmountLbl: Label 'Amount';
        TotalAmountLbl: Label 'Total Amount';
        AmountCorrectedLbl: Label 'Amount Corrected';
        PmtPostingDateLbl: Label 'Payment posting date';
        PmtAmountLbl: Label 'Payment amount';
        RemainingAmountLbl: Label 'Amount Due';
        TotalInvoicesLbl: Label 'Total invoices';
        TotalAmountOfInvoicesLbl: Label 'Total amount of invoices (Corrected)';

    local procedure CheckDateConsistency()
    begin
        if (StartingDate <> 0D) and (EndingDate <> 0D) and (StartingDate > EndingDate) then
            Error(StartingDateLaterThanEndingDateErr);
    end;
}

