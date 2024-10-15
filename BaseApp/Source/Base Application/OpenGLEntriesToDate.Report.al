report 11781 "Open G/L Entries To Date"
{
    DefaultLayout = RDLC;
    RDLCLayout = './OpenGLEntriesToDate.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Open G/L Entries To Date';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Entry"; "G/L Entry")
        {
            RequestFilterFields = "G/L Account No.";
            column(SkipEntiesDetail; SkipEntiesDetail)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(BalanceToDate; BalanceToDate)
            {
            }
            column(G_L_Entry__G_L_Entry___G_L_Account_No__; "G/L Entry"."G/L Account No.")
            {
            }
            column(GLAccount_Name; GLAccount.Name)
            {
            }
            column(G_L_Entry__Posting_Date_; "Posting Date")
            {
            }
            column(G_L_Entry__Document_Type_; "Document Type")
            {
            }
            column(G_L_Entry__Document_No__; "Document No.")
            {
            }
            column(G_L_Entry_Description; Description)
            {
            }
            column(G_L_Entry_Amount; Amount)
            {
            }
            column(Amount___AppliedAmount; Amount - AppliedAmount)
            {
            }
            column(DebitAmount; DebitAmount)
            {
            }
            column(CreditAmount; CreditAmount)
            {
            }
            column(G_L_Entry__G_L_Entry___G_L_Account_No___Control1220014; "G/L Entry"."G/L Account No.")
            {
            }
            column(TotalOpenAmount; TotalOpenAmount)
            {
            }
            column(TotalDebitAmount; TotalDebitAmount)
            {
            }
            column(TotalCreditAmount; TotalCreditAmount)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Open_G_L_Entries_To_DateCaption; Open_G_L_Entries_To_DateCaptionLbl)
            {
            }
            column(Balance_To_Date_Caption; Balance_To_Date_CaptionLbl)
            {
            }
            column(Credit_AmountCaption; Credit_AmountCaptionLbl)
            {
            }
            column(Debit_AmountCaption; Debit_AmountCaptionLbl)
            {
            }
            column(Open_AmountCaption; Open_AmountCaptionLbl)
            {
            }
            column(Original_AmountCaption; Original_AmountCaptionLbl)
            {
            }
            column(G_L_Entry__Posting_Date_Caption; FieldCaption("Posting Date"))
            {
            }
            column(G_L_Entry__Document_Type_Caption; FieldCaption("Document Type"))
            {
            }
            column(G_L_Entry__Document_No__Caption; FieldCaption("Document No."))
            {
            }
            column(G_L_Entry_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Credit_AmountCaption_Control1220021; Credit_AmountCaption_Control1220021Lbl)
            {
            }
            column(Debit_AmountCaption_Control1220022; Debit_AmountCaption_Control1220022Lbl)
            {
            }
            column(Open_AmountCaption_Control1220025; Open_AmountCaption_Control1220025Lbl)
            {
            }
            column(Account_No_Caption; Account_No_CaptionLbl)
            {
            }
            column(Account_TotalCaption; Account_TotalCaptionLbl)
            {
            }
            column(G_L_Entry_Entry_No_; "Entry No.")
            {
            }

            trigger OnAfterGetRecord()
            var
                GLEntry: Record "G/L Entry";
            begin
                if PreviousAccountNo <> "G/L Entry"."G/L Account No." then begin
                    TotalOpenAmount := 0;
                    TotalDebitAmount := 0;
                    TotalCreditAmount := 0;
                    PreviousAccountNo := "G/L Entry"."G/L Account No.";
                end;
                if Closed and ("Closed at Date" <= BalanceToDate) then
                    CurrReport.Skip();
                AppliedAmount := 0;
                DebitAmount := 0;
                CreditAmount := 0;
                GLAccount.Get("G/L Account No.");

                GLEntry := "G/L Entry";
                GLEntry.Find;
                GLEntry.SetFilter("Date Filter", '..%1', BalanceToDate);
                GLEntry.CalcFields("Applied Amount");
                AppliedAmount := GLEntry."Applied Amount";

                if "Debit Amount" <> 0 then
                    DebitAmount := (Amount - AppliedAmount)
                else
                    CreditAmount := -(Amount - AppliedAmount);

                TotalOpenAmount += (Amount - AppliedAmount);
                TotalDebitAmount += DebitAmount;
                TotalCreditAmount += CreditAmount;
            end;

            trigger OnPreDataItem()
            begin
                SetCurrentKey("G/L Account No.", "Posting Date");
                if BalanceToDate = 0D then
                    BalanceToDate := WorkDate;

                SetFilter("Posting Date", '..%1', BalanceToDate);
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
                    field(BalanceToDate; BalanceToDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Balance to Date';
                        ToolTip = 'Specifies the last date in the period for open general ledger entries.';
                    }
                    field(SkipEntiesDetail; SkipEntiesDetail)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip Entry Details';
                        ToolTip = 'Specifies when entry details are to be skip';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            BalanceToDate := WorkDate;
        end;
    }

    labels
    {
    }

    var
        GLAccount: Record "G/L Account";
        BalanceToDate: Date;
        SkipEntiesDetail: Boolean;
        DebitAmount: Decimal;
        CreditAmount: Decimal;
        AppliedAmount: Decimal;
        TotalOpenAmount: Decimal;
        TotalDebitAmount: Decimal;
        TotalCreditAmount: Decimal;
        PreviousAccountNo: Code[20];
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Open_G_L_Entries_To_DateCaptionLbl: Label 'Open G/L Entries To Date';
        Balance_To_Date_CaptionLbl: Label 'Balance To Date:';
        Credit_AmountCaptionLbl: Label 'Credit Amount';
        Debit_AmountCaptionLbl: Label 'Debit Amount';
        Open_AmountCaptionLbl: Label 'Open Amount';
        Original_AmountCaptionLbl: Label 'Original Amount';
        DescriptionCaptionLbl: Label 'Description';
        Credit_AmountCaption_Control1220021Lbl: Label 'Credit Amount';
        Debit_AmountCaption_Control1220022Lbl: Label 'Debit Amount';
        Open_AmountCaption_Control1220025Lbl: Label 'Open Amount';
        Account_No_CaptionLbl: Label 'Account No.';
        Account_TotalCaptionLbl: Label 'Account Total';
}

