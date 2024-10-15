// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
#if not CLEAN23
using System.Environment;
using System.Environment.Configuration;
#endif

report 596 "Exch. Rate Adjustment"
{
#if CLEAN23
    ApplicationArea = Basic, Suite;    
#endif
    Caption = 'Exchange Rates Adjustment';
    ProcessingOnly = true;
#if CLEAN23
    UsageCategory = Tasks;
#endif

    dataset
    {
        dataitem(CurrencyFilter; Currency)
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";
            dataitem(BankAccountFilter; "Bank Account")
            {
                DataItemLink = "Currency Code" = field(Code);
                RequestFilterFields = "No.";
            }
        }
        dataitem(CustomerFilter; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
        }
        dataitem(VendorFilter; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
        }
        dataitem(EmployeeFilter; Employee)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
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
                    group("Adjustment Period")
                    {
                        Caption = 'Adjustment Period';
                        field(StartingDate; StartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                        }
                        field(EndingDate; EndDateReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the last date for which entries are adjusted. This date is usually the same as the posting date in the Posting Date field.';

                            trigger OnValidate()
                            begin
                                PostingDate := EndDateReq;
                                UpdateControls();
                            end;
                        }
                    }
                    group("Valuation Method")
                    {
                        Caption = 'Valuation Method';
                        field(Method; ValuationMethod)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Method';
                            OptionCaption = 'Standard,Lowest Value,BilMoG (Germany)';
                            ToolTip = 'Specifies the valuation method that is used for short-term entries.';

                            trigger OnValidate()
                            begin
                                UpdateControls();
                            end;
                        }
                        field(ValPerEnd; ValuationPeriodEndDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Valuation Reference Date';
                            Enabled = ValPerEndEnable;
                            ToolTip = 'Specifies the base date that is used to calculate which entries are short-term entries.';

                            trigger OnValidate()
                            begin
                                UpdateControls();
                            end;
                        }
                        field(DueDateLimit; DueDateTo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Short-term Liabilities Due Date';
                            Enabled = DueDateLimitEnable;
                            ToolTip = 'Specifies the date that is used to separate short-term entries from long-term entries.';

                            trigger OnValidate()
                            begin
                                if DueDateTo < ValuationPeriodEndDate then
                                    Error(ValuationReferenceDateErr);
                            end;
                        }
                    }
                    field(PostingDescriptionReq; PostingDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies text for the general ledger entries that are created by the batch job. The default text is Exchange Rate Adjmt. of %1 %2, in which %1 is replaced by the currency code and %2 is replaced by the currency amount that is adjusted. For example, Exchange Rate Adjmt. of DEM 38,000.';
                    }
                    field(PostingDateReq; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date on which the general ledger entries are posted. This date is usually the same as the ending date in the Ending Date field.';

                        trigger OnValidate()
                        begin
                            CheckPostingDate();
                        end;
                    }
                    field(DocumentNo; PostingDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the document number that will appear on the general ledger entries that are created by the batch job.';
                        Visible = not IsJournalTemplNameVisible;
                    }
                    field(JournalTemplateName; GenJournalLineReq."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnValidate()
                        begin
                            GenJournalLineReq."Journal Batch Name" := '';
                        end;
                    }
                    field(JournalBatchName; GenJournalLineReq."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;
                        ToolTip = 'Specifies the name of the journal batch that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GenJnlManagement: Codeunit GenJnlManagement;
                        begin
                            GenJnlManagement.SetJnlBatchName(GenJournalLineReq);
                            if GenJournalLineReq."Journal Batch Name" <> '' then
                                GenJournalBatch.Get(GenJournalLineReq."Journal Template Name", GenJournalLineReq."Journal Batch Name");
                        end;

                        trigger OnValidate()
                        begin
                            if GenJournalLineReq."Journal Batch Name" <> '' then begin
                                GenJournalLineReq.TestField("Journal Template Name");
                                GenJournalBatch.Get(GenJournalLineReq."Journal Template Name", GenJournalLineReq."Journal Batch Name");
                            end;
                        end;
                    }
                    field(AdjCustAcc; AdjCust)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Customers';
                        ToolTip = 'Specifies if you want to adjust customers for currency fluctuations.';
                    }
                    field(AdjVendAcc; AdjVend)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Vendors';
                        ToolTip = 'Specifies if you want to adjust vendors for currency fluctuations.';
                    }
                    field(AdjEmplAcc; AdjEmpl)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Employees';
                        ToolTip = 'Specifies if you want to adjust employees for currency fluctuations.';
                    }
                    field(AdjBankAcc; AdjBank)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Bank Accounts';
                        ToolTip = 'Specifies if you want to adjust bank accounts for currency fluctuations.';
                    }
                    field(AdjGLAccount; AdjGLAcc)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Adjust G/L Accounts for Add.-Reporting Currency';
                        ToolTip = 'Specifies if you want to post in an additional reporting currency and adjust general ledger accounts for currency fluctuations between LCY and the additional reporting currency.';
                    }
                    field(AdjVAT; AdjVATEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust VAT';
                        ToolTip = 'Specifies if you want to adjust the VAT exchange rate.';
                    }
                    field(AdjustPerEntry; AdjPerEntry)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Adjust per entry';
                        Tooltip = 'Specifies if adjustment should be posted per each customer or vendor ledger entry with currency fluctuations.';

                    }
                    field(PreviewPost; PreviewPosting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preview Posting';
                        ToolTip = 'Specifies if you want to preview posting for currency fluctuations.';
                    }
                    field(DimensionPost; DimensionPosting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimension Posting';
                        ToolTip = 'Specifies how you want to move dimensions to posted ledger entries.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            ValPerEndEnable := true;
            DueDateLimitEnable := true;
        end;

        trigger OnOpenPage()
        begin
            OnBeforeOpenPage(AdjCust, AdjVend, AdjEmpl, AdjBank, AdjGLAcc, PostingDocNo);

            if PostingDescription = '' then
                PostingDescription := AdjustmentDescriptionTxt;

            if not (AdjCust or AdjVend or AdjEmpl or AdjBank or AdjGLAcc) then begin
                AdjCust := true;
                AdjVend := true;
                AdjEmpl := true;
                AdjBank := true;
            end;

            PreviewPosting := true;

            GeneralLedgerSetup.Get();
            IsJournalTemplNameVisible := GeneralLedgerSetup."Journal Templ. Name Mandatory";

            UpdateControls();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
#if not CLEAN23
        FeatureKey: Record "Feature Key";
        EnvironmentInformation: Codeunit "Environment Information";
        FeatureKeyManagement: Codeunit "Feature Key Management";
        FeatureErrorInfo: ErrorInfo;
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInitReport(IsHandled);
        if IsHandled then
            exit;
#if not CLEAN23
        if not EnvironmentInformation.IsOnPrem() then
            if not FeatureKeyManagement.IsExtensibleExchangeRateAdjustmentEnabled() then begin
                FeatureKey.Get(FeatureKeyManagement.GetExtensibleExchangeRateAdjustmentFeatureKey());
                FeatureErrorInfo.Title := FeatureDisabledTitleTxt;
                FeatureErrorInfo.Message := StrSubstno(FeatureDisabledErrorTxt, FeatureKey.Description);
                FeatureErrorInfo.AddAction(ShowFeatureManagementTxt, Codeunit::"Exch. Rate Adjmt. Run Handler", 'ShowFeatureManagement');
                Error(FeatureErrorInfo);
            end;
#endif
    end;

    trigger OnPreReport()
    var
        NoSeries: Codeunit "No. Series";
    begin
        GeneralLedgerSetup.Get();

        if EndDateReq = 0D then
            EndDate := DMY2Date(31, 12, 9999)
        else
            EndDate := EndDateReq;

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then begin
            if GenJournalLineReq."Journal Template Name" = '' then
                Error(MustBeEnteredErr, GenJournalLineReq.FieldCaption("Journal Template Name"));
            if GenJournalLineReq."Journal Batch Name" = '' then
                Error(MustBeEnteredErr, GenJournalLineReq.FieldCaption("Journal Batch Name"));
            Clear(PostingDocNo);
            GenJournalBatch.Get(GenJournalLineReq."Journal Template Name", GenJournalLineReq."Journal Batch Name");
            GenJournalBatch.TestField("No. Series");
            if not PreviewPosting then
                PostingDocNo := NoSeries.GetNextNo(GenJournalBatch."No. Series", PostingDate);
        end else
            if (PostingDocNo = '') and (not PreviewPosting) then
                Error(MustBeEnteredErr, GenJournalLineReq.FieldCaption("Document No."));

        if PreviewPosting then
            PostingDocNo := '***';

        if (not AdjCust) and (not AdjVend) and (not AdjBank) and (not AdjEmpl) and AdjGLAcc then
            if not Confirm(ConfirmationTxt + ContinueTxt, false) then
                Error(AdjustmentCancelledErr);

        if (not AdjCust) and (not AdjVend) and (not AdjBank) and (not AdjEmpl) and (not AdjGLAcc) then
            exit;

        if AdjVATEntries then
            if not Confirm(AdjustVATExchRatesQst + ContinueTxt) then
                Error(AdjustmentCancelledErr);

        RunAdjustmentProcess();
    end;

    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineReq: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionPosting: Enum "Exch. Rate Adjmt. Dimensions";
        PostingDate: Date;
        PostingDescription: Text[100];
        PostingDocNo: Code[20];
        StartDate: Date;
        EndDate: Date;
        EndDateReq: Date;
        AdjCust: Boolean;
        AdjVend: Boolean;
        AdjEmpl: Boolean;
        AdjBank: Boolean;
        AdjGLAcc: Boolean;
        AdjPerEntry: Boolean;
        AdjVATEntries: Boolean;
        PreviewPosting: Boolean;
        HideUI: Boolean;
        IsJournalTemplNameVisible: Boolean;
        ValuationMethod: Option Standard,"Lowest Value","BilMoG (Germany)";
        DueDateTo: Date;
        ValuationPeriodEndDate: Date;
        DueDateLimitEnable: Boolean;
        ValPerEndEnable: Boolean;
        MustBeEnteredErr: Label '%1 must be entered.', Comment = '%1 = field name';
        ConfirmationTxt: Label 'Do you want to adjust general ledger entries for currency fluctuations without adjusting customer, vendor and bank ledger entries? This may result in incorrect currency adjustments to payables, receivables and bank accounts.\\ ';
        ContinueTxt: Label 'Do you wish to continue?';
        AdjustmentCancelledErr: Label 'The adjustment of exchange rates has been canceled.';
        AdjustmentDescriptionTxt: Label 'Adjmt. of %1 %2, Ex.Rate Adjust.', Comment = '%1 = Currency Code, %2= Adjust Amount';
        FilterIsTooComplexErr: Label '%1 filter is too complex', Comment = '%1 - table caption';
        PostingDateNotInPeriodErr: Label 'This posting date cannot be entered because it does not occur within the adjustment period. Reenter the posting date.';
        ValuationReferenceDateErr: Label 'Short term liabilities until must not be before Valuation Reference Date.';
        AdjustVATExchRatesQst: Label 'You want to adjust the VAT exchange rate. Please check whether the VAT exchange rates are correct. They cannot be corrected anymore.\\ ';
#if not CLEAN23
        FeatureDisabledErrorTxt: Label 'You should enable feature %1 to run Exchange Rates Adjustment report in Feature Management page.', Comment = '%1 - feature name';
        FeatureDisabledTitleTxt: Label 'You cannot run Exchange Rates Adjustment report.';
        ShowFeatureManagementTxt: Label 'Show Feature Management';
#endif

    protected var
        ExchRateAdjmtParameters: Record "Exch. Rate Adjmt. Parameters";

    local procedure RunAdjustmentProcess()
    var
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
    begin
        Clear(ExchRateAdjmtProcess);
        CopyParameters(ExchRateAdjmtParameters);
        if StrLen(CurrencyFilter.GetView()) > MaxStrLen(ExchRateAdjmtParameters."Currency Filter") then
            Error(FilterIsTooComplexErr, CurrencyFilter.TableCaption());
        ExchRateAdjmtParameters."Currency Filter" :=
            CopyStr(CurrencyFilter.GetView(), 1, MaxStrLen(ExchRateAdjmtParameters."Currency Filter"));
        if StrLen(BankAccountFilter.GetView()) > MaxStrLen(ExchRateAdjmtParameters."Bank Account Filter") then
            Error(FilterIsTooComplexErr, BankAccountFilter.TableCaption());
        ExchRateAdjmtParameters."Bank Account Filter" :=
            CopyStr(BankAccountFilter.GetView(), 1, MaxStrLen(ExchRateAdjmtParameters."Bank Account Filter"));
        if StrLen(CustomerFilter.GetView()) > MaxStrLen(ExchRateAdjmtParameters."Customer Filter") then
            Error(FilterIsTooComplexErr, CustomerFilter.TableCaption());
        ExchRateAdjmtParameters."Customer Filter" :=
            CopyStr(CustomerFilter.GetView(), 1, MaxStrLen(ExchRateAdjmtParameters."Customer Filter"));
        if StrLen(VendorFilter.GetView()) > MaxStrLen(ExchRateAdjmtParameters."Vendor Filter") then
            Error(FilterIsTooComplexErr, VendorFilter.TableCaption());
        ExchRateAdjmtParameters."Vendor Filter" :=
            CopyStr(VendorFilter.GetView(), 1, MaxStrLen(ExchRateAdjmtParameters."Vendor Filter"));
        ExchRateAdjmtParameters."Employee Filter" :=
            CopyStr(EmployeeFilter.GetView(), 1, MaxStrLen(ExchRateAdjmtParameters."Employee Filter"));

        if PreviewPosting then
            ExchRateAdjmtProcess.Preview(ExchRateAdjmtParameters)
        else
            ExchRateAdjmtProcess.Run(ExchRateAdjmtParameters);
    end;

    procedure InitializeRequest(NewStartDate: Date; NewEndDate: Date; NewPostingDescription: Text[100]; NewPostingDate: Date)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        PostingDescription := NewPostingDescription;
        PostingDate := NewPostingDate;
        if EndDate = 0D then
            EndDateReq := DMY2Date(31, 12, 9999)
        else
            EndDateReq := EndDate;
    end;

    procedure InitializeRequest2(NewStartDate: Date; NewEndDate: Date; NewPostingDescription: Text[100]; NewPostingDate: Date; NewPostingDocNo: Code[20]; NewAdjCustVendEmplBank: Boolean; NewAdjGLAcc: Boolean)
    begin
        InitializeRequest(NewStartDate, NewEndDate, NewPostingDescription, NewPostingDate);
        PostingDocNo := NewPostingDocNo;
        AdjBank := NewAdjCustVendEmplBank;
        AdjCust := NewAdjCustVendEmplBank;
        AdjVend := NewAdjCustVendEmplBank;
        AdjEmpl := NewAdjCustVendEmplBank;
        AdjGLAcc := NewAdjGLAcc;
        PreviewPosting := false;
    end;

    procedure SetValuationMethod(NewValuationMethod: Integer; NewDueDateTo: Date; NewValuationPeriodEndDate: Date)
    begin
        ValuationMethod := NewValuationMethod;
        DueDateTo := NewDueDateTo;
        ValuationPeriodEndDate := NewValuationPeriodEndDate;
        UpdateControls();
    end;

    local procedure CopyParameters(var ExchRateAdjmtParameters2: Record "Exch. Rate Adjmt. Parameters" temporary)
    begin
        ExchRateAdjmtParameters2."Start Date" := StartDate;
        ExchRateAdjmtParameters2."End Date" := EndDate;
        ExchRateAdjmtParameters2."Posting Date" := PostingDate;
        ExchRateAdjmtParameters2."Posting Description" := PostingDescription;
        ExchRateAdjmtParameters2."Document No." := PostingDocNo;
        ExchRateAdjmtParameters2."Adjust Bank Accounts" := AdjBank;
        ExchRateAdjmtParameters2."Adjust Customers" := AdjCust;
        ExchRateAdjmtParameters2."Adjust Vendors" := AdjVend;
        ExchRateAdjmtParameters2."Adjust Employees" := AdjEmpl;
        ExchRateAdjmtParameters2."Adjust G/L Accounts" := AdjGLAcc;
        ExchRateAdjmtParameters2."Adjust VAT Entries" := AdjVATEntries;
        ExchRateAdjmtParameters2."Adjust Per Entry" := AdjPerEntry;
        ExchRateAdjmtParameters2."Hide UI" := HideUI;
        ExchRateAdjmtParameters2."Preview Posting" := PreviewPosting;
        ExchRateAdjmtParameters2."Dimension Posting" := DimensionPosting;
        ExchRateAdjmtParameters2."Valuation Method" := ValuationMethod;
        ExchRateAdjmtParameters2."Valuation Period End Date" := ValuationPeriodEndDate;
        ExchRateAdjmtParameters2."Due Date To" := DueDateTo;
        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then begin
            ExchRateAdjmtParameters2."Journal Template Name" := GenJournalBatch."Journal Template Name";
            ExchRateAdjmtParameters2."Journal Batch Name" := GenJournalBatch.Name;
        end;
        OnAfterCopyParameters(ExchRateAdjmtParameters2);
    end;

    procedure SetGenJnlBatch(NewGenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalBatch := NewGenJournalBatch;
    end;

    procedure SetPreviewMode(NewPreviewPosting: Boolean)
    begin
        PreviewPosting := NewPreviewPosting;
    end;

    procedure SetHideUI(NewHideUI: Boolean)
    begin
        HideUI := NewHideUI;
    end;

    procedure SetAdjustVATEntries(NewAdjVATEntries: Boolean)
    begin
        AdjVATEntries := NewAdjVATEntries;
    end;

    procedure CheckPostingDate()
    begin
        if PostingDate < StartDate then
            Error(PostingDateNotInPeriodErr);
        if PostingDate > EndDateReq then
            Error(PostingDateNotInPeriodErr);
    end;

    local procedure UpdateControls()
    begin
        if ValuationMethod = ValuationMethod::"BilMoG (Germany)" then begin
            DueDateLimitEnable := true;
            ValPerEndEnable := true;
            if ValuationPeriodEndDate = 0D then
                if EndDateReq <> 0D then
                    ValuationPeriodEndDate := CalcDate('<+CM>', EndDateReq);
            if ValuationPeriodEndDate <> 0D then
                DueDateTo := CalcDate('<+1Y>', ValuationPeriodEndDate);
        end else begin
            DueDateLimitEnable := false;
            ValPerEndEnable := false;
            ValuationPeriodEndDate := 0D;
            DueDateTo := 0D;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyParameters(var ExchRateAdjmtParameters2: Record "Exch. Rate Adjmt. Parameters" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnInitReport(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPage(var AdjCust: Boolean; var AdjVend: Boolean; var AdjEmpl: Boolean; AdjBank: Boolean; var AdjGLAcc: Boolean; var PostingDocNo: Code[20])
    begin
    end;
}

