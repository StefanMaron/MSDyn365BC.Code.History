namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;

report 1700 "Deferral Summary - G/L"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Deferral/DeferralSummaryGL.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Deferral Summary';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Posted Deferral Header"; "Posted Deferral Header")
        {
            DataItemTableView = sorting("Deferral Doc. Type", "Account No.", "Posting Date", "Gen. Jnl. Document No.", "Document Type", "Document No.", "Line No.") order(ascending) where("Deferral Doc. Type" = const("G/L"));
            RequestFilterFields = "Account No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(PostedDeferralTableCaption; TableCaption + ': ' + PostedDeferralFilter)
            {
            }
            column(PostedDeferralFilter; PostedDeferralFilter)
            {
            }
            column(EmptyString; '')
            {
            }
            column(No_GLAcc; "Account No.")
            {
            }
            column(DeferralSummaryGLCaption; DeferralSummaryGLCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(GLBalCaption; GLBalCaptionLbl)
            {
            }
            column(RemAmtDefCaption; RemAmtDefCaptionLbl)
            {
            }
            column(TotAmtDefCaption; TotAmtDefCaptionLbl)
            {
            }
            column(BalanceAsOfDateCaption; BalanceAsOfDateCaptionLbl + Format(BalanceAsOfDateFilter))
            {
            }
            column(BalanceAsOfDateFilter; BalanceAsOfDateFilter)
            {
            }
            column(AccountNoCaption; AccountNoLbl)
            {
            }
            column(AmtRecognizedCaption; AmtRecognizedLbl)
            {
            }
            column(AccountName; AccountName)
            {
            }
            column(NumOfPeriods; "No. of Periods")
            {
            }
            column(DocumentType; "Document Type")
            {
            }
            column(DeferralStartDate; Format("Start Date"))
            {
            }
            column(AmtRecognized; AmtRecognized)
            {
            }
            column(RemainingAmtDeferred; RemainingAmtDeferred)
            {
            }
            column(TotalAmtDeferred; "Amount to Defer (LCY)")
            {
            }
            column(PostingDate; Format(PostingDate))
            {
            }
            column(DeferralAccount; DeferralAccount)
            {
            }
            column(Amount; "Amount to Defer (LCY)")
            {
            }
            column(GenJnlDocNo; "Gen. Jnl. Document No.")
            {
            }
            column(GLDocType; GLDocType)
            {
            }

            trigger OnAfterGetRecord()
            var
                GLEntry: Record "G/L Entry";
            begin
                PreviousAccount := WorkingAccount;
                if GLAccount.Get("Account No.") then begin
                    AccountName := GLAccount.Name;
                    WorkingAccount := GLAccount."No.";
                end;

                AmtRecognized := 0;
                RemainingAmtDeferred := 0;

                PostedDeferralLine.SetRange("Deferral Doc. Type", "Deferral Doc. Type");
                PostedDeferralLine.SetRange("Gen. Jnl. Document No.", "Gen. Jnl. Document No.");
                PostedDeferralLine.SetRange("Account No.", "Account No.");
                PostedDeferralLine.SetRange("Document Type", "Document Type");
                PostedDeferralLine.SetRange("Document No.", "Document No.");
                PostedDeferralLine.SetRange("Line No.", "Line No.");
                if PostedDeferralLine.Find('-') then
                    repeat
                        DeferralAccount := PostedDeferralLine."Deferral Account";
                        if PostedDeferralLine."Posting Date" <= BalanceAsOfDateFilter then
                            AmtRecognized := AmtRecognized + PostedDeferralLine."Amount (LCY)"
                        else
                            RemainingAmtDeferred := RemainingAmtDeferred + PostedDeferralLine."Amount (LCY)";
                    until (PostedDeferralLine.Next() = 0);

                if GLEntry.Get("Entry No.") then begin
                    GLDocType := GLEntry."Document Type";
                    PostingDate := GLEntry."Posting Date";
                end;

                if PrintOnlyOnePerPage and (PreviousAccount <> WorkingAccount) then begin
                    PostedDeferralHeaderPage.Reset();
                    PostedDeferralHeaderPage.SetRange("Account No.", "Account No.");
                    if PostedDeferralHeaderPage.FindFirst() then
                        PageGroupNo := PageGroupNo + 1;
                end;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
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
                    field(NewPageperGLAcc; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per G/L Acc.';
                        ToolTip = 'Specifies if each G/L account information is printed on a new page if you have chosen two or more G/L accounts to be included in the report.';
                    }
                    field(BalanceAsOfDateFilter; BalanceAsOfDateFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Balance as of:';
                        ToolTip = 'Specifies the end date that the balance is calculated on.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if BalanceAsOfDateFilter = 0D then
                BalanceAsOfDateFilter := WorkDate();
        end;
    }

    labels
    {
        PostingDateCaption = 'Posting Date';
        DocNoCaption = 'Document No.';
        DescCaption = 'Description';
        EntryNoCaption = 'Entry No.';
        NoOfPeriodsCaption = 'No. of Periods';
        DeferralAccountCaption = 'Deferral Account';
        DocTypeCaption = 'Document Type';
        DefStartDateCaption = 'Deferral Start Date';
        AcctNameCaption = 'Account Name';
    }

    trigger OnPreReport()
    begin
        PostedDeferralFilter := "Posted Deferral Header".GetFilters();
    end;

    var
        PostedDeferralHeaderPage: Record "Posted Deferral Header";
        GLAccount: Record "G/L Account";
        PostedDeferralLine: Record "Posted Deferral Line";
        GLDocType: Enum "Gen. Journal Document Type";
        PostedDeferralFilter: Text;
        PrintOnlyOnePerPage: Boolean;
        PageGroupNo: Integer;
        PageCaptionLbl: Label 'Page';
        BalanceCaptionLbl: Label 'This also includes general ledger accounts that only have a balance.';
        PeriodCaptionLbl: Label 'This report also includes closing entries within the period.';
        GLBalCaptionLbl: Label 'Balance';
        DeferralSummaryGLCaptionLbl: Label 'Deferral Summary - GL';
        RemAmtDefCaptionLbl: Label 'Remaining Amt. Deferred';
        TotAmtDefCaptionLbl: Label 'Total Amt. Deferred';
        BalanceAsOfDateFilter: Date;
        PostingDate: Date;
        AmtRecognized: Decimal;
        RemainingAmtDeferred: Decimal;
        BalanceAsOfDateCaptionLbl: Label 'Balance as of: ';
        AccountNoLbl: Label 'Account No.';
        AmtRecognizedLbl: Label 'Amt. Recognized';
        AccountName: Text[100];
        WorkingAccount: Code[20];
        PreviousAccount: Code[20];
        DeferralAccount: Code[20];

    procedure InitializeRequest(NewPrintOnlyOnePerPage: Boolean; NewBalanceAsOfDateFilter: Date)
    begin
        PrintOnlyOnePerPage := NewPrintOnlyOnePerPage;
        BalanceAsOfDateFilter := NewBalanceAsOfDateFilter;
    end;
}

