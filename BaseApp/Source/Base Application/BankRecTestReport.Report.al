#pragma warning disable AS0074
#if not CLEAN21
report 10407 "Bank Rec. Test Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './BankRecTestReport.rdlc';
    Caption = 'Bank Rec. Test Report';
    ObsoleteReason = 'Deprecated in favor of W1 Bank Reconciliation';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#pragma warning restore AS0074
    dataset
    {
        dataitem("Bank Rec. Header"; "Bank Rec. Header")
        {
            DataItemTableView = SORTING("Bank Account No.", "Statement No.");
            RequestFilterFields = "Bank Account No.", "Statement No.";
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(Statement_Balance_____Outstanding_Deposits______Outstanding_Checks_; ("Statement Balance" + "Outstanding Deposits") - "Outstanding Checks")
            {
            }
            column(Bank_Rec__Header__Outstanding_Checks_; "Outstanding Checks")
            {
            }
            column(Statement_Balance_____Outstanding_Deposits_; "Statement Balance" + "Outstanding Deposits")
            {
            }
            column(Positive_Adjustments_____Negative_Bal__Adjustments_; "Positive Adjustments" - "Negative Bal. Adjustments")
            {
            }
            column(Negative_Adjustments_____Positive_Bal__Adjustments_; "Negative Adjustments" - "Positive Bal. Adjustments")
            {
            }
            column(Bank_Rec__Header__Outstanding_Deposits_; "Outstanding Deposits")
            {
            }
            column(G_L_Balance______Positive_Adjustments_____Negative_Bal__Adjustments__; "G/L Balance" + ("Positive Adjustments" - "Negative Bal. Adjustments"))
            {
            }
            column(G_L_Balance___Positive_Adjustments___Negative_Bal__Adjustments___Negative_Adjustments___Positive_Bal__Adjustments__; "G/L Balance" + ("Positive Adjustments" - "Negative Bal. Adjustments") + ("Negative Adjustments" - "Positive Bal. Adjustments"))
            {
            }
            column(Difference; ("G/L Balance" + ("Positive Adjustments" - "Negative Bal. Adjustments") + ("Negative Adjustments" - "Positive Bal. Adjustments")) - (("Statement Balance" + "Outstanding Deposits") - "Outstanding Checks"))
            {
            }
            column(Bank_Rec__Header__G_L_Balance__LCY__; "G/L Balance (LCY)")
            {
            }
            column(Bank_Rec__Header__Statement_Balance_; "Statement Balance")
            {
            }
            column(Bank_Rec__Header__Statement_Date_; "Statement Date")
            {
            }
            column(Bank_Rec__Header__Currency_Code_; "Currency Code")
            {
            }
            column(Bank_Rec__Header__Statement_No__; "Statement No.")
            {
            }
            column(Bank_Rec__Header__Bank_Account_No__; "Bank Account No.")
            {
            }
            column(Bank_Rec__Header__G_L_Balance_; "G/L Balance")
            {
            }
            column(PrintDetails; PrintDetails)
            {
            }
            column(PrintChecks; PrintChecks)
            {
            }
            column(PrintDeposits; PrintDeposits)
            {
            }
            column(PrintAdjustments; PrintAdjustments)
            {
            }
            column(PrintOutstandingChecks; PrintOutstandingChecks)
            {
            }
            column(PrintOutstandingDeposits; PrintOutstandingDeposits)
            {
            }
            column(Amount_BalAmount; Amount_BalAmount)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Bank_Rec__Test_ReportCaption; Bank_Rec__Test_ReportCaptionLbl)
            {
            }
            column(Statement_Balance_____Outstanding_Deposits______Outstanding_Checks_Caption; Statement_Balance_____Outstanding_Deposits______Outstanding_Checks_CaptionLbl)
            {
            }
            column(Bank_Rec__Header__Outstanding_Checks_Caption; FieldCaption("Outstanding Checks"))
            {
            }
            column(Statement_Balance_____Outstanding_Deposits_Caption; Statement_Balance_____Outstanding_Deposits_CaptionLbl)
            {
            }
            column(Positive_Adjustments_____Negative_Bal__Adjustments_Caption; Positive_Adjustments_____Negative_Bal__Adjustments_CaptionLbl)
            {
            }
            column(Negative_Adjustments_____Positive_Bal__Adjustments_Caption; Negative_Adjustments_____Positive_Bal__Adjustments_CaptionLbl)
            {
            }
            column(Bank_Rec__Header__Outstanding_Deposits_Caption; FieldCaption("Outstanding Deposits"))
            {
            }
            column(G_L_Balance______Positive_Adjustments_____Negative_Bal__Adjustments__Caption; G_L_Balance______Positive_Adjustments_____Negative_Bal__Adjustments__CaptionLbl)
            {
            }
            column(G_L_Balance__Positive_Adjustments__Negative_Bal__Adjustments__Negative_Adjustments__Positive_Bal__Adjustments_Caption; G_L_Balance_Positive_Adjustments_Negative_Bal_Adjustments_Negative_Adjustments_Positive_Bal_Adjustments_Lbl)
            {
            }
            column(DifferenceCaption; DifferenceCaptionLbl)
            {
            }
            column(Bank_Rec__Header__G_L_Balance__LCY__Caption; FieldCaption("G/L Balance (LCY)"))
            {
            }
            column(Bank_Rec__Header__Statement_Balance_Caption; FieldCaption("Statement Balance"))
            {
            }
            column(Bank_Rec__Header__Statement_Date_Caption; FieldCaption("Statement Date"))
            {
            }
            column(Bank_Rec__Header__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            column(Bank_Rec__Header__Statement_No__Caption; FieldCaption("Statement No."))
            {
            }
            column(Bank_Rec__Header__Bank_Account_No__Caption; FieldCaption("Bank Account No."))
            {
            }
            column(Bank_Rec__Header__G_L_Balance_Caption; FieldCaption("G/L Balance"))
            {
            }
            column(DifferenceCaption_Control1020058; DifferenceCaption_Control1020058Lbl)
            {
            }
            column(Cleared___Balance_Amt_Caption; Cleared___Balance_Amt_CaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(Bal__Account_No_Caption; Bal__Account_No_CaptionLbl)
            {
            }
            column(Bal__Account_TypeCaption; Bal__Account_TypeCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Account_No_Caption; Account_No_CaptionLbl)
            {
            }
            column(Account_TypeCaption; Account_TypeCaptionLbl)
            {
            }
            column(Document_No_Caption; Document_No_CaptionLbl)
            {
            }
            column(Document_TypeCaption; Document_TypeCaptionLbl)
            {
            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            dataitem(ErrorLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(ErrorText_Number_; ErrorText[Number])
                {
                }
                column(ErrorLoop_Number; Number)
                {
                }

                trigger OnPostDataItem()
                begin
                    Clear(ErrorText);
                    ErrorCounter := 0;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, ErrorCounter);
                end;
            }
            dataitem(Checks; "Bank Rec. Line")
            {
                DataItemLink = "Bank Account No." = FIELD("Bank Account No."), "Statement No." = FIELD("Statement No.");
                DataItemTableView = SORTING("Bank Account No.", "Statement No.", "Record Type", "Line No.") WHERE("Record Type" = CONST(Check), Cleared = CONST(true));
                column(Checks__Posting_Date_; "Posting Date")
                {
                }
                column(Checks__Document_Type_; "Document Type")
                {
                }
                column(Checks__Document_No__; "Document No.")
                {
                }
                column(Checks_Description; Description)
                {
                }
                column(Checks_Amount; Amount)
                {
                }
                column(Checks__Cleared_Amount_; "Cleared Amount")
                {
                }
                column(Amount____Cleared_Amount_; Amount - "Cleared Amount")
                {
                }
                column(Checks__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(Checks__Bal__Account_Type_; "Bal. Account Type")
                {
                }
                column(Checks__Account_No__; "Account No.")
                {
                }
                column(Checks__Account_Type_; "Account Type")
                {
                }
                column(Checks_Amount_Control1020059; Amount)
                {
                }
                column(Checks__Cleared_Amount__Control1020060; "Cleared Amount")
                {
                }
                column(Amount____Cleared_Amount__Control1020061; Amount - "Cleared Amount")
                {
                }
                column(Checks_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(Checks_Statement_No_; "Statement No.")
                {
                }
                column(Checks_Record_Type; "Record Type")
                {
                }
                column(Checks_Line_No_; "Line No.")
                {
                }
                column(ChecksCaption; ChecksCaptionLbl)
                {
                }
                column(ChecksCaption_Control1020052; ChecksCaption_Control1020052Lbl)
                {
                }
                column(Total_ChecksCaption; Total_ChecksCaptionLbl)
                {
                }
            }
            dataitem(Deposits; "Bank Rec. Line")
            {
                DataItemLink = "Bank Account No." = FIELD("Bank Account No."), "Statement No." = FIELD("Statement No.");
                DataItemTableView = SORTING("Bank Account No.", "Statement No.", "Record Type", "Line No.") WHERE("Record Type" = CONST(Deposit), Cleared = CONST(true));
                column(Deposits_Amount; Amount)
                {
                }
                column(Amount____Cleared_Amount__Control1020129; Amount - "Cleared Amount")
                {
                }
                column(Deposits__Cleared_Amount_; "Cleared Amount")
                {
                }
                column(Deposits__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(Deposits__Bal__Account_Type_; "Bal. Account Type")
                {
                }
                column(Deposits_Description; Description)
                {
                }
                column(Deposits__Account_No__; "Account No.")
                {
                }
                column(Deposits__Account_Type_; "Account Type")
                {
                }
                column(Deposits__Document_No__; "Document No.")
                {
                }
                column(Deposits__Document_Type_; "Document Type")
                {
                }
                column(Deposits__Posting_Date_; "Posting Date")
                {
                }
                column(Amount____Cleared_Amount__Control1020094; Amount - "Cleared Amount")
                {
                }
                column(Deposits__Cleared_Amount__Control1020095; "Cleared Amount")
                {
                }
                column(Deposits_Amount_Control1020096; Amount)
                {
                }
                column(Deposits_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(Deposits_Statement_No_; "Statement No.")
                {
                }
                column(Deposits_Record_Type; "Record Type")
                {
                }
                column(Deposits_Line_No_; "Line No.")
                {
                }
                column(DepositsCaption; DepositsCaptionLbl)
                {
                }
                column(DepositsCaption_Control1020062; DepositsCaption_Control1020062Lbl)
                {
                }
                column(Total_DepositsCaption; Total_DepositsCaptionLbl)
                {
                }
                column(Deposit__External_Document_No_; "External Document No.")
                {
                }
            }
            dataitem(Adjustments; "Bank Rec. Line")
            {
                DataItemLink = "Bank Account No." = FIELD("Bank Account No."), "Statement No." = FIELD("Statement No.");
                DataItemTableView = SORTING("Bank Account No.", "Statement No.", "Record Type", "Line No.") WHERE("Record Type" = CONST(Adjustment), Cleared = CONST(true));
                column(Adjustments_Amount; Amount)
                {
                }
                column(BalAmount; -BalAmount)
                {
                }
                column(Adjustments__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(Adjustments__Bal__Account_Type_; "Bal. Account Type")
                {
                }
                column(Adjustments_Description; Description)
                {
                }
                column(Adjustments__Account_No__; "Account No.")
                {
                }
                column(Adjustments__Account_Type_; "Account Type")
                {
                }
                column(Adjustments__Document_No__; "Document No.")
                {
                }
                column(Adjustments__Document_Type_; "Document Type")
                {
                }
                column(Adjustments__Posting_Date_; "Posting Date")
                {
                }
                column(Adjustments_Amount_Control1020131; Amount)
                {
                }
                column(BalAmount_Control1020074; -BalAmount)
                {
                }
                column(Adjustments_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(Adjustments_Statement_No_; "Statement No.")
                {
                }
                column(Adjustments_Record_Type; "Record Type")
                {
                }
                column(Adjustments_Line_No_; "Line No.")
                {
                }
                column(AdjustmentsCaption; AdjustmentsCaptionLbl)
                {
                }
                column(AdjustmentsCaption_Control1020063; AdjustmentsCaption_Control1020063Lbl)
                {
                }
                column(Total_AdjustmentsCaption; Total_AdjustmentsCaptionLbl)
                {
                }
                column(Warning___Balance_must_be_zero_for_adjustments_Caption; Warning___Balance_must_be_zero_for_adjustments_CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Bal. Account No." = '' then
                        BalAmount := 0
                    else
                        BalAmount := Amount;
                    Amount_BalAmount := Amount - BalAmount
                end;

                trigger OnPreDataItem()
                begin
                    Clear(BalAmount);
                end;
            }
            dataitem(OutstandingChecks; "Bank Rec. Line")
            {
                DataItemLink = "Bank Account No." = FIELD("Bank Account No."), "Statement No." = FIELD("Statement No.");
                DataItemTableView = SORTING("Bank Account No.", "Statement No.", "Record Type", "Line No.") WHERE("Record Type" = CONST(Check), Cleared = CONST(false));
                column(OutstandingChecks_Amount; Amount)
                {
                }
                column(Amount____Cleared_Amount__Control1020157; Amount - "Cleared Amount")
                {
                }
                column(OutstandingChecks__Cleared_Amount_; "Cleared Amount")
                {
                }
                column(OutstandingChecks__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(OutstandingChecks__Bal__Account_Type_; "Bal. Account Type")
                {
                }
                column(OutstandingChecks_Description; Description)
                {
                }
                column(OutstandingChecks__Account_No__; "Account No.")
                {
                }
                column(OutstandingChecks__Account_Type_; "Account Type")
                {
                }
                column(OutstandingChecks__Document_No__; "Document No.")
                {
                }
                column(OutstandingChecks__Document_Type_; "Document Type")
                {
                }
                column(OutstandingChecks__Posting_Date_; "Posting Date")
                {
                }
                column(OutstandingChecks_Amount_Control1020136; Amount)
                {
                }
                column(OutstandingChecks_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(OutstandingChecks_Statement_No_; "Statement No.")
                {
                }
                column(OutstandingChecks_Record_Type; "Record Type")
                {
                }
                column(OutstandingChecks_Line_No_; "Line No.")
                {
                }
                column(Outstanding_ChecksCaption; Outstanding_ChecksCaptionLbl)
                {
                }
                column(Outstanding_ChecksCaption_Control1020064; Outstanding_ChecksCaption_Control1020064Lbl)
                {
                }
                column(Total_Outstanding_ChecksCaption; Total_Outstanding_ChecksCaptionLbl)
                {
                }
            }
            dataitem(OutstandingDeposits; "Bank Rec. Line")
            {
                DataItemLink = "Bank Account No." = FIELD("Bank Account No."), "Statement No." = FIELD("Statement No.");
                DataItemTableView = SORTING("Bank Account No.", "Statement No.", "Record Type", "Line No.") WHERE("Record Type" = CONST(Deposit), Cleared = CONST(false));
                column(OutstandingDeposits_Amount; Amount)
                {
                }
                column(Amount____Cleared_Amount__Control1020168; Amount - "Cleared Amount")
                {
                }
                column(OutstandingDeposits__Cleared_Amount_; "Cleared Amount")
                {
                }
                column(OutstandingDeposits__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(OutstandingDeposits__Bal__Account_Type_; "Bal. Account Type")
                {
                }
                column(OutstandingDeposits_Description; Description)
                {
                }
                column(OutstandingDeposits__Account_No__; "Account No.")
                {
                }
                column(OutstandingDeposits__Account_Type_; "Account Type")
                {
                }
                column(OutstandingDeposits__Document_No__; "Document No.")
                {
                }
                column(OutstandingDeposits__Document_Type_; "Document Type")
                {
                }
                column(OutstandingDeposits__Posting_Date_; "Posting Date")
                {
                }
                column(OutstandingDeposits_Amount_Control1020187; Amount)
                {
                }
                column(OutstandingDeposits_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(OutstandingDeposits_Statement_No_; "Statement No.")
                {
                }
                column(OutstandingDeposits_Record_Type; "Record Type")
                {
                }
                column(OutstandingDeposits_Line_No_; "Line No.")
                {
                }
                column(Outstanding_DepositsCaption; Outstanding_DepositsCaptionLbl)
                {
                }
                column(Outstanding_DepositsCaption_Control1020069; Outstanding_DepositsCaption_Control1020069Lbl)
                {
                }
                column(Total_Outstanding_DepositsCaption; Total_Outstanding_DepositsCaptionLbl)
                {
                }
                column(Outstanding__External_Document_No__; "External Document No.")
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                SetupRecord();

                CalculateBalance();
                Difference :=
                  Round(("G/L Balance" +
                   ("Positive Adjustments" - "Negative Bal. Adjustments") +
                   ("Negative Adjustments" - "Positive Bal. Adjustments")) -
                  (("Statement Balance" + "Outstanding Deposits") - "Outstanding Checks"), 0.01);
                if Difference <> 0 then
                    AddError(StrSubstNo('Difference %1 must be zero before statement can be posted!', Difference));

                if "Statement Date" = 0D then
                    AddError('Statement date must be entered!');
                if "Statement No." = '' then
                    AddError('Statement number must be entered!');
                if "Bank Account No." = '' then
                    AddError('Bank account number must be entered!');
            end;

            trigger OnPreDataItem()
            begin
                Clear(ErrorText);
                ErrorCounter := 0;
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
                    field(PrintDetails; PrintDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print details';
                        ToolTip = 'Specifies if individual transactions are included in the report. Clear the check box to include only totals.';

                        trigger OnValidate()
                        begin
                            if PrintDetails then begin
                                PrintChecks := true;
                                PrintDeposits := true;
                                PrintAdjustments := true;
                                PrintOutstandingChecks := true;
                                PrintOutstandingDeposits := true;
                            end;
                            PrintDetailsOnAfterValidate();
                        end;
                    }
                    field(PrintChecks; PrintChecks)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print checks';
                        Editable = PrintChecksEditable;
                        ToolTip = 'Specifies if the report includes bank reconciliation lines for checks.';
                    }
                    field(PrintDeposits; PrintDeposits)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print deposits';
                        Editable = PrintDepositsEditable;
                        ToolTip = 'Specifies if the report includes bank reconciliation lines for deposits.';
                    }
                    field(PrintAdj; PrintAdjustments)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print adjustments';
                        Editable = PrintAdjEditable;
                        ToolTip = 'Specifies if the report includes bank reconciliation lines for adjustments.';
                    }
                    field(PrintOutChecks; PrintOutstandingChecks)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print outstanding checks';
                        Editable = PrintOutChecksEditable;
                        ToolTip = 'Specifies if the report includes bank reconciliation lines for outstanding checks.';
                    }
                    field(PrintOutDeposits; PrintOutstandingDeposits)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print outstanding deposits';
                        Editable = PrintOutDepositsEditable;
                        ToolTip = 'Specifies if the report includes bank reconciliation lines for outstanding deposits.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            PrintChecksEditable := true;
            PrintDepositsEditable := true;
            PrintAdjEditable := true;
            PrintOutDepositsEditable := true;
            PrintOutChecksEditable := true;
        end;

        trigger OnOpenPage()
        begin
            SetupRequestForm();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
    end;

    var
        PrintDetails: Boolean;
        PrintChecks: Boolean;
        PrintDeposits: Boolean;
        PrintAdjustments: Boolean;
        PrintOutstandingChecks: Boolean;
        PrintOutstandingDeposits: Boolean;
        Difference: Decimal;
        BalAmount: Decimal;
        ErrorCounter: Integer;
        ErrorText: array[50] of Text[250];
        CompanyInformation: Record "Company Information";
        Amount_BalAmount: Decimal;
        [InDataSet]
        PrintOutChecksEditable: Boolean;
        [InDataSet]
        PrintOutDepositsEditable: Boolean;
        [InDataSet]
        PrintAdjEditable: Boolean;
        [InDataSet]
        PrintDepositsEditable: Boolean;
        [InDataSet]
        PrintChecksEditable: Boolean;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Bank_Rec__Test_ReportCaptionLbl: Label 'Bank Rec. Test Report';
        Statement_Balance_____Outstanding_Deposits______Outstanding_Checks_CaptionLbl: Label 'Ending Balance';
        Statement_Balance_____Outstanding_Deposits_CaptionLbl: Label 'Subtotal';
        Positive_Adjustments_____Negative_Bal__Adjustments_CaptionLbl: Label 'Positive Adjustments';
        Negative_Adjustments_____Positive_Bal__Adjustments_CaptionLbl: Label 'Negative Adjustments';
        G_L_Balance______Positive_Adjustments_____Negative_Bal__Adjustments__CaptionLbl: Label 'Subtotal';
        G_L_Balance_Positive_Adjustments_Negative_Bal_Adjustments_Negative_Adjustments_Positive_Bal_Adjustments_Lbl: Label 'Ending G/L Balance';
        DifferenceCaptionLbl: Label 'Difference';
        DifferenceCaption_Control1020058Lbl: Label 'Difference';
        Cleared___Balance_Amt_CaptionLbl: Label 'Cleared / Balance Amt.';
        AmountCaptionLbl: Label 'Amount';
        Bal__Account_No_CaptionLbl: Label 'Bal. Account No.';
        Bal__Account_TypeCaptionLbl: Label 'Bal. Account Type';
        DescriptionCaptionLbl: Label 'Description';
        Account_No_CaptionLbl: Label 'Account No.';
        Account_TypeCaptionLbl: Label 'Account Type';
        Document_No_CaptionLbl: Label 'Document No.';
        Document_TypeCaptionLbl: Label 'Document Type';
        Posting_DateCaptionLbl: Label 'Posting Date';
        ChecksCaptionLbl: Label 'Checks';
        ChecksCaption_Control1020052Lbl: Label 'Checks';
        Total_ChecksCaptionLbl: Label 'Total Checks';
        DepositsCaptionLbl: Label 'Deposits';
        DepositsCaption_Control1020062Lbl: Label 'Deposits';
        Total_DepositsCaptionLbl: Label 'Total Deposits';
        AdjustmentsCaptionLbl: Label 'Adjustments';
        AdjustmentsCaption_Control1020063Lbl: Label 'Adjustments';
        Total_AdjustmentsCaptionLbl: Label 'Total Adjustments';
        Warning___Balance_must_be_zero_for_adjustments_CaptionLbl: Label 'Warning!  Balance must be zero for adjustments!';
        Outstanding_ChecksCaptionLbl: Label 'Outstanding Checks';
        Outstanding_ChecksCaption_Control1020064Lbl: Label 'Outstanding Checks';
        Total_Outstanding_ChecksCaptionLbl: Label 'Total Outstanding Checks';
        Outstanding_DepositsCaptionLbl: Label 'Outstanding Deposits';
        Outstanding_DepositsCaption_Control1020069Lbl: Label 'Outstanding Deposits';
        Total_Outstanding_DepositsCaptionLbl: Label 'Total Outstanding Deposits';

    procedure SetupRecord()
    begin
        with "Bank Rec. Header" do begin
            SetRange("Date Filter", "Statement Date");
            CalcFields("Positive Adjustments",
              "Positive Bal. Adjustments",
              "Negative Adjustments",
              "Negative Bal. Adjustments",
              "Outstanding Deposits",
              "Outstanding Checks");
        end;
    end;

    procedure SetupRequestForm()
    begin
        PageSetupRequestForm();
    end;

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := StrSubstNo('Warning!  %1', Text);
    end;

    local procedure PrintDetailsOnAfterValidate()
    begin
        SetupRequestForm();
    end;

    local procedure PageSetupRequestForm()
    begin
        if not PrintDetails then begin
            PrintChecks := false;
            PrintDeposits := false;
            PrintAdjustments := false;
            PrintOutstandingChecks := false;
            PrintOutstandingDeposits := false;
        end;

        PrintOutChecksEditable := PrintDetails;
        PrintOutDepositsEditable := PrintDetails;
        PrintAdjEditable := PrintDetails;
        PrintDepositsEditable := PrintDetails;
        PrintChecksEditable := PrintDetails;
    end;
}

#endif