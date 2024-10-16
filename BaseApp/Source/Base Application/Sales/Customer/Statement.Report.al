﻿namespace Microsoft.Sales.Customer;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Email;
using System.Globalization;
using System.Utilities;

report 116 Statement
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Customer/Statement.rdlc';
    Caption = 'Statement';

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Print Statements", "Currency Filter";
            column(No_Cust; "No.")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(CompanyInfo1Picture; CompanyInfo1.Picture)
                {
                }
                column(CompanyInfo2Picture; CompanyInfo2.Picture)
                {
                }
                column(CompanyInfo3Picture; CompanyInfo3.Picture)
                {
                }
                column(CustAddr1; CustAddr[1])
                {
                }
                column(CompanyAddr1; CompanyAddr[1])
                {
                }
                column(CustAddr2; CustAddr[2])
                {
                }
                column(CompanyAddr2; CompanyAddr[2])
                {
                }
                column(CustAddr3; CustAddr[3])
                {
                }
                column(CompanyAddr3; CompanyAddr[3])
                {
                }
                column(CustAddr4; CustAddr[4])
                {
                }
                column(CompanyAddr4; CompanyAddr[4])
                {
                }
                column(CustAddr5; CustAddr[5])
                {
                }
                column(PhoneNo_CompanyInfo; CompanyInfo."Phone No.")
                {
                }
                column(CustAddr6; CustAddr[6])
                {
                }
                column(CompanyInfoEmail; CompanyInfo."E-Mail")
                {
                }
                column(CompanyInfoHomePage; CompanyInfo."Home Page")
                {
                }
                column(VATRegNo_CompanyInfo; CompanyInfo."VAT Registration No.")
                {
                }
                column(GiroNo_CompanyInfo; CompanyInfo."Giro No.")
                {
                }
                column(BankName_CompanyInfo; CompanyInfo."Bank Name")
                {
                }
                column(BankAccNo_CompanyInfo; CompanyInfo."Bank Account No.")
                {
                }
                column(No1_Cust; Customer."No.")
                {
                }
                column(TodayFormatted; Format(Today, 0, 4))
                {
                }
                column(StartDate; Format(StartDate))
                {
                }
                column(EndDate; Format(EndDate))
                {
                }
                column(LastStatmntNo_Cust; Format(Customer."Last Statement No."))
                {
                }
                column(CustAddr7; CustAddr[7])
                {
                }
                column(CustAddr8; CustAddr[8])
                {
                }
                column(CompanyAddr7; CompanyAddr[7])
                {
                }
                column(CompanyAddr8; CompanyAddr[8])
                {
                }
                column(StatementCaption; StatementCaptionLbl)
                {
                }
                column(PhoneNo_CompanyInfoCaption; PhoneNo_CompanyInfoCaptionLbl)
                {
                }
                column(VATRegNo_CompanyInfoCaption; VATRegNo_CompanyInfoCaptionLbl)
                {
                }
                column(GiroNo_CompanyInfoCaption; GiroNo_CompanyInfoCaptionLbl)
                {
                }
                column(BankName_CompanyInfoCaption; BankName_CompanyInfoCaptionLbl)
                {
                }
                column(BankAccNo_CompanyInfoCaption; BankAccNo_CompanyInfoCaptionLbl)
                {
                }
                column(No1_CustCaption; No1_CustCaptionLbl)
                {
                }
                column(StartDateCaption; StartDateCaptionLbl)
                {
                }
                column(EndDateCaption; EndDateCaptionLbl)
                {
                }
                column(LastStatmntNo_CustCaption; LastStatmntNo_CustCaptionLbl)
                {
                }
                column(PostDate_DtldCustLedgEntriesCaption; PostDate_DtldCustLedgEntriesCaptionLbl)
                {
                }
                column(DocNo_DtldCustLedgEntriesCaption; "Detailed Cust. Ledg. Entry".FieldCaption("Document No."))
                {
                }
                column(Desc_CustLedgEntry2Caption; CustLedgEntry2.FieldCaption(Description))
                {
                }
                column(DueDate_CustLedgEntry2Caption; DueDate_CustLedgEntry2CaptionLbl)
                {
                }
                column(RemainAmtCustLedgEntry2Caption; CustLedgEntry2.FieldCaption("Remaining Amount"))
                {
                }
                column(CustBalanceCaption; CustBalanceCaptionLbl)
                {
                }
                column(OriginalAmt_CustLedgEntry2Caption; CustLedgEntry2.FieldCaption("Original Amount"))
                {
                }
                column(CompanyInfoHomepageCaption; CompanyInfoHomepageCaptionLbl)
                {
                }
                column(CompanyInfoEmailCaption; CompanyInfoEmailCaptionLbl)
                {
                }
                column(DocDateCaption; DocDateCaptionLbl)
                {
                }
                column(Total_Caption2; Total_CaptionLbl)
                {
                }
                column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                {
                }
                column(EnterpriseClassification; CompanyInfo.GetEnterpriseClassification())
                {
                }
                dataitem(CurrencyLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    PrintOnlyIfDetail = true;
                    dataitem(CustLedgEntryHdr; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(Currency2Code_CustLedgEntryHdr; StrSubstNo(Text001Lbl, CurrencyCode3))
                        {
                        }
                        column(StartBalance; StartBalance)
                        {
                            AutoFormatExpression = TempCurrency2.Code;
                            AutoFormatType = 1;
                        }
                        column(CurrencyCode3; CurrencyCode3)
                        {
                        }
                        column(CustBalance_CustLedgEntryHdr; CustBalance)
                        {
                        }
                        column(PrintLine; PrintLine)
                        {
                        }
                        column(DtldCustLedgEntryType; Format("Detailed Cust. Ledg. Entry"."Entry Type", 0, 2))
                        {
                        }
                        column(EntriesExists; EntriesExists)
                        {
                        }
                        column(IsNewCustCurrencyGroup; IsNewCustCurrencyGroup)
                        {
                        }
                        dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
                        {
                            DataItemTableView = sorting("Customer No.", "Posting Date", "Entry Type", "Currency Code");
                            column(PostDate_DtldCustLedgEntries; Format("Posting Date"))
                            {
                            }
                            column(DocNo_DtldCustLedgEntries; "Document No.")
                            {
                            }
                            column(Description; Description)
                            {
                            }
                            column(DueDate_DtldCustLedgEntries; Format(DueDate))
                            {
                            }
                            column(CurrCode_DtldCustLedgEntries; "Currency Code")
                            {
                            }
                            column(Amt_DtldCustLedgEntries; Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(RemainAmt_DtldCustLedgEntries; RemainingAmount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(CustBalance; CustBalance)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(Currency2Code; TempCurrency2.Code)
                            {
                            }

                            trigger OnAfterGetRecord()
                            var
                                CustLedgerEntry: Record "Cust. Ledger Entry";
                            begin
                                if SkipReversedUnapplied("Detailed Cust. Ledg. Entry") or (Amount = 0) then
                                    CurrReport.Skip();
                                RemainingAmount := 0;
                                PrintLine := true;
                                case "Entry Type" of
                                    "Entry Type"::"Initial Entry":
                                        begin
                                            CustLedgerEntry.Get("Cust. Ledger Entry No.");
                                            Description := CustLedgerEntry.Description;
                                            DueDate := CustLedgerEntry."Due Date";
                                            CustLedgerEntry.SetRange("Date Filter", 0D, EndDate);
                                            CustLedgerEntry.CalcFields("Remaining Amount");
                                            RemainingAmount := CustLedgerEntry."Remaining Amount";
                                        end;
                                    "Entry Type"::Application:
                                        begin
                                            DetailedCustLedgEntry.SetCurrentKey("Customer No.", "Posting Date", "Entry Type");
                                            DetailedCustLedgEntry.SetRange("Customer No.", "Customer No.");
                                            DetailedCustLedgEntry.SetRange("Posting Date", "Posting Date");
                                            DetailedCustLedgEntry.SetRange("Entry Type", "Entry Type"::Application);
                                            DetailedCustLedgEntry.SetRange("Transaction No.", "Transaction No.");
                                            DetailedCustLedgEntry.SetFilter("Currency Code", '<>%1', "Currency Code");
                                            if not DetailedCustLedgEntry.IsEmpty() then begin
                                                Description := Text005Txt;
                                                DueDate := 0D;
                                            end else
                                                PrintLine := false;
                                        end;
                                    "Entry Type"::"Payment Discount",
                                    "Entry Type"::"Payment Discount (VAT Excl.)",
                                    "Entry Type"::"Payment Discount (VAT Adjustment)",
                                    "Entry Type"::"Payment Discount Tolerance",
                                    "Entry Type"::"Payment Discount Tolerance (VAT Excl.)",
                                    "Entry Type"::"Payment Discount Tolerance (VAT Adjustment)":
                                        begin
                                            Description := Text006Txt;
                                            DueDate := 0D;
                                        end;
                                    "Entry Type"::"Payment Tolerance",
                                    "Entry Type"::"Payment Tolerance (VAT Excl.)",
                                    "Entry Type"::"Payment Tolerance (VAT Adjustment)":
                                        begin
                                            Description := Text014Txt;
                                            DueDate := 0D;
                                        end;
                                    "Entry Type"::"Appln. Rounding",
                                    "Entry Type"::"Correction of Remaining Amount":
                                        begin
                                            Description := Text007Txt;
                                            DueDate := 0D;
                                        end;
                                end;

                                if PrintLine then begin
                                    CustBalance := CustBalance + Amount;
                                    IsNewCustCurrencyGroup := IsFirstPrintLine;
                                    IsFirstPrintLine := false;
                                    ClearCompanyPicture();
                                end;
                            end;

                            trigger OnPreDataItem()
                            begin
                                SetRange("Customer No.", Customer."No.");
                                SetRange("Posting Date", StartDate, EndDate);
                                SetRange("Currency Code", TempCurrency2.Code);

                                if TempCurrency2.Code = '' then begin
                                    GLSetup.TestField("LCY Code");
                                    CurrencyCode3 := GLSetup."LCY Code"
                                end else
                                    CurrencyCode3 := TempCurrency2.Code;

                                IsFirstPrintLine := true;
                            end;
                        }
                    }
                    dataitem(CustLedgEntryFooter; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(CurrencyCode3_CustLedgEntryFooter; CurrencyCode3)
                        {
                        }
                        column(Total_Caption; Total_CaptionLbl)
                        {
                        }
                        column(CustBalance_CustLedgEntryHdrFooter; CustBalance)
                        {
                            AutoFormatExpression = TempCurrency2.Code;
                            AutoFormatType = 1;
                        }
                        column(EntriesExistsl_CustLedgEntryFooterCaption; EntriesExists)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            ClearCompanyPicture();
                        end;
                    }
                    dataitem(CustLedgEntry2; "Cust. Ledger Entry")
                    {
                        DataItemLink = "Customer No." = field("No.");
                        DataItemLinkReference = Customer;
                        DataItemTableView = sorting("Customer No.", Open, Positive, "Due Date");
                        column(OverDueEntries; StrSubstNo(Text002Lbl, TempCurrency2.Code))
                        {
                        }
                        column(RemainAmt_CustLedgEntry2; "Remaining Amount")
                        {
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                        }
                        column(PostDate_CustLedgEntry2; Format("Posting Date"))
                        {
                        }
                        column(DocNo_CustLedgEntry2; "Document No.")
                        {
                        }
                        column(Desc_CustLedgEntry2; Description)
                        {
                        }
                        column(DueDate_CustLedgEntry2; Format("Due Date"))
                        {
                        }
                        column(OriginalAmt_CustLedgEntry2; "Original Amount")
                        {
                            AutoFormatExpression = "Currency Code";
                        }
                        column(CurrCode_CustLedgEntry2; "Currency Code")
                        {
                        }
                        column(PrintEntriesDue; PrintEntriesDue)
                        {
                        }
                        column(Currency2Code_CustLedgEntry2; TempCurrency2.Code)
                        {
                        }
                        column(CurrencyCode3_CustLedgEntry2; CurrencyCode3)
                        {
                        }
                        column(CustNo_CustLedgEntry2; "Customer No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                            CustLedgEntry: Record "Cust. Ledger Entry";
                        begin
                            if IncludeAgingBand then begin
                                if ("Posting Date" > EndDate) and ("Due Date" >= EndDate) then
                                    CurrReport.Skip();
                                if DateChoice = DateChoice::"Due Date" then
                                    if "Due Date" >= EndDate then
                                        CurrReport.Skip();
                            end;
                            CustLedgEntry := CustLedgEntry2;
                            CustLedgEntry.SetRange("Date Filter", 0D, EndDate);
                            CustLedgEntry.CalcFields("Remaining Amount");
                            "Remaining Amount" := CustLedgEntry."Remaining Amount";
                            if CustLedgEntry."Remaining Amount" = 0 then
                                CurrReport.Skip();

                            if IncludeAgingBand and ("Posting Date" <= EndDate) then
                                UpdateBuffer(TempCurrency2.Code, GetDate("Posting Date", "Due Date"), "Remaining Amount");
                            if "Due Date" >= EndDate then
                                CurrReport.Skip();

                            ClearCompanyPicture();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not IncludeAgingBand then
                                SetRange("Due Date", 0D, EndDate - 1);
                            SetRange("Currency Code", TempCurrency2.Code);
                            if (not PrintEntriesDue) and (not IncludeAgingBand) then
                                CurrReport.Break();
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                    begin
                        if Number = 1 then
                            TempCurrency2.FindSet();

                        repeat
                            if not IsFirstLoop then
                                IsFirstLoop := true
                            else
                                if TempCurrency2.Next() = 0 then
                                    CurrReport.Break();
                            CustLedgerEntry.SetRange("Customer No.", Customer."No.");
                            CustLedgerEntry.SetRange("Posting Date", 0D, EndDate);
                            CustLedgerEntry.SetRange("Currency Code", TempCurrency2.Code);
                            EntriesExists := not CustLedgerEntry.IsEmpty();
                        until EntriesExists;
                        Cust2 := Customer;
                        Cust2.SetRange("Date Filter", 0D, StartDate - 1);
                        Cust2.SetRange("Currency Filter", TempCurrency2.Code);
                        Cust2.CalcFields("Net Change");
                        StartBalance := Cust2."Net Change";
                        CustBalance := Cust2."Net Change";
                    end;

                    trigger OnPreDataItem()
                    begin
                        Customer.CopyFilter("Currency Filter", TempCurrency2.Code);
                    end;
                }
                dataitem(AgingBandLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(AgingDate1; Format(AgingDate[1] + 1))
                    {
                    }
                    column(AgingDate2; Format(AgingDate[2]))
                    {
                    }
                    column(AgingDate21; Format(AgingDate[2] + 1))
                    {
                    }
                    column(AgingDate3; Format(AgingDate[3]))
                    {
                    }
                    column(AgingDate31; Format(AgingDate[3] + 1))
                    {
                    }
                    column(AgingDate4; Format(AgingDate[4]))
                    {
                    }
                    column(AgingBandEndingDate; StrSubstNo(Text011Lbl, AgingBandEndingDate, PeriodLength, SelectStr(DateChoice + 1, Text013Txt)))
                    {
                    }
                    column(AgingDate41; Format(AgingDate[4] + 1))
                    {
                    }
                    column(AgingDate5; Format(AgingDate[5]))
                    {
                    }
                    column(AgingBandBufCol1Amt; TempAgingBandBuf."Column 1 Amt.")
                    {
                        AutoFormatExpression = TempAgingBandBuf."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AgingBandBufCol2Amt; TempAgingBandBuf."Column 2 Amt.")
                    {
                        AutoFormatExpression = TempAgingBandBuf."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AgingBandBufCol3Amt; TempAgingBandBuf."Column 3 Amt.")
                    {
                        AutoFormatExpression = TempAgingBandBuf."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AgingBandBufCol4Amt; TempAgingBandBuf."Column 4 Amt.")
                    {
                        AutoFormatExpression = TempAgingBandBuf."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AgingBandBufCol5Amt; TempAgingBandBuf."Column 5 Amt.")
                    {
                        AutoFormatExpression = TempAgingBandBuf."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(AgingBandCurrencyCode; AgingBandCurrencyCode)
                    {
                    }
                    column(beforeCaption; beforeCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            ClearCompanyPicture();
                            if not TempAgingBandBuf.Find('-') then
                                CurrReport.Break();
                        end else
                            if TempAgingBandBuf.Next() = 0 then
                                CurrReport.Break();
                        AgingBandCurrencyCode := TempAgingBandBuf."Currency Code";
                        if AgingBandCurrencyCode = '' then
                            AgingBandCurrencyCode := GLSetup."LCY Code";
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not IncludeAgingBand then
                            CurrReport.Break();
                    end;
                }
            }

            trigger OnAfterGetRecord()
            var
                CustLedgerEntry: Record "Cust. Ledger Entry";
            begin
                TempAgingBandBuf.DeleteAll();
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");
                PrintLine := false;
                if PrintAllHavingBal then
                    PrintLine := true;

                if (not PrintLine) and PrintAllHavingEntry then begin
                    CustLedgerEntry.SetRange("Customer No.", "No.");
                    CustLedgerEntry.SetRange("Posting Date", StartDate, EndDate);
                    CopyFilter("Currency Filter", CustLedgerEntry."Currency Code");
                    PrintLine := not CustLedgerEntry.IsEmpty();
                end;
                if not PrintLine then
                    CurrReport.Skip();

                FormatAddr.Customer(CustAddr, Customer);
                PrintedCustomersList.Add("No.");

                IsFirstLoop := false;
            end;

            trigger OnPreDataItem()
            var
                CustLedgerEntry: Record "Cust. Ledger Entry";
            begin
                VerifyDates();
                AgingBandEndingDate := EndDate;
                CalcAgingBandDates();

                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);

                CustLedgerEntry.Reset();
                CustLedgerEntry.SetCurrentKey("Currency Code");
                TempCurrency2.Init();
                while CustLedgerEntry.FindFirst() do begin
                    TempCurrency2.Code := CustLedgerEntry."Currency Code";
                    TempCurrency2.Insert();
                    CustLedgerEntry.SetFilter("Currency Code", '>%1', CustLedgerEntry."Currency Code");
                end;

                if PrintAllHavingBal and not PrintAllHavingEntry then begin
                    SetAutoCalcFields("Balance (LCY)");
                    SetFilter("Balance (LCY)", '<>0');
                end;
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
                    field("Start Date"; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field("End Date"; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(ShowOverdueEntries; PrintEntriesDue)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Overdue Entries';
                        ToolTip = 'Specifies if you want overdue entries to be shown separately for each currency.';
                    }
                    group(Include)
                    {
                        Caption = 'Include';
                        field(IncludeAllCustomerswithLE; PrintAllHavingEntry)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Include All Customers with Ledger Entries';
                            MultiLine = true;
                            ToolTip = 'Specifies if you want entries displayed for customers that have ledger entries at the end of the selected period.';

                            trigger OnValidate()
                            begin
                                if not PrintAllHavingEntry then
                                    PrintAllHavingBal := true;
                            end;
                        }
                        field(IncludeAllCustomerswithBalance; PrintAllHavingBal)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Include All Customers with a Balance';
                            MultiLine = true;
                            ToolTip = 'Specifies if you want entries displayed for customers that have a balance.';

                            trigger OnValidate()
                            begin
                                if not PrintAllHavingBal then
                                    PrintAllHavingEntry := true;
                            end;
                        }
                        field(IncludeReversedEntries; PrintReversedEntries)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Include Reversed Entries';
                            ToolTip = 'Specifies if you want to include reversed entries in the report.';
                        }
                        field(IncludeUnappliedEntries; PrintUnappliedEntries)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Include Unapplied Entries';
                            ToolTip = 'Specifies if you want to include unapplied entries in the report.';
                        }
                    }
                    group("Aging Band")
                    {
                        Caption = 'Aging Band';
                        field(IncludeAgingBand; IncludeAgingBand)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Include Aging Band';
                            ToolTip = 'Specifies if you want an aging band to be included in the document. If you place a check mark here, you must also fill in the Aging Band Period Length and Aging Band by fields.';
                        }
                        field(AgingBandPeriodLengt; PeriodLength)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Aging Band Period Length';
                            ToolTip = 'Specifies the length of each of the four periods in the aging band, for example, enter "1M" for one month. The most recent period will end on the last day of the period in the Date Filter field.';
                        }
                        field(AgingBandby; DateChoice)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Aging Band by';
                            OptionCaption = 'Due Date,Posting Date';
                            ToolTip = 'Specifies if the aging band will be calculated from the due date or from the posting date.';
                        }
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the related record to be recorded as an interaction and be added to the Interaction Log Entry table.';
                    }
                }
                group("Output Options")
                {
                    Caption = 'Output Options';
                    field(ReportOutput; SupportedOutputMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Output';
                        OptionCaption = 'Print,Preview,PDF,Email,Excel,XML';
                        ToolTip = 'Specifies the output of the scheduled report, such as PDF or Word.';

                        trigger OnValidate()
                        var
                            CustomLayoutReporting: Codeunit "Custom Layout Reporting";
                        begin
                            ShowPrintIfEmailIsMissing := (SupportedOutputMethod = SupportedOutputMethod::Email);

                            case SupportedOutputMethod of
                                SupportedOutputMethod::Print:
                                    ChosenOutputMethod := CustomLayoutReporting.GetPrintOption();
                                SupportedOutputMethod::Preview:
                                    ChosenOutputMethod := CustomLayoutReporting.GetPreviewOption();
                                SupportedOutputMethod::PDF:
                                    ChosenOutputMethod := CustomLayoutReporting.GetPDFOption();
                                SupportedOutputMethod::Email:
                                    ChosenOutputMethod := CustomLayoutReporting.GetEmailOption();
                                SupportedOutputMethod::Excel:
                                    ChosenOutputMethod := CustomLayoutReporting.GetExcelOption();
                                SupportedOutputMethod::XML:
                                    ChosenOutputMethod := CustomLayoutReporting.GetXMLOption();
                            end;
                        end;
                    }
                    field(ChosenOutput; ChosenOutputMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Chosen Output';
                        ToolTip = 'Specifies how to output the report, such as Print or Excel.';
                        Visible = false;
                    }
                    group(EmailOptions)
                    {
                        Caption = 'Email Options';
                        Visible = ShowPrintIfEmailIsMissing;
                        field(PrintMissingAddresses; PrintIfEmailIsMissing)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Print Although Email is Missing or Invalid';
                            ToolTip = 'Specifies if you want to print also the statements for customers that have not been set up with a send-to email address or defined send-to email address is invalid.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            InitRequestPageDataInternal();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
        SalesSetup.Get();

        case SalesSetup."Logo Position on Documents" of
            SalesSetup."Logo Position on Documents"::"No Logo":
                ;
            SalesSetup."Logo Position on Documents"::Left:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo3.Get();
                    CompanyInfo3.CalcFields(Picture);
                end;
        end;

        LogInteractionEnable := true;
    end;

    trigger OnPostReport()
    var
        CusNo: Code[20];
    begin
        if not IsReportInPreviewMode() then
            foreach CusNo in PrintedCustomersList do
                if Customer.Get(CusNo) then begin
                    Customer."Last Statement No." := Customer."Last Statement No." + 1;
                    Customer.Modify();
                    if LogInteraction then
                        SegManagement.LogDocument(
                          7, Format(Customer."Last Statement No."), 0, 0, DATABASE::Customer, Customer."No.", Customer."Salesperson Code", '',
                          Text003Txt + Format(Customer."Last Statement No."), '');
                end;
    end;

    trigger OnPreReport()
    begin
        InitRequestPageDataInternal();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        Cust2: Record Customer;
        TempCurrency2: Record Currency temporary;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TempAgingBandBuf: Record "Aging Band Buffer" temporary;
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        SegManagement: Codeunit SegManagement;
        PeriodLength: DateFormula;
        PeriodLength2: DateFormula;
        PrintedCustomersList: List of [Code[20]];
        PrintAllHavingEntry: Boolean;
        PrintAllHavingBal: Boolean;
        PrintEntriesDue: Boolean;
        PrintUnappliedEntries: Boolean;
        PrintReversedEntries: Boolean;
        PrintLine: Boolean;
        LogInteraction: Boolean;
        EntriesExists: Boolean;
        StartDate: Date;
        EndDate: Date;
        DueDate: Date;
        CustAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        Description: Text[100];
        StartBalance: Decimal;
        CustBalance: Decimal;
        RemainingAmount: Decimal;
        CurrencyCode3: Code[10];
        DateChoice: Option "Due Date","Posting Date";
        AgingDate: array[5] of Date;
        AgingBandEndingDate: Date;
        AgingBandCurrencyCode: Code[20];
        IncludeAgingBand: Boolean;
        LogInteractionEnable: Boolean;
        isInitialized: Boolean;
        IsFirstLoop: Boolean;
        IsFirstPrintLine: Boolean;
        IsNewCustCurrencyGroup: Boolean;
        SupportedOutputMethod: Option Print,Preview,PDF,Email,Excel,XML;
        ChosenOutputMethod: Integer;
        PrintIfEmailIsMissing: Boolean;
        ShowPrintIfEmailIsMissing: Boolean;
        FirstCustomerPrinted: Boolean;

        Text001Lbl: Label 'Entries %1', Comment = '%1 is the currency code';
        Text002Lbl: Label 'Overdue Entries %1', Comment = '%1 is the currency code';
        Text003Txt: Label 'Statement ';
        Text005Txt: Label 'Multicurrency Application';
        Text006Txt: Label 'Payment Discount';
        Text007Txt: Label 'Rounding';
        Text008Err: Label 'You must specify the Aging Band Period Length.';
        Text010Err: Label 'You must specify Aging Band Ending Date.';
        Text011Lbl: Label 'Aged Summary by %1 (%2 by %3)', Comment = '%1 is ending date, %2 is period length, %3 is Due Date or Posting Date';
        Text012Err: Label 'Period Length is out of range.';
        Text013Txt: Label 'Due Date,Posting Date';
        Text014Txt: Label 'Application Writeoffs';
        Text036Txt: Label '-%1', Comment = 'Negating the period length: %1 is the period length';
        StatementCaptionLbl: Label 'Statement';
        PhoneNo_CompanyInfoCaptionLbl: Label 'Phone No.';
        VATRegNo_CompanyInfoCaptionLbl: Label 'VAT Registration No.';
        GiroNo_CompanyInfoCaptionLbl: Label 'Giro No.';
        BankName_CompanyInfoCaptionLbl: Label 'Bank';
        BankAccNo_CompanyInfoCaptionLbl: Label 'Account No.';
        No1_CustCaptionLbl: Label 'Customer No.';
        StartDateCaptionLbl: Label 'Starting Date';
        EndDateCaptionLbl: Label 'Ending Date';
        LastStatmntNo_CustCaptionLbl: Label 'Statement No.';
        PostDate_DtldCustLedgEntriesCaptionLbl: Label 'Posting Date';
        DueDate_CustLedgEntry2CaptionLbl: Label 'Due Date';
        CustBalanceCaptionLbl: Label 'Running Total';
        beforeCaptionLbl: Label '..before';
        CompanyInfoHomepageCaptionLbl: Label 'Home Page';
        CompanyInfoEmailCaptionLbl: Label 'Email';
        DocDateCaptionLbl: Label 'Document Date';
        Total_CaptionLbl: Label 'Total';
        BlankStartDateErr: Label 'Start Date must have a value.';
        BlankEndDateErr: Label 'End Date must have a value.';
        StartDateLaterTheEndDateErr: Label 'Start date must be earlier than End date.';
        CurrReportPageNoCaptionLbl: Label 'Page';

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";

    local procedure GetDate(PostingDate: Date; DueDate: Date): Date
    begin
        if DateChoice = DateChoice::"Posting Date" then
            exit(PostingDate);

        exit(DueDate);
    end;

    local procedure CalcAgingBandDates()
    begin
        if not IncludeAgingBand then
            exit;
        if AgingBandEndingDate = 0D then
            Error(Text010Err);
        if Format(PeriodLength) = '' then
            Error(Text008Err);
        Evaluate(PeriodLength2, StrSubstNo(Text036Txt, PeriodLength));
        AgingDate[5] := AgingBandEndingDate;
        AgingDate[4] := CalcDate(PeriodLength2, AgingDate[5]);
        AgingDate[3] := CalcDate(PeriodLength2, AgingDate[4]);
        AgingDate[2] := CalcDate(PeriodLength2, AgingDate[3]);
        AgingDate[1] := CalcDate(PeriodLength2, AgingDate[2]);
        if AgingDate[2] <= AgingDate[1] then
            Error(Text012Err);
    end;

    local procedure UpdateBuffer(CurrencyCode: Code[10]; Date: Date; Amount: Decimal)
    var
        I: Integer;
        GoOn: Boolean;
    begin
        TempAgingBandBuf.Init();
        TempAgingBandBuf."Currency Code" := CurrencyCode;
        if not TempAgingBandBuf.Find() then
            TempAgingBandBuf.Insert();
        I := 1;
        GoOn := true;
        while (I <= 5) and GoOn do begin
            if Date <= AgingDate[I] then
                if I = 1 then begin
                    TempAgingBandBuf."Column 1 Amt." := TempAgingBandBuf."Column 1 Amt." + Amount;
                    GoOn := false;
                end;
            if Date <= AgingDate[I] then
                if I = 2 then begin
                    TempAgingBandBuf."Column 2 Amt." := TempAgingBandBuf."Column 2 Amt." + Amount;
                    GoOn := false;
                end;
            if Date <= AgingDate[I] then
                if I = 3 then begin
                    TempAgingBandBuf."Column 3 Amt." := TempAgingBandBuf."Column 3 Amt." + Amount;
                    GoOn := false;
                end;
            if Date <= AgingDate[I] then
                if I = 4 then begin
                    TempAgingBandBuf."Column 4 Amt." := TempAgingBandBuf."Column 4 Amt." + Amount;
                    GoOn := false;
                end;
            if Date <= AgingDate[I] then
                if I = 5 then begin
                    TempAgingBandBuf."Column 5 Amt." := TempAgingBandBuf."Column 5 Amt." + Amount;
                    GoOn := false;
                end;
            I := I + 1;
        end;
        TempAgingBandBuf.Modify();
    end;

    procedure SkipReversedUnapplied(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"): Boolean
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if PrintReversedEntries and PrintUnappliedEntries then
            exit(false);
        if not PrintUnappliedEntries then
            if DetailedCustLedgEntry.Unapplied then
                exit(true);
        if not PrintReversedEntries then begin
            CustLedgEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");
            if CustLedgEntry.Reversed then
                exit(true);
        end;
        exit(false);
    end;

    procedure InitializeRequest(NewPrintEntriesDue: Boolean; NewPrintAllHavingEntry: Boolean; NewPrintAllHavingBal: Boolean; NewPrintReversedEntries: Boolean; NewPrintUnappliedEntries: Boolean; NewIncludeAgingBand: Boolean; NewPeriodLength: Text[30]; NewDateChoice: Option; NewLogInteraction: Boolean; NewStartDate: Date; NewEndDate: Date)
    begin
        InitRequestPageDataInternal();

        PrintEntriesDue := NewPrintEntriesDue;
        PrintAllHavingEntry := NewPrintAllHavingEntry;
        PrintAllHavingBal := NewPrintAllHavingBal;
        PrintReversedEntries := NewPrintReversedEntries;
        PrintUnappliedEntries := NewPrintUnappliedEntries;
        IncludeAgingBand := NewIncludeAgingBand;
        Evaluate(PeriodLength, NewPeriodLength);
        DateChoice := NewDateChoice;
        LogInteraction := NewLogInteraction;
        StartDate := NewStartDate;
        EndDate := NewEndDate;
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    procedure InitRequestPageDataInternal()
    begin
        if isInitialized then
            exit;

        isInitialized := true;

        if (not PrintAllHavingEntry) and (not PrintAllHavingBal) then
            PrintAllHavingBal := true;

        LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Sales Stmnt.") <> '';
        LogInteractionEnable := LogInteraction;

        if Format(PeriodLength) = '' then
            Evaluate(PeriodLength, '<1M+CM>');

        PrintIfEmailIsMissing := SupportedOutputMethod = SupportedOutputMethod::Email;
    end;

    local procedure VerifyDates()
    begin
        if StartDate = 0D then
            Error(BlankStartDateErr);
        if EndDate = 0D then
            Error(BlankEndDateErr);
        if StartDate > EndDate then
            Error(StartDateLaterTheEndDateErr);
    end;

    local procedure ClearCompanyPicture()
    begin
        if FirstCustomerPrinted then begin
            Clear(CompanyInfo.Picture);
            Clear(CompanyInfo1.Picture);
            Clear(CompanyInfo2.Picture);
            Clear(CompanyInfo3.Picture);
        end;
        FirstCustomerPrinted := true;
    end;
}

