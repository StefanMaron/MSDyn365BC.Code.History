report 10580 "Payment Practices"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PaymentPractices.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Practices';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = CONST(1));
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
            column(AvgNumberOfDaysToMakePaymentCaption; AvgNumberOfDaysToMakePaymentLbl)
            {
            }
            column(AverageDays; AvgNumberOfDays)
            {
            }
            column(AvgInvoicesExists; AvgInvoicesExists)
            {
            }
            column(PmtsNotPaidExists; PmtsNotPaidExists)
            {
            }
            column(PctOfPmtsDueCaption; PctOfPmtsDueLbl)
            {
            }
            column(PctOfPmtsDue; PctOfPmtsDue)
            {
            }
            column(StartingDate; Format(StartingDate))
            {
            }
            column(EndingDate; Format(EndingDate))
            {
            }
            column(WorkDate; Format(WorkDate()))
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

            trigger OnAfterGetRecord()
            begin
                AvgNumberOfDays := PaymentPracticesMgt.GetAvgNumberOfDaysToMakePmt(TempPaymentApplicationBuffer);
                if ShowInvoices then
                    AvgInvoicesExists := TransferMarkedEntriesIntoTempTable(TempAvgPmtApplicationBuffer, TempPaymentApplicationBuffer);
                PctOfPmtsDue := PaymentPracticesMgt.GetPctOfPmtsNotPaid(TempPaymentApplicationBuffer);
                if ShowInvoices then
                    PmtsNotPaidExists := TransferMarkedEntriesIntoTempTable(TempOverduePmtApplicationBuffer, TempPaymentApplicationBuffer);
            end;

            trigger OnPreDataItem()
            var
                PaymentPeriodSetup: Record "Payment Period Setup";
            begin
                if (StartingDate = 0D) or (EndingDate = 0D) then
                    Error(DatesNotSpecifiedErr);
                if PaymentPeriodSetup.IsEmpty() then
                    Error(PaymentPeriodSetupEmptyErr);
                PaymentPracticesMgt.BuildPmtApplicationBuffer(TempPaymentApplicationBuffer, StartingDate, EndingDate);
                if TempPaymentApplicationBuffer.IsEmpty() then
                    Error(NoInvoicesForPeriodErr);
            end;
        }
        dataitem(AvgNumberOfDaysInvoices; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(AvgVendorNo; TempAvgPmtApplicationBuffer."Vendor No.")
            {
            }
            column(AvgInvExternalDocNo; TempAvgPmtApplicationBuffer."Inv. External Document No.")
            {
            }
            column(AvgPmtInvNo; TempAvgPmtApplicationBuffer."Invoice Doc. No.")
            {
            }
            column(AvgPmtInvRcptDate; Format(TempAvgPmtApplicationBuffer."Invoice Receipt Date"))
            {
            }
            column(AvgPmtDueDate; Format(TempAvgPmtApplicationBuffer."Due Date"))
            {
            }
            column(AvgPmtPostingDate; Format(TempAvgPmtApplicationBuffer."Pmt. Posting Date"))
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number <> 1 then
                    if TempAvgPmtApplicationBuffer.Next() = 0 then
                        CurrReport.Break();
            end;

            trigger OnPreDataItem()
            begin
                if not TempAvgPmtApplicationBuffer.FindSet() then
                    CurrReport.Break();
            end;
        }
        dataitem(OverdueInvoices; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(OverdueVendorNo; TempOverduePmtApplicationBuffer."Vendor No.")
            {
            }
            column(OverdueExternalDocNo; TempOverduePmtApplicationBuffer."Inv. External Document No.")
            {
            }
            column(OverdueInvNo; TempOverduePmtApplicationBuffer."Invoice Doc. No.")
            {
            }
            column(OverdueRcptDate; Format(TempOverduePmtApplicationBuffer."Invoice Receipt Date"))
            {
            }
            column(OverdueDueDate; Format(TempOverduePmtApplicationBuffer."Due Date"))
            {
            }
            column(OverduePmtPostingDate; Format(TempOverduePmtApplicationBuffer."Pmt. Posting Date"))
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number <> 1 then
                    if TempOverduePmtApplicationBuffer.Next() = 0 then
                        CurrReport.Break();
            end;

            trigger OnPreDataItem()
            begin
                if not TempOverduePmtApplicationBuffer.FindSet() then
                    CurrReport.Break();
            end;
        }
        dataitem("Payment Period Setup"; "Payment Period Setup")
        {
            DataItemTableView = SORTING(ID);
            column(PctOfPmtsPaidInDaysLineCaption; GetPctOfPmtsPaidInDaysCaption("Days From", "Days To"))
            {
            }
            column(PctOfPmtsPaidInDays; PaymentPracticesMgt.GetPctOfPmtsPaidInDays(TempPaymentApplicationBuffer, "Days From", "Days To"))
            {
            }
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
                            CheckDateConsistency();
                        end;
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the ending date of period to report';

                        trigger OnValidate()
                        begin
                            CheckDateConsistency();
                        end;
                    }
                    field(ShowInvoices; ShowInvoices)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Invoices';
                        ToolTip = 'Specifies that list of invoices for each value has to be print.';
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

    var
        TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary;
        TempAvgPmtApplicationBuffer: Record "Payment Application Buffer" temporary;
        TempOverduePmtApplicationBuffer: Record "Payment Application Buffer" temporary;
        PaymentPracticesMgt: Codeunit "Payment Practices Mgt.";
        StartingDate: Date;
        EndingDate: Date;
        ReportNameLbl: Label 'Payment Practices';
        PageLbl: Label 'Page';
        StartingDateLaterThanEndingDateErr: Label 'Starting date cannot be later than ending date.';
        DatesNotSpecifiedErr: Label 'Both starting date and ending date must be specified.';
        PaymentPeriodSetupEmptyErr: Label 'You must update Payment Period Setup before running this report.';
        NoInvoicesForPeriodErr: Label 'No invoices posted for specified period.';
        AvgNumberOfDaysToMakePaymentLbl: Label 'The average number of days taken to make payments:';
        StartingDateLbl: Label 'Starting Date';
        EndingDateLbl: Label 'Ending Date';
        WorkDateLbl: Label 'Work Date';
        XDaysAndFewerLbl: Label '%1 days or fewer', Comment = '%1 = number of days';
        BetweenXandYDaysLbl: Label 'between %1 and %2 days', Comment = '%1%2 = number of days';
        InXDaysOrLongerLbl: Label 'in %1 days or longer', Comment = '%1 = number of days';
        PctOfPmtsDueLbl: Label 'The percentage of payments due which were not paid within agreed terms:';
        AvgNumberOfDays: Integer;
        PctOfPmtsDue: Decimal;
        AvgInvoicesExists: Boolean;
        PmtsNotPaidExists: Boolean;
        ShowInvoices: Boolean;

    local procedure CheckDateConsistency()
    begin
        if (StartingDate <> 0D) and (EndingDate <> 0D) and (StartingDate > EndingDate) then
            Error(StartingDateLaterThanEndingDateErr);
    end;

    local procedure GetPctOfPmtsPaidInDaysCaption(DaysFrom: Integer; DaysTo: Integer): Text
    begin
        if DaysFrom = 0 then
            exit(StrSubstNo(XDaysAndFewerLbl, DaysTo));
        if DaysTo = 0 then
            exit(StrSubstNo(InXDaysOrLongerLbl, DaysFrom));
        exit(StrSubstNo(BetweenXandYDaysLbl, DaysFrom, DaysTo));
    end;

    local procedure TransferMarkedEntriesIntoTempTable(var TempAvgPmtApplicationBuffer: Record "Payment Application Buffer" temporary; var TempPaymentApplicationBuffer: Record "Payment Application Buffer" temporary) Exists: Boolean
    begin
        TempPaymentApplicationBuffer.MarkedOnly(true);
        if TempPaymentApplicationBuffer.FindSet() then
            repeat
                TempAvgPmtApplicationBuffer := TempPaymentApplicationBuffer;
                TempAvgPmtApplicationBuffer.Insert();
                Exists := true;
            until TempPaymentApplicationBuffer.Next() = 0;
        TempPaymentApplicationBuffer.MarkedOnly(false);
        TempPaymentApplicationBuffer.ClearMarks();
    end;
}

