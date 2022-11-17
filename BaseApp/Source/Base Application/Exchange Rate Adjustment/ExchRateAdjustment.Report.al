report 596 "Exch. Rate Adjustment"
{
    Caption = 'Exchange Rates Adjustment';
    ProcessingOnly = true;

    dataset
    {
        dataitem(CurrencyFilter; Currency)
        {
            DataItemTableView = SORTING(Code);
            RequestFilterFields = "Code";
            dataitem(BankAccountFilter; "Bank Account")
            {
                DataItemLink = "Currency Code" = FIELD(Code);
                RequestFilterFields = "No.";
            }
        }
        dataitem(CustomerFilter; Customer)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
        }
        dataitem(VendorFilter; Vendor)
        {
            DataItemTableView = SORTING("No.");
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
                    field(JournalTemplateName; GenJnlLineReq."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnValidate()
                        begin
                            GenJnlLineReq."Journal Batch Name" := '';
                        end;
                    }
                    field(JournalBatchName; GenJnlLineReq."Journal Batch Name")
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
                            GenJnlManagement.SetJnlBatchName(GenJnlLineReq);
                            if GenJnlLineReq."Journal Batch Name" <> '' then
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLineReq."Journal Batch Name" <> '' then begin
                                GenJnlLineReq.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
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
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            OnBeforeOpenPage(AdjCust, AdjVend, AdjBank, AdjGLAcc, PostingDocNo);

            if PostingDescription = '' then
                PostingDescription := AdjustmentDescriptionTxt;

            if not (AdjCust or AdjVend or AdjBank or AdjGLAcc) then begin
                AdjCust := true;
                AdjVend := true;
                AdjBank := true;
            end;

            PreviewPosting := true;

            GLSetup.Get();
            IsJournalTemplNameVisible := GLSetup."Journal Templ. Name Mandatory";
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInitReport(IsHandled);
        if IsHandled then
            exit;
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get();

        if EndDateReq = 0D then
            EndDate := DMY2Date(31, 12, 9999)
        else
            EndDate := EndDateReq;

        GLSetup.Get();
        if GLSetup."Journal Templ. Name Mandatory" then begin
            if GenJnlLineReq."Journal Template Name" = '' then
                Error(MustBeEnteredErr, GenJnlLineReq.FieldCaption("Journal Template Name"));
            if GenJnlLineReq."Journal Batch Name" = '' then
                Error(MustBeEnteredErr, GenJnlLineReq.FieldCaption("Journal Batch Name"));
            Clear(NoSeriesMgt);
            Clear(PostingDocNo);
            GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
            GenJnlBatch.TestField("No. Series");
            PostingDocNo := NoSeriesMgt.GetNextNo(GenJnlBatch."No. Series", PostingDate, true);
        end else
            if (PostingDocNo = '') and (not PreviewPosting) then
                Error(MustBeEnteredErr, GenJnlLineReq.FieldCaption("Document No."));

        if PreviewPosting then
            PostingDocNo := '***';

        if (not AdjCust) and (not AdjVend) and (not AdjBank) and AdjGLAcc then
            if not Confirm(ConfirmationTxt + ContinueTxt, false) then
                Error(AdjustmentCancelledErr);

        if (not AdjCust) and (not AdjVend) and (not AdjBank) then
            exit;

        RunAdjustmentProcess();
    end;

    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLineReq: Record "Gen. Journal Line";
        GLSetup: Record "General Ledger Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        PostingDate: Date;
        PostingDescription: Text[100];
        PostingDocNo: Code[20];
        StartDate: Date;
        EndDate: Date;
        EndDateReq: Date;
        AdjCust: Boolean;
        AdjVend: Boolean;
        AdjBank: Boolean;
        AdjGLAcc: Boolean;
        AdjPerEntry: Boolean;
        PreviewPosting: Boolean;
        HideUI: Boolean;
        IsJournalTemplNameVisible: Boolean;
        MustBeEnteredErr: Label '%1 must be entered.', Comment = '%1 = field name';
        ConfirmationTxt: Label 'Do you want to adjust general ledger entries for currency fluctuations without adjusting customer, vendor and bank ledger entries? This may result in incorrect currency adjustments to payables, receivables and bank accounts.\\ ';
        ContinueTxt: Label 'Do you wish to continue?';
        AdjustmentCancelledErr: Label 'The adjustment of exchange rates has been canceled.';
        AdjustmentDescriptionTxt: Label 'Adjmt. of %1 %2, Ex.Rate Adjust.', Comment = '%1 = Currency Code, %2= Adjust Amount';
        FilterIsTooComplexErr: Label '%1 filter is too complex', Comment = '%1 - table caption';
        PostingDateNotInPeriodErr: Label 'This posting date cannot be entered because it does not occur within the adjustment period. Reenter the posting date.';

    local procedure RunAdjustmentProcess()
    var
        ExchRateAdjmtParameters: Record "Exch. Rate Adjmt. Parameters";
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

    procedure InitializeRequest2(NewStartDate: Date; NewEndDate: Date; NewPostingDescription: Text[100]; NewPostingDate: Date; NewPostingDocNo: Code[20]; NewAdjCustVendBank: Boolean; NewAdjGLAcc: Boolean)
    begin
        InitializeRequest(NewStartDate, NewEndDate, NewPostingDescription, NewPostingDate);
        PostingDocNo := NewPostingDocNo;
        AdjBank := NewAdjCustVendBank;
        AdjCust := NewAdjCustVendBank;
        AdjVend := NewAdjCustVendBank;
        AdjGLAcc := NewAdjGLAcc;
        PreviewPosting := false;
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
        ExchRateAdjmtParameters2."Adjust G/L Accounts" := AdjGLAcc;
        ExchRateAdjmtParameters2."Hide UI" := HideUI;
        ExchRateAdjmtParameters2."Preview Posting" := PreviewPosting;
        if GLSetup."Journal Templ. Name Mandatory" then begin
            ExchRateAdjmtParameters2."Journal Template Name" := GenJnlBatch."Journal Template Name";
            ExchRateAdjmtParameters2."Journal Batch Name" := GenJnlBatch.Name;
        end;
        OnAfterCopyParameters(ExchRateAdjmtParameters2);
    end;

    procedure SetGenJnlBatch(NewGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch := NewGenJnlBatch;
    end;

    procedure SetPreviewMode(NewPreviewPosting: Boolean)
    begin
        PreviewPosting := NewPreviewPosting;
    end;

    procedure SetHideUI(NewHideUI: Boolean)
    begin
        HideUI := NewHideUI;
    end;

    procedure CheckPostingDate()
    begin
        if PostingDate < StartDate then
            Error(PostingDateNotInPeriodErr);
        if PostingDate > EndDateReq then
            Error(PostingDateNotInPeriodErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyParameters(var ExchRateAdjmtParameters2: Record "Exch. Rate Adjmt. Parameters" temporary)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeOnInitReport(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPage(var AdjCust: Boolean; var AdjVend: Boolean; AdjBank: Boolean; var AdjGLAcc: Boolean; var PostingDocNo: Code[20])
    begin
    end;
}

