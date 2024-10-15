report 11778 "Open Customer Entries at Date"
{
    DefaultLayout = RDLC;
    RDLCLayout = './OpenCustomerEntriesatDate.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Open Customer Entries to Date';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Header; "Integer")
        {
            DataItemTableView = SORTING(Number);
            MaxIteration = 1;
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(STRSUBSTNO_gtcText000_gteCustDateFilter_; StrSubstNo(Text000, CustDateFilter))
            {
            }
            column(gteInfoText; InfoText)
            {
            }
            column(Customer_TABLECAPTION__________gteCustFilter; Customer.TableCaption + ': ' + CustFilter)
            {
            }
            column(Cust__Ledger_Entry__TABLECAPTION__________gteLedgerEntryFilter; "Cust. Ledger Entry".TableCaption + ': ' + LedgerEntryFilter)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Open_Customer_Entries_at_DateCaption; Open_Customer_Entries_at_DateCaptionLbl)
            {
            }
            column(gboSkipBalance; SkipBalance)
            {
            }
            column(gboPrintCurrency; PrintCurrency)
            {
            }
            column(gboSkipDetail; SkipDetail)
            {
            }
            column(gboSkipTotal; SkipTotal)
            {
            }
            column(gboSkipGLAcc; SkipGLAcc)
            {
            }
            column(gteLedgerEntryFilter; LedgerEntryFilter)
            {
            }
            column(gteCustFilter; CustFilter)
            {
            }
            column(Header_Number; Number)
            {
            }
            column(CustomerNoCaption; Customer.FieldCaption("No."))
            {
            }
            column(CustomerNameCaption; Customer.FieldCaption(Name))
            {
            }
            column(Original_AmountCaption; "Cust. Ledger Entry".FieldCaption("Original Amount"))
            {
            }
            column(RemainingAmountCaption; "Cust. Ledger Entry".FieldCaption("Remaining Amount"))
            {
            }
            column(CurrencyCodeCaption; "Cust. Ledger Entry".FieldCaption("Currency Code"))
            {
            }
            column(DueDateCaption; "Cust. Ledger Entry".FieldCaption("Due Date"))
            {
            }
            column(DescriptionCaption; "Cust. Ledger Entry".FieldCaption(Description))
            {
            }
            column(DocumentNoCaption; "Cust. Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(DocumentTypeCaption; "Cust. Ledger Entry".FieldCaption("Document Type"))
            {
            }
            column(PostingDateCaption; "Cust. Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(ginDaysAfterDueCaption; DaysAfterDueCaptionLbl)
            {
            }
            dataitem(Customer; Customer)
            {
                DataItemTableView = SORTING("No.");
                RequestFilterFields = "No.", "Customer Posting Group", "Date Filter";

                trigger OnPreDataItem()
                begin
                    CurrReport.Break();
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                PrintOnlyIfDetail = true;
                column(greCustomer_Name; Cust.Name)
                {
                }
                column(greCustomer__No__; Cust."No.")
                {
                }
                column(Integer_Number; Number)
                {
                }
                dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                {
                    DataItemTableView = SORTING("Customer No.", "Posting Date") ORDER(Ascending);
                    RequestFilterFields = "Document Type";
                    column(Cust__Ledger_Entry__Original_Amt___LCY__; "Original Amt. (LCY)")
                    {
                    }
                    column(greGLSetup__LCY_Code_; GLSetup."LCY Code")
                    {
                    }
                    column(ginDaysAfterDue; DaysAfterDue)
                    {
                    }
                    column(Cust__Ledger_Entry_Description; Description)
                    {
                    }
                    column(Cust__Ledger_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(Cust__Ledger_Entry__Document_Type_; "Document Type")
                    {
                    }
                    column(Cust__Ledger_Entry__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(Cust__Ledger_Entry__Due_Date_; Format("Due Date"))
                    {
                    }
                    column(Cust__Ledger_Entry__Remaining_Amt___LCY__; "Remaining Amt. (LCY)")
                    {
                    }
                    column(gcoCurrency; Currency)
                    {
                    }
                    column(Cust__Ledger_Entry__Original_Amount_; "Original Amount")
                    {
                    }
                    column(Cust__Ledger_Entry__Remaining_Amount_; "Remaining Amount")
                    {
                    }
                    column(gdeBalance_1_; Balance[1])
                    {
                    }
                    column(gdeBalance_2_; Balance[2])
                    {
                    }
                    column(gdeBalance_3_; Balance[3])
                    {
                    }
                    column(gdeBalance_4_; Balance[4])
                    {
                    }
                    column(gdeBalance_5_; Balance[5])
                    {
                    }
                    column(gdeBalance_6_; Balance[6])
                    {
                    }
                    column(gdeBalance_7_; Balance[7])
                    {
                    }
                    column(BalanceCaption1; InMatureCaption)
                    {
                    }
                    column(BalanceCaption2; StrSubstNo('%1 %2', Text001, LimitDate[1]))
                    {
                    }
                    column(BalanceCaption3; StrSubstNo('%1 %2', Text001, LimitDate[2]))
                    {
                    }
                    column(BalanceCaption4; StrSubstNo('%1 %2', Text001, LimitDate[3]))
                    {
                    }
                    column(BalanceCaption5; StrSubstNo('%1 %2', Text001, LimitDate[4]))
                    {
                    }
                    column(BalanceCaption6; StrSubstNo('%1 %2', Text001, LimitDate[5]))
                    {
                    }
                    column(BalanceCaption7; StrSubstNo('%1 %2', Text002, LimitDate[5]))
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }
                    column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Original Amt. (LCY)", "Remaining Amt. (LCY)");
                        if PrintCurrency then
                            CalcFields("Original Amount", "Remaining Amount");

                        if not (("Remaining Amt. (LCY)" <> 0) or ("Remaining Amount" <> 0)) then
                            CurrReport.Skip();

                        if "Currency Code" = '' then
                            Currency := GLSetup."LCY Code"
                        else
                            Currency := "Currency Code";

                        // calculate days after due date
                        if "Due Date" = 0D then
                            "Due Date" := "Posting Date";
                        DaysAfterDue := LastDate - "Due Date";
                        if DaysAfterDue < 0 then
                            DaysAfterDue := 0;

                        if not SkipBalance then
                            case true of
                                DaysAfterDue <= 0:
                                    begin
                                        Balance[1] += "Remaining Amt. (LCY)";
                                        BalanceT[1] += "Remaining Amt. (LCY)";
                                    end;
                                DaysAfterDue <= Days[1]:
                                    begin
                                        Balance[2] += "Remaining Amt. (LCY)";
                                        BalanceT[2] += "Remaining Amt. (LCY)";
                                    end;
                                DaysAfterDue <= Days[2]:
                                    begin
                                        Balance[3] += "Remaining Amt. (LCY)";
                                        BalanceT[3] += "Remaining Amt. (LCY)";
                                    end;
                                DaysAfterDue <= Days[3]:
                                    begin
                                        Balance[4] += "Remaining Amt. (LCY)";
                                        BalanceT[4] += "Remaining Amt. (LCY)";
                                    end;
                                DaysAfterDue <= Days[4]:
                                    begin
                                        Balance[5] += "Remaining Amt. (LCY)";
                                        BalanceT[5] += "Remaining Amt. (LCY)";
                                    end;
                                DaysAfterDue <= Days[5]:
                                    begin
                                        Balance[6] += "Remaining Amt. (LCY)";
                                        BalanceT[6] += "Remaining Amt. (LCY)";
                                    end;
                                else begin
                                        Balance[7] += "Remaining Amt. (LCY)";
                                        BalanceT[7] += "Remaining Amt. (LCY)";
                                    end;
                            end;

                        // buffer for total sumary by G/L account;
                        CustPostingGroup.Get("Customer Posting Group");

                        if Prepayment then
                            UpdateBuffer(TGLAccBuffer, CustPostingGroup."Advance Account", "Remaining Amt. (LCY)", 0)
                        else
                            UpdateBuffer(TGLAccBuffer, CustPostingGroup."Receivables Account", "Remaining Amt. (LCY)", 0);
                        UpdateBuffer(TTotalCurrencyBuffer, '', "Original Amt. (LCY)", "Remaining Amt. (LCY)");

                        if PrintCurrency then begin
                            UpdateBuffer(TCurrencyBuffer, Currency, "Original Amount", "Remaining Amount");
                            UpdateBuffer(TTotalCurrencyBuffer, Currency, "Original Amount", "Remaining Amount");
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Customer No.", Cust."No.");
                        SetFilter("Posting Date", Customer.GetFilter("Date Filter"));
                        SetFilter("Date Filter", Customer.GetFilter("Date Filter"));
                        Clear(Balance);
                    end;
                }
                dataitem(CustomerByCurrency; "Integer")
                {
                    DataItemTableView = SORTING(Number) ORDER(Ascending) WHERE(Number = FILTER(> 0));
                    column(greTCurrencyBuffer__Net_Change_in_Jnl__; TCurrencyBuffer."Net Change in Jnl.")
                    {
                    }
                    column(greTCurrencyBuffer__Balance_after_Posting_; TCurrencyBuffer."Balance after Posting")
                    {
                    }
                    column(greTCurrencyBuffer__No__; TCurrencyBuffer."No.")
                    {
                    }
                    column(of_itCaption; of_itCaptionLbl)
                    {
                    }
                    column(CustomerByCurrency_Number; Number)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number <> 1 then
                            TCurrencyBuffer.Next;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not TCurrencyBuffer.Find('-') then
                            CurrReport.Break();
                        SetRange(Number, 1, TCurrencyBuffer.Count);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    lreCustEntry: Record "Cust. Ledger Entry";
                begin
                    CustActual := CustActual + 1;
                    Window.Update(1, Round(CustActual / CustCount * 10000, 1));
                    if Number <> 1 then
                        Cust.Next;

                    if CustActual = CustCount then begin
                        Cust.Reset();
                        Cust.Init();
                        Cust."No." := '';
                        lreCustEntry.SetCurrentKey("Customer No.");
                        lreCustEntry.SetRange("Customer No.", '');
                        if lreCustEntry.IsEmpty then
                            CurrReport.Skip();
                    end;
                    TCurrencyBuffer.DeleteAll();
                end;

                trigger OnPreDataItem()
                begin
                    if not Cust.Find('-') then
                        CurrReport.Break();

                    CustCount := Cust.Count + 1;
                    CustActual := 0;
                    Window.Open(TxtWorkDlg);
                    SetRange(Number, 1, CustCount);
                end;
            }
            dataitem(TotalByCurrency; "Integer")
            {
                DataItemTableView = SORTING(Number) ORDER(Ascending) WHERE(Number = FILTER(> 0));
                column(greTTotalCurrencyBuffer__Net_Change_in_Jnl__; TTotalCurrencyBuffer."Net Change in Jnl.")
                {
                }
                column(greTTotalCurrencyBuffer__Balance_after_Posting_; TTotalCurrencyBuffer."Balance after Posting")
                {
                }
                column(greGLSetup__LCY_Code__Control72; GLSetup."LCY Code")
                {
                }
                column(greTTotalCurrencyBuffer__Net_Change_in_Jnl___Control1104000005; TTotalCurrencyBuffer."Net Change in Jnl.")
                {
                }
                column(greTTotalCurrencyBuffer__Balance_after_Posting__Control1104000009; TTotalCurrencyBuffer."Balance after Posting")
                {
                }
                column(greTTotalCurrencyBuffer__No__; TTotalCurrencyBuffer."No.")
                {
                }
                column(gdeBalanceT_1_; BalanceT[1])
                {
                }
                column(gdeBalanceT_2_; BalanceT[2])
                {
                }
                column(gdeBalanceT_3_; BalanceT[3])
                {
                }
                column(gdeBalanceT_4_; BalanceT[4])
                {
                }
                column(gdeBalanceT_5_; BalanceT[5])
                {
                }
                column(gdeBalanceT_6_; BalanceT[6])
                {
                }
                column(gdeBalanceT_7_; BalanceT[7])
                {
                }
                column(BalanceTCaption1; InMatureCaption)
                {
                }
                column(BalanceTCaption2; StrSubstNo('%1 %2', Text001, LimitDate[1]))
                {
                }
                column(BalanceTCaption3; StrSubstNo('%1 %2', Text001, LimitDate[2]))
                {
                }
                column(BalanceTCaption4; StrSubstNo('%1 %2', Text001, LimitDate[3]))
                {
                }
                column(BalanceTCaption5; StrSubstNo('%1 %2', Text001, LimitDate[4]))
                {
                }
                column(BalanceTCaption6; StrSubstNo('%1 %2', Text001, LimitDate[5]))
                {
                }
                column(BalanceTCaption7; StrSubstNo('%1 %2', Text002, LimitDate[5]))
                {
                }
                column(TotalCaption_Control1104000029; TotalCaption_Control1104000029Lbl)
                {
                }
                column(of_itCaption_Control1104000028; of_itCaption_Control1104000028Lbl)
                {
                }
                column(TotalByCurrency_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number <> 1 then
                        TTotalCurrencyBuffer.Next;
                end;

                trigger OnPreDataItem()
                begin
                    if not TTotalCurrencyBuffer.Find('-') then
                        CurrReport.Break();

                    SetRange(Number, 1, TTotalCurrencyBuffer.Count);
                end;
            }
            dataitem(GLAccDetail; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(greGLAcc_FIELDCAPTION__Balance_at_Date__; GLAcc.FieldCaption("Balance at Date"))
                {
                }
                column(greGLAcc_FIELDCAPTION__No___; GLAcc.FieldCaption("No."))
                {
                }
                column(greGLAcc_FIELDCAPTION_Name_; GLAcc.FieldCaption(Name))
                {
                }
                column(greTGLAccBuffer__No__; TGLAccBuffer."No.")
                {
                }
                column(greGLAcc_Name; GLAcc.Name)
                {
                }
                column(greTGLAccBuffer__Balance_after_Posting_; TGLAccBuffer."Balance after Posting")
                {
                }
                column(greTGLAccBuffer__Balance_after_Posting____greGLAcc__Net_Change_; TGLAccBuffer."Balance after Posting" - GLAcc."Net Change")
                {
                }
                column(greGLAcc__Net_Change_; GLAcc."Net Change")
                {
                }
                column(greTGLAccBuffer__Balance_after_Posting____greGLAcc__Net_Change__Control1100170000; TGLAccBuffer."Balance after Posting" - GLAcc."Net Change")
                {
                }
                column(greGLAcc__Net_Change__Control1100170001; GLAcc."Net Change")
                {
                }
                column(greTGLAccBuffer__Balance_after_Posting__Control1100170002; TGLAccBuffer."Balance after Posting")
                {
                }
                column(General_Ledger_SpecificationCaption; General_Ledger_SpecificationCaptionLbl)
                {
                }
                column(greTGLAccBuffer__Balance_after_Posting____greGLAcc__Net_Change_Caption; TGLAccBuffer__Balance_after_Posting____greGLAcc__Net_Change_CaptionLbl)
                {
                }
                column(greGLAcc__Net_Change_Caption; GLAcc__Net_Change_CaptionLbl)
                {
                }
                column(TotalCaption_Control1100170003; TotalCaption_Control1100170003Lbl)
                {
                }
                column(GLAccDetail_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then begin
                        if not TGLAccBuffer.FindSet then
                            CurrReport.Break();
                    end else
                        if TGLAccBuffer.Next = 0 then
                            CurrReport.Break();

                    GLAcc.Get(TGLAccBuffer."No.");
                    GLAcc.CalcFields("Net Change");
                end;

                trigger OnPreDataItem()
                begin
                    if SkipGLAcc then
                        CurrReport.Break();

                    TGLAccBuffer.Reset();
                    if TGLAccBuffer.IsEmpty then
                        CurrReport.Break();

                    SetRange(Number, 1, TGLAccBuffer.Count);
                    GLAcc.SetFilter("Date Filter", Customer.GetFilter("Date Filter"));
                end;
            }

            trigger OnPreDataItem()
            var
                lin: Integer;
            begin
                if not SkipBalance then
                    for lin := 1 to 5 do
                        Days[lin] := (CalcDate(StrSubstNo('<CD> + <%1>', Format(LimitDate[lin])), Today) - Today);
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
                    field(PrintCurrency; PrintCurrency)
                    {
                        ApplicationArea = All;
                        Caption = 'Show Currency';
                        ToolTip = 'Specifies when the currency is to be show';
                        Visible = CurrencyIncludeVisible;
                    }
                    field(CustPerPage; CustPerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Per Page';
                        ToolTip = 'Specifies if each customer has to be printed on new page.';
                        Visible = false;
                    }
                    field(SkipDetail; SkipDetail)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip Entries';
                        ToolTip = 'Specifies when the entries are to be skip';
                    }
                    field(SkipTotal; SkipTotal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip Customer Total';
                        ToolTip = 'Specifies when the custom balance is to be skip';
                    }
                    field(SkipGLAcc; SkipGLAcc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip General Ledger Specification';
                        ToolTip = 'Specifies when the general ledger specification is to be skip';
                    }
                    field(SkipBalance; SkipBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip Balance';
                        ToolTip = 'Specifies when the balance is to be skip';

                        trigger OnValidate()
                        begin
                            SkipBalanceOnPush;
                        end;
                    }
                    group(Limits)
                    {
                        Caption = 'Limits';
                        Enabled = LimitEnabled;
                        field("LimitDate[1]"; LimitDate[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Limit 1.';
                            Enabled = LimitEnabled;
                            ToolTip = 'Specifies the number of due date for customer''s entries calculation.';
                        }
                        field("LimitDate[2]"; LimitDate[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Limit 2.';
                            Enabled = LimitEnabled;
                            ToolTip = 'Specifies the number of due date for customer''s entries calculation.';
                        }
                        field("LimitDate[3]"; LimitDate[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Limit 3.';
                            Enabled = LimitEnabled;
                            ToolTip = 'Specifies the number of due date for customer''s entries calculation.';
                        }
                        field("LimitDate[4]"; LimitDate[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Limit 4.';
                            Enabled = LimitEnabled;
                            ToolTip = 'Specifies the number of due date for customer''s entries calculation.';
                        }
                        field("LimitDate[5]"; LimitDate[5])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Limit 5.';
                            Enabled = LimitEnabled;
                            ToolTip = 'Specifies the number of due date for customer''s entries calculation.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LimitEnabled := true;
            CurrencyIncludeVisible := true;
        end;

        trigger OnOpenPage()
        begin
            CurrencyIncludeVisible := CurrencyAllowed;
            LimitEnabled := not SkipBalance;
            if not SkipBalance then begin
                Evaluate(LimitDate[1], Format('<30D>'));
                Evaluate(LimitDate[2], Format('<60D>'));
                Evaluate(LimitDate[3], Format('<90D>'));
                Evaluate(LimitDate[4], Format('<120D>'));
                Evaluate(LimitDate[5], Format('<150D>'));
            end;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        Currency: Record Currency;
    begin
        CurrencyAllowed := Currency.ReadPermission;
    end;

    trigger OnPreReport()
    var
        ltcILC: Label 'In local currency';
        ltcIEC: Label ' and in original currency.';
    begin
        GLSetup.Get();
        Cust.CopyFilters(Customer);
        CustFilter := Customer.GetFilters;
        CustDateFilter := Customer.GetFilter("Date Filter");
        LedgerEntryFilter := "Cust. Ledger Entry".GetFilters;
        LastDate := Customer.GetRangeMax("Date Filter");
        InfoText := ltcILC;
        if PrintCurrency and CurrencyAllowed then
            InfoText := InfoText + ltcIEC
        else
            InfoText := InfoText + '.';
    end;

    var
        Cust: Record Customer;
        GLSetup: Record "General Ledger Setup";
        TGLAccBuffer: Record "G/L Account Net Change" temporary;
        TCurrencyBuffer: Record "G/L Account Net Change" temporary;
        TTotalCurrencyBuffer: Record "G/L Account Net Change" temporary;
        CustPostingGroup: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
        Currency: Code[10];
        Window: Dialog;
        LimitDate: array[5] of DateFormula;
        CustDateFilter: Text;
        CustFilter: Text;
        LedgerEntryFilter: Text;
        InfoText: Text[100];
        LastDate: Date;
        Balance: array[7] of Decimal;
        BalanceT: array[7] of Decimal;
        DaysAfterDue: Integer;
        CustCount: Integer;
        CustActual: Integer;
        Days: array[5] of Integer;
        SkipBalance: Boolean;
        PrintCurrency: Boolean;
        SkipDetail: Boolean;
        SkipTotal: Boolean;
        SkipGLAcc: Boolean;
        CustPerPage: Boolean;
        CurrencyAllowed: Boolean;
        [InDataSet]
        CurrencyIncludeVisible: Boolean;
        [InDataSet]
        LimitEnabled: Boolean;
        Text000: Label 'Period: %1';
        Text001: Label 'To';
        Text002: Label 'Over';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Open_Customer_Entries_at_DateCaptionLbl: Label 'Open Customer Entries at Date';
        DaysAfterDueCaptionLbl: Label 'Days after Due Date';
        TotalCaptionLbl: Label 'Total';
        InMatureCaption: Label 'In mature';
        of_itCaptionLbl: Label 'of it';
        TotalCaption_Control1104000029Lbl: Label 'Total';
        of_itCaption_Control1104000028Lbl: Label 'of it';
        General_Ledger_SpecificationCaptionLbl: Label 'General Ledger Specification';
        TGLAccBuffer__Balance_after_Posting____greGLAcc__Net_Change_CaptionLbl: Label 'Difference';
        GLAcc__Net_Change_CaptionLbl: Label 'Balance at Date by GL';
        TotalCaption_Control1100170003Lbl: Label 'Total';
        TxtWorkDlg: Label 'Processing Customers @1@@@@@@@@@@@@@@@@@@';

    local procedure UpdateBuffer(var lreTBuffer: Record "G/L Account Net Change" temporary; lcoAccount: Code[20]; ldeAmount: Decimal; ldeAmount2: Decimal)
    begin
        with lreTBuffer do
            if Get(lcoAccount) then begin
                "Balance after Posting" := "Balance after Posting" + ldeAmount;
                "Net Change in Jnl." := "Net Change in Jnl." + ldeAmount2;
                Modify;
            end else begin
                Init;
                "No." := lcoAccount;
                "Balance after Posting" := ldeAmount;
                "Net Change in Jnl." := ldeAmount2;
                Insert;
            end;
    end;

    local procedure SkipBalanceOnPush()
    begin
        LimitEnabled := not SkipBalance;
        RequestOptionsPage.Update;
    end;
}

