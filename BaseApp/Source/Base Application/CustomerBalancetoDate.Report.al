report 121 "Customer - Balance to Date"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CustomerBalancetoDate.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Balance to Date';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = SORTING("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter", Blocked;
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(TxtCustGeTranmaxDtFilter; StrSubstNo(Text000, Format(GetRangeMax("Date Filter"))))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(PrintOnePrPage; PrintOnePrPage)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(PrintAmountInLCY; PrintAmountInLCY)
            {
            }
            column(CustTableCaptCustFilter; TableCaption + ': ' + CustFilter)
            {
            }
            column(No_Customer; "No.")
            {
            }
            column(Name_Customer; Name)
            {
            }
            column(PhoneNo_Customer; "Phone No.")
            {
                IncludeCaption = true;
            }
            column(CustBalancetoDateCaption; CustBalancetoDateCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(AllamtsareinLCYCaption; AllamtsareinLCYCaptionLbl)
            {
            }
            column(CustLedgEntryPostingDtCaption; CustLedgEntryPostingDtCaptionLbl)
            {
            }
            column(OriginalAmtCaption; OriginalAmtCaptionLbl)
            {
            }
            dataitem(CustLedgEntry3; "Cust. Ledger Entry")
            {
                DataItemTableView = SORTING("Entry No.");
                column(PostingDt_CustLedgEntry; Format("Posting Date"))
                {
                    IncludeCaption = false;
                }
                column(DocType_CustLedgEntry; "Document Type")
                {
                    IncludeCaption = true;
                }
                column(DocNo_CustLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_CustLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(OriginalAmt; OriginalAmt)
                {
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                }
                column(EntryNo_CustLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(CurrencyCode; CurrencyCode)
                {
                }
                dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
                {
                    DataItemLink = "Cust. Ledger Entry No." = FIELD("Entry No."), "Posting Date" = FIELD("Date Filter");
                    DataItemTableView = SORTING("Cust. Ledger Entry No.", "Posting Date") WHERE("Entry Type" = FILTER(<> "Initial Entry"));
                    column(EntType_DtldCustLedgEnt; "Entry Type")
                    {
                    }
                    column(postDt_DtldCustLedgEntry; Format("Posting Date"))
                    {
                    }
                    column(DocType_DtldCustLedgEntry; "Document Type")
                    {
                    }
                    column(DocNo_DtldCustLedgEntry; "Document No.")
                    {
                    }
                    column(Amt; Amt)
                    {
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(CurrencyCodeDtldCustLedgEntry; CurrencyCode)
                    {
                    }
                    column(EntNo_DtldCustLedgEntry; DtldCustLedgEntryNum)
                    {
                    }
                    column(RemainingAmt; RemainingAmt)
                    {
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not PrintUnappliedEntries then
                            if Unapplied then
                                CurrReport.Skip();

                        if PrintAmountInLCY then begin
                            Amt := "Amount (LCY)";
                            CurrencyCode := '';
                        end else begin
                            Amt := Amount;
                            CurrencyCode := "Currency Code";
                        end;
                        if Amt = 0 then
                            CurrReport.Skip();

                        DtldCustLedgEntryNum := DtldCustLedgEntryNum + 1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        DtldCustLedgEntryNum := 0;
                        CustLedgEntry3.CopyFilter("Posting Date", "Posting Date");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountInLCY then begin
                        CalcFields("Original Amt. (LCY)", "Remaining Amt. (LCY)");
                        OriginalAmt := "Original Amt. (LCY)";
                        RemainingAmt := "Remaining Amt. (LCY)";
                        CurrencyCode := '';
                    end else begin
                        CalcFields("Original Amount", "Remaining Amount");
                        OriginalAmt := "Original Amount";
                        RemainingAmt := "Remaining Amount";
                        CurrencyCode := "Currency Code";
                    end;
                end;

                trigger OnPreDataItem()
                var
                    TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
                    ClosedEntryIncluded: Boolean;
                begin
                    Reset;
                    SetRange("Date Filter", 0D, MaxDate);
                    FilterCustLedgerEntry(CustLedgEntry3);
                    if FindSet then
                        repeat
                            if not Open then
                                ClosedEntryIncluded := CheckCustEntryIncluded("Entry No.");
                            if Open or ClosedEntryIncluded then begin
                                Mark(true);
                                TempCustLedgerEntry := CustLedgEntry3;
                                TempCustLedgerEntry.Insert();
                            end;
                        until Next = 0;

                    SetCurrentKey("Entry No.");
                    MarkedOnly(true);

                    AddCustomerDimensionFilter(CustLedgEntry3);

                    CalcCustomerTotalAmount(TempCustLedgerEntry);
                end;
            }
            dataitem(Integer2; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                column(CustName; Customer.Name)
                {
                }
                column(TtlAmtCurrencyTtlBuff; CurrencyTotalBuffer."Total Amount")
                {
                    AutoFormatExpression = CurrencyTotalBuffer."Currency Code";
                    AutoFormatType = 1;
                }
                column(CurryCode_CurrencyTtBuff; CurrencyTotalBuffer."Currency Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        OK := CurrencyTotalBuffer.Find('-')
                    else
                        OK := CurrencyTotalBuffer.Next <> 0;
                    if not OK then
                        CurrReport.Break();

                    CurrencyTotalBuffer2.UpdateTotal(
                      CurrencyTotalBuffer."Currency Code",
                      CurrencyTotalBuffer."Total Amount",
                      0,
                      Counter1);
                end;

                trigger OnPostDataItem()
                begin
                    CurrencyTotalBuffer.DeleteAll();
                end;

                trigger OnPreDataItem()
                begin
                    if not ShowEntriesWithZeroBalance then
                        CurrencyTotalBuffer.SetFilter("Total Amount", '<>0');
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if MaxDate = 0D then
                    Error(BlankMaxDateErr);

                SetRange("Date Filter", 0D, MaxDate);
                CalcFields("Net Change (LCY)", "Net Change");

                if ("Net Change (LCY)" = 0) and
                   ("Net Change" = 0) and
                   (not ShowEntriesWithZeroBalance)
                then
                    CurrReport.Skip();
            end;
        }
        dataitem(Integer3; "Integer")
        {
            DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
            column(CurryCode_CurrencyTtBuff2; CurrencyTotalBuffer2."Currency Code")
            {
            }
            column(TtlAmtCurrencyTtlBuff2; CurrencyTotalBuffer2."Total Amount")
            {
                AutoFormatExpression = CurrencyTotalBuffer2."Currency Code";
                AutoFormatType = 1;
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    OK := CurrencyTotalBuffer2.Find('-')
                else
                    OK := CurrencyTotalBuffer2.Next <> 0;
                if not OK then
                    CurrReport.Break();
            end;

            trigger OnPostDataItem()
            begin
                CurrencyTotalBuffer2.DeleteAll();
            end;

            trigger OnPreDataItem()
            begin
                CurrencyTotalBuffer2.SetFilter("Total Amount", '<>0');
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
                    field("Ending Date"; MaxDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date until which information in the report is shown. If left blank, the report shows information until the present time.';
                    }
                    field(PrintAmountInLCY; PrintAmountInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if amounts in the report are displayed in LCY. If you leave the check box blank, amounts are shown in foreign currencies.';
                    }
                    field(PrintOnePrPage; PrintOnePrPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Customer';
                        ToolTip = 'Specifies if each customer balance is printed on a separate page, in case two or more customers are included in the report.';
                    }
                    field(PrintUnappliedEntries; PrintUnappliedEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Unapplied Entries';
                        ToolTip = 'Specifies if unapplied entries are included in the report.';
                    }
                    field(ShowEntriesWithZeroBalance; ShowEntriesWithZeroBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Entries with Zero Balance';
                        ToolTip = 'Specifies if the report must include entries with a balance of 0. By default, the report only includes entries with a positive or negative balance.';
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
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
    end;

    var
        Text000: Label 'Balance on %1';
        CurrencyTotalBuffer: Record "Currency Total Buffer" temporary;
        CurrencyTotalBuffer2: Record "Currency Total Buffer" temporary;
        PrintAmountInLCY: Boolean;
        PrintOnePrPage: Boolean;
        ShowEntriesWithZeroBalance: Boolean;
        CustFilter: Text;
        MaxDate: Date;
        OriginalAmt: Decimal;
        Amt: Decimal;
        RemainingAmt: Decimal;
        Counter1: Integer;
        DtldCustLedgEntryNum: Integer;
        OK: Boolean;
        CurrencyCode: Code[10];
        PrintUnappliedEntries: Boolean;
        CustBalancetoDateCaptionLbl: Label 'Customer - Balance to Date';
        CurrReportPageNoCaptionLbl: Label 'Page';
        AllamtsareinLCYCaptionLbl: Label 'All amounts are in LCY.';
        CustLedgEntryPostingDtCaptionLbl: Label 'Posting Date';
        OriginalAmtCaptionLbl: Label 'Amount';
        TotalCaptionLbl: Label 'Total';
        BlankMaxDateErr: Label 'Ending Date must have a value.';

    procedure InitializeRequest(NewPrintAmountInLCY: Boolean; NewPrintOnePrPage: Boolean; NewPrintUnappliedEntries: Boolean; NewEndingDate: Date)
    begin
        PrintAmountInLCY := NewPrintAmountInLCY;
        PrintOnePrPage := NewPrintOnePrPage;
        PrintUnappliedEntries := NewPrintUnappliedEntries;
        MaxDate := NewEndingDate;
    end;

    local procedure FilterCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        with CustLedgerEntry do begin
            SetCurrentKey("Customer No.", "Posting Date");
            SetRange("Customer No.", Customer."No.");
            SetRange("Posting Date", 0D, MaxDate);
        end;
    end;

    local procedure AddCustomerDimensionFilter(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        with CustLedgerEntry do begin
            if Customer.GetFilter("Global Dimension 1 Filter") <> '' then
                SetFilter("Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
            if Customer.GetFilter("Global Dimension 2 Filter") <> '' then
                SetFilter("Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
            if Customer.GetFilter("Currency Filter") <> '' then
                SetFilter("Currency Code", Customer.GetFilter("Currency Filter"));
        end;
    end;

    local procedure CalcCustomerTotalAmount(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    begin
        with TempCustLedgerEntry do begin
            SetCurrentKey("Entry No.");
            SetRange("Date Filter", 0D, MaxDate);
            AddCustomerDimensionFilter(TempCustLedgerEntry);
            if FindSet then
                repeat
                    if PrintAmountInLCY then begin
                        CalcFields("Remaining Amt. (LCY)");
                        RemainingAmt := "Remaining Amt. (LCY)";
                        CurrencyCode := '';
                    end else begin
                        CalcFields("Remaining Amount");
                        RemainingAmt := "Remaining Amount";
                        CurrencyCode := "Currency Code";
                    end;
                    if RemainingAmt <> 0 then
                        CurrencyTotalBuffer.UpdateTotal(
                          CurrencyCode,
                          RemainingAmt,
                          0,
                          Counter1);
                until Next = 0;
        end;
    end;

    local procedure CheckCustEntryIncluded(EntryNo: Integer): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.Get(EntryNo) and (CustLedgerEntry."Posting Date" <= MaxDate) then begin
            CustLedgerEntry.SetRange("Date Filter", 0D, MaxDate);
            CustLedgerEntry.CalcFields("Remaining Amount");
            if CustLedgerEntry."Remaining Amount" <> 0 then
                exit(true);
            if PrintUnappliedEntries then
                exit(CheckUnappliedEntryExists(EntryNo));
        end;
        exit(false);
    end;

    local procedure CheckUnappliedEntryExists(EntryNo: Integer): Boolean
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        with DetailedCustLedgEntry do begin
            SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
            SetRange("Cust. Ledger Entry No.", EntryNo);
            SetRange("Entry Type", "Entry Type"::Application);
            SetFilter("Posting Date", '>%1', MaxDate);
            SetRange(Unapplied, true);
            exit(not IsEmpty);
        end;
    end;
}

