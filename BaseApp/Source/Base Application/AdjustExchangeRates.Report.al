#if not CLEAN18
report 595 "Adjust Exchange Rates"
{
    DefaultLayout = RDLC;
    RDLCLayout = './AdjustExchangeRates.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Adjust Exchange Rates';
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "Exch. Rate Adjmt. Reg." = rimd,
                  TableData "VAT Entry" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd,
                  TableData "Detailed Vendor Ledg. Entry" = rimd;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Currency; Currency)
        {
            DataItemTableView = SORTING(Code);
            RequestFilterFields = "Code";
            column(CompanyNameHdr; COMPANYPROPERTY.DisplayName)
            {
            }
            column(TestModeVar; TestMode)
            {
            }
            column(BankAccFiltersVar; BankAccFilters)
            {
            }
            column(CustomerFiltersVar; CustFilters)
            {
            }
            column(VendorFiltersVar; VendFilters)
            {
            }
            column(EndDateVar; Format(EndDate))
            {
            }
            dataitem("Bank Account"; "Bank Account")
            {
                DataItemLink = "Currency Code" = FIELD(Code);
                DataItemTableView = SORTING("Bank Acc. Posting Group");
                RequestFilterFields = "No.";
                column(BankAccNo_Fld; "No.")
                {
                }
                column(BankAccName_Fld; Name)
                {
                }
                column(BankAccCurrencyCode_Fld; "Currency Code")
                {
                }
                column(BankAccFactor_Fld; Round(1 / Currency."Currency Factor", 0.001))
                {
                    DecimalPlaces = 3 : 3;
                }
                column(BankAccBalanceDate_Fld; "Balance at Date")
                {
                }
                column(BankAccBalanceDateLCY_Fld; "Balance at Date (LCY)")
                {
                }
                column(BankAccModBalanceDateLCY_Fld; CurrAdjAmount + "Balance at Date (LCY)")
                {
                }
                column(BankAccGainLoss_Fld; GainOrLoss)
                {
                }
                column(BankAccModDebitAmount_Fld; AdjDebit)
                {
                }
                column(BankAccModCrebitAmount_Fld; AdjCredit)
                {
                }
                column(BATableType_Var; TableType)
                {
                }
                dataitem(BankAccountGroupTotal; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    MaxIteration = 1;

                    trigger OnAfterGetRecord()
                    var
                        BankAccount: Record "Bank Account";
                        GroupTotal: Boolean;
                    begin
                        BankAccount.Copy("Bank Account");
                        if BankAccount.Next = 1 then begin
                            if BankAccount."Bank Acc. Posting Group" <> "Bank Account"."Bank Acc. Posting Group" then
                                GroupTotal := true;
                        end else
                            GroupTotal := true;

                        if GroupTotal then
                            if TotalAdjAmount <> 0 then begin
                                AdjExchRateBufferUpdate(
                                  "Bank Account"."Currency Code", "Bank Account"."Bank Acc. Posting Group",
                                  TotalAdjBase, TotalAdjBaseLCY, TotalAdjAmount, 0, 0, 0, PostingDate, '',
                                  false, ''); // NAVCZ
                                InsertExchRateAdjmtReg(3, "Bank Account"."Bank Acc. Posting Group", "Bank Account"."Currency Code");
                                TotalBankAccountsAdjusted += 1;
                                ResetTempAdjmtBuffer();
                                TotalAdjBase := 0;
                                TotalAdjBaseLCY := 0;
                                TotalAdjAmount := 0;
                            end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    BankAccNo := BankAccNo + 1;
                    Window.Update(1, Round(BankAccNo / BankAccNoTotal * 10000, 1));

                    TempDimSetEntry.Reset();
                    TempDimSetEntry.DeleteAll();
                    TempDimBuf.Reset();
                    TempDimBuf.DeleteAll();

                    CalcFields("Balance at Date", "Balance at Date (LCY)");
                    CurrAdjBase := "Balance at Date";
                    CurrAdjBaseLCY := "Balance at Date (LCY)";
                    CurrAdjAmount :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCYAdjmt(
                          PostingDate, Currency.Code, "Balance at Date", Currency."Currency Factor")) -
                      "Balance at Date (LCY)";

                    // NAVCZ
                    Clear(AdjDebit);
                    Clear(AdjCredit);
                    // NAVCZ

                    if CurrAdjAmount <> 0 then begin
                        PostBankAccAdjmt("Bank Account");

                        TotalAdjBase := TotalAdjBase + CurrAdjBase;
                        TotalAdjBaseLCY := TotalAdjBaseLCY + CurrAdjBaseLCY;
                        TotalAdjAmount := TotalAdjAmount + CurrAdjAmount;
                        Window.Update(4, TotalAdjAmount);
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    // NAVCZ
                    if not AdjBank then
                        CurrReport.Break();
                    TableType := 1;
                    // NAVCZ

                    SetRange("Date Filter", StartDate, EndDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                "Last Date Adjusted" := PostingDate;
                if not TestMode then // NAVCZ
                    Modify();

                "Currency Factor" := CurrExchRate.ExchangeRateAdjmt(PostingDate, Code);

                TempCurrencyToAdjust := Currency;
                TempCurrencyToAdjust.Insert();
            end;

            trigger OnPostDataItem()
            begin
                if (Code = '') and AdjCustVendBank then
                    Error(Text011Err);
            end;

            trigger OnPreDataItem()
            begin
                CheckPostingDate;
                if not (AdjCust or AdjVend or AdjBank) then // NAVCZ
                    CurrReport.Break();

                Window.Open(
                  Text006Txt +
                  Text007Txt +
                  Text008Txt +
                  Text009Txt +
                  Text010Txt);

                CustNoTotal := Customer.Count();
                VendNoTotal := Vendor.Count();
                CopyFilter(Code, "Bank Account"."Currency Code");
                FilterGroup(2);
                "Bank Account".SetFilter("Currency Code", '<>%1', '');
                FilterGroup(0);
                BankAccNoTotal := "Bank Account".Count();
                "Bank Account".Reset();
            end;
        }
        dataitem(Customer; Customer)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            dataitem(CustomerLedgerEntryLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(CLEDocumentType_Fld; CopyStr(Format(CustLedgerEntry."Document Type"), 1, 2))
                {
                }
                column(CLEDocumentNo_Fld; CustLedgerEntry."Document No.")
                {
                }
                column(CLEPostingDate_Fld; Format(CustLedgerEntry."Posting Date"))
                {
                }
                column(CLECurrencyCode_Fld; CustLedgerEntry."Currency Code")
                {
                }
                column(CLEOriginalCurrency_Fld; Round(1 / CustLedgerEntry."Adjusted Currency Factor", 0.001))
                {
                    DecimalPlaces = 3 : 3;
                }
                column(CLEModifiedAmt_Fld; Round(AdjustedFactor, 0.001))
                {
                    DecimalPlaces = 3 : 3;
                }
                column(CLERemainingAmt_Fld; CustLedgerEntry."Remaining Amount")
                {
                }
                column(CLERemainingAmtLCY_Fld; CustLedgerEntry."Remaining Amt. (LCY)")
                {
                }
                column(CLEModRemainingAmtLCY_Fld; CustLedgerEntry."Remaining Amt. (LCY)" + CurrAdjAmount2)
                {
                }
                column(CLEGainLoss_Fld; GainOrLoss)
                {
                }
                column(CLEDebitAmount_Fld; AdjDebit)
                {
                }
                column(CLECreditAmount_Fld; AdjCredit)
                {
                }
                column(CLETableType_Var; TableType)
                {
                }
                dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
                {
                    DataItemTableView = SORTING("Cust. Ledger Entry No.", "Posting Date");

                    trigger OnAfterGetRecord()
                    begin
                        CalcCustRealGainLossAmount(CustLedgerEntry."Entry No.", "Posting Date");  // NAVCZ
                        AdjustCustomerLedgerEntry(CustLedgerEntry, "Posting Date");
                    end;

                    trigger OnPostDataItem()
                    begin
                        // NAVCZ
                        if not SummarizeEntries then
                            HandlePostAdjmt(1);
                        // NAVCZ
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetCurrentKey("Cust. Ledger Entry No.");
                        SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
                        SetFilter("Posting Date", '%1..', CalcDate('<+1D>', PostingDate));

                        CreateCustRealGainLossEntries("Detailed Cust. Ledg. Entry");  // NAVCZ
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempDtldCustLedgEntrySums.DeleteAll();

                    if FirstEntry then begin
                        TempCustLedgerEntry.Find('-');
                        FirstEntry := false
                    end else
                        if TempCustLedgerEntry.Next() = 0 then
                            CurrReport.Break();
                    CustLedgerEntry.Get(TempCustLedgerEntry."Entry No.");
                    AdjustCustomerLedgerEntry(CustLedgerEntry, PostingDate);

                    // NAVCZ
                    Clear(AdjDebit);
                    Clear(AdjCredit);
                    CurrAdjAmount2 := CurrAdjAmount;
                    if CurrAdjAmount2 > 0 then begin
                        GainOrLoss := TextCZ003Txt;
                        AdjCredit := CurrAdjAmount2;
                    end else begin
                        GainOrLoss := TextCZ004Txt;
                        AdjDebit := -CurrAdjAmount2;
                    end;

                    CustLedgerEntry.SetRange("Date Filter", 0D, EndDateReq);
                    CustLedgerEntry.CalcFields(
                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)", "Original Amt. (LCY)",
                      "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
                    // NAVCZ
                end;

                trigger OnPreDataItem()
                begin
                    if not TempCustLedgerEntry.Find('-') then
                        CurrReport.Break();
                    FirstEntry := true;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CustNo := CustNo + 1;
                Window.Update(2, Round(CustNo / CustNoTotal * 10000, 1));

                PrepareTempCustLedgEntry(Customer, TempCustLedgerEntry);

                OnCustomerAfterGetRecordOnAfterFindCustLedgerEntriesToAdjust(TempCustLedgerEntry);
            end;

            trigger OnPostDataItem()
            begin
                if (CustNo <> 0) and (not TestMode) then // NAVCZ
                    if SummarizeEntries then
                        HandlePostAdjmt(1); // Customer
            end;

            trigger OnPreDataItem()
            begin
                if not AdjCust then // NAVCZ
                    CurrReport.Break();

                DtldCustLedgEntry.LockTable();
                CustLedgerEntry.LockTable();

                CustNo := 0;

                if DtldCustLedgEntry.Find('+') then
                    NewEntryNo := DtldCustLedgEntry."Entry No." + 1
                else
                    NewEntryNo := 1;

                Clear(DimMgt);
                TableType := 2;  // NAVCZ
            end;
        }
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            dataitem(VendorLedgerEntryLoop; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(VLEDocumentType_Fld; CopyStr(Format(VendorLedgerEntry."Document Type"), 1, 2))
                {
                }
                column(VLEDocumentNo_Fld; VendorLedgerEntry."Document No.")
                {
                }
                column(VLEPostingDate_Fld; Format(VendorLedgerEntry."Posting Date"))
                {
                }
                column(VLECurrencyCode_Fld; VendorLedgerEntry."Currency Code")
                {
                }
                column(VLEOriginalCurrency_Fld; Round(1 / VendorLedgerEntry."Adjusted Currency Factor", 0.001))
                {
                    DecimalPlaces = 3 : 3;
                }
                column(VLEModifiedAmt_Fld; Round(AdjustedFactor, 0.001))
                {
                    DecimalPlaces = 3 : 3;
                }
                column(VLERemainingAmt_Fld; VendorLedgerEntry."Remaining Amount")
                {
                }
                column(VLERemainingAmtLCY_Fld; VendorLedgerEntry."Remaining Amt. (LCY)")
                {
                }
                column(VLEModRemainingAmtLCY_Fld; VendorLedgerEntry."Remaining Amt. (LCY)" + CurrAdjAmount2)
                {
                }
                column(VLEGainLoss_Fld; GainOrLoss)
                {
                }
                column(VLEDebitAmount_Fld; AdjDebit)
                {
                }
                column(VLECreditAmount_Fld; AdjCredit)
                {
                }
                column(VLETableType_Var; TableType)
                {
                }
                dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                {
                    DataItemTableView = SORTING("Vendor Ledger Entry No.", "Posting Date");

                    trigger OnAfterGetRecord()
                    begin
                        CalcVendRealGainLossAmount(VendorLedgerEntry."Entry No.", "Posting Date");  // NAVCZ

                        AdjustVendorLedgerEntry(VendorLedgerEntry, "Posting Date");
                    end;

                    trigger OnPostDataItem()
                    begin
                        // NAVCZ
                        if not SummarizeEntries then
                            HandlePostAdjmt(2);
                        // NAVCZ
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetCurrentKey("Vendor Ledger Entry No.");
                        SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
                        SetFilter("Posting Date", '%1..', CalcDate('<+1D>', PostingDate));

                        CreateVendRealGainLossEntries("Detailed Vendor Ledg. Entry");  // NAVCZ
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempDtldVendLedgEntrySums.DeleteAll();

                    if FirstEntry then begin
                        TempVendorLedgerEntry.Find('-');
                        FirstEntry := false
                    end else
                        if TempVendorLedgerEntry.Next() = 0 then
                            CurrReport.Break();
                    VendorLedgerEntry.Get(TempVendorLedgerEntry."Entry No.");
                    AdjustVendorLedgerEntry(VendorLedgerEntry, PostingDate);

                    // NAVCZ
                    Clear(AdjDebit);
                    Clear(AdjCredit);
                    CurrAdjAmount2 := CurrAdjAmount;
                    if CurrAdjAmount2 > 0 then begin
                        GainOrLoss := TextCZ003Txt;
                        AdjCredit := CurrAdjAmount2;
                    end else begin
                        GainOrLoss := TextCZ004Txt;
                        AdjDebit := -CurrAdjAmount2;
                    end;

                    VendorLedgerEntry.SetRange("Date Filter", 0D, EndDateReq);
                    VendorLedgerEntry.CalcFields(
                      Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)", "Original Amt. (LCY)",
                      "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");
                    // NAVCZ
                end;

                trigger OnPreDataItem()
                begin
                    if not TempVendorLedgerEntry.Find('-') then
                        CurrReport.Break();
                    FirstEntry := true;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                VendNo := VendNo + 1;
                Window.Update(3, Round(VendNo / VendNoTotal * 10000, 1));

                PrepareTempVendLedgEntry(Vendor, TempVendorLedgerEntry);

                OnVendorAfterGetRecordOnAfterFindVendLedgerEntriesToAdjust(TempVendorLedgerEntry);
            end;

            trigger OnPostDataItem()
            begin
                if (VendNo <> 0) and (not TestMode) then // NAVCZ
                    if SummarizeEntries then
                        HandlePostAdjmt(2); // Vendor
            end;

            trigger OnPreDataItem()
            begin
                if not AdjVend then // NAVCZ
                    CurrReport.Break();

                DtldVendLedgEntry.LockTable();
                VendorLedgerEntry.LockTable();

                VendNo := 0;
                if DtldVendLedgEntry.Find('+') then
                    NewEntryNo := DtldVendLedgEntry."Entry No." + 1
                else
                    NewEntryNo := 1;

                Clear(DimMgt);
                TableType := 3; // NAVCZ
            end;
        }
        dataitem("VAT Posting Setup"; "VAT Posting Setup")
        {
            DataItemTableView = SORTING("VAT Bus. Posting Group", "VAT Prod. Posting Group");

            trigger OnAfterGetRecord()
            begin
                VATEntryNo := VATEntryNo + 1;
                Window.Update(1, 10000 * VATEntryNo div VATEntryNoTotal);

                VATEntry.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                VATEntry.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");

                if "VAT Calculation Type" <> "VAT Calculation Type"::"Sales Tax" then begin
                    AdjustVATEntries(VATEntry.Type::Purchase, false);
                    if (VATEntry2.Amount <> 0) or (VATEntry2."Additional-Currency Amount" <> 0) then begin
                        AdjustVATAccount(
                          GetPurchAccount(false),
                          VATEntry2.Amount, VATEntry2."Additional-Currency Amount",
                          VATEntryTotalBase.Amount, VATEntryTotalBase."Additional-Currency Amount");
                        if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then
                            AdjustVATAccount(
                              GetRevChargeAccount(false),
                              -VATEntry2.Amount, -VATEntry2."Additional-Currency Amount",
                              -VATEntryTotalBase.Amount, -VATEntryTotalBase."Additional-Currency Amount");
                    end;
                    if (VATEntry2."Remaining Unrealized Amount" <> 0) or
                       (VATEntry2."Add.-Curr. Rem. Unreal. Amount" <> 0)
                    then begin
                        TestField("Unrealized VAT Type");
                        AdjustVATAccount(
                          GetPurchAccount(true),
                          VATEntry2."Remaining Unrealized Amount",
                          VATEntry2."Add.-Curr. Rem. Unreal. Amount",
                          VATEntryTotalBase."Remaining Unrealized Amount",
                          VATEntryTotalBase."Add.-Curr. Rem. Unreal. Amount");
                        if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then
                            AdjustVATAccount(
                              GetRevChargeAccount(true),
                              -VATEntry2."Remaining Unrealized Amount",
                              -VATEntry2."Add.-Curr. Rem. Unreal. Amount",
                              -VATEntryTotalBase."Remaining Unrealized Amount",
                              -VATEntryTotalBase."Add.-Curr. Rem. Unreal. Amount");
                    end;

                    AdjustVATEntries(VATEntry.Type::Sale, false);
                    if (VATEntry2.Amount <> 0) or (VATEntry2."Additional-Currency Amount" <> 0) then
                        AdjustVATAccount(
                          GetSalesAccount(false),
                          VATEntry2.Amount, VATEntry2."Additional-Currency Amount",
                          VATEntryTotalBase.Amount, VATEntryTotalBase."Additional-Currency Amount");
                    if (VATEntry2."Remaining Unrealized Amount" <> 0) or
                       (VATEntry2."Add.-Curr. Rem. Unreal. Amount" <> 0)
                    then begin
                        TestField("Unrealized VAT Type");
                        AdjustVATAccount(
                          GetSalesAccount(true),
                          VATEntry2."Remaining Unrealized Amount",
                          VATEntry2."Add.-Curr. Rem. Unreal. Amount",
                          VATEntryTotalBase."Remaining Unrealized Amount",
                          VATEntryTotalBase."Add.-Curr. Rem. Unreal. Amount");
                    end;
                end else begin
                    if TaxJurisdiction.Find('-') then
                        repeat
                            VATEntry.SetRange("Tax Jurisdiction Code", TaxJurisdiction.Code);
                            AdjustVATEntries(VATEntry.Type::Purchase, false);
                            AdjustPurchTax(false);
                            AdjustVATEntries(VATEntry.Type::Purchase, true);
                            AdjustPurchTax(true);
                            AdjustVATEntries(VATEntry.Type::Sale, false);
                            AdjustSalesTax;
                        until TaxJurisdiction.Next() = 0;
                    VATEntry.SetRange("Tax Jurisdiction Code");
                end;
                Clear(VATEntryTotalBase);
            end;

            trigger OnPreDataItem()
            begin
                // NAVCZ
                if TestMode then
                    CurrReport.Break();
                // NAVCZ

                if not AdjGLAcc or
                   (GLSetup."VAT Exchange Rate Adjustment" = GLSetup."VAT Exchange Rate Adjustment"::"No Adjustment")
                then
                    CurrReport.Break();

                VATEntryNoTotal := VATEntry.Count();

                if VATEntryNoTotal = 0 then
                    CurrReport.Break();

                Window.Open(
                  Text012Txt +
                  Text013Txt);

                if not
                   VATEntry.SetCurrentKey(
                     Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date")
                then
                    VATEntry.SetCurrentKey(
                      Type, Closed, "Tax Jurisdiction Code", "Use Tax", "Posting Date");
                VATEntry.SetRange(Closed, false);
                VATEntry.SetRange("Posting Date", StartDate, EndDate);
            end;
        }
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = SORTING("No.") WHERE("Exchange Rate Adjustment" = FILTER("Adjust Amount" .. "Adjust Additional-Currency Amount"));

            trigger OnAfterGetRecord()
            begin
                GLAccNo := GLAccNo + 1;
                Window.Update(1, Round(GLAccNo / GLAccNoTotal * 10000, 1));
                if "Exchange Rate Adjustment" = "Exchange Rate Adjustment"::"No Adjustment" then
                    CurrReport.Skip();

                TempDimSetEntry.Reset();
                TempDimSetEntry.DeleteAll();
                CalcFields("Net Change", "Additional-Currency Net Change");
                case "Exchange Rate Adjustment" of
                    "Exchange Rate Adjustment"::"Adjust Amount":
                        PostGLAccAdjmt(
                          "No.", "Exchange Rate Adjustment"::"Adjust Amount",
                          Round(
                            CurrExchRate2.ExchangeAmtFCYToLCYAdjmt(
                              PostingDate, GLSetup."Additional Reporting Currency",
                              "Additional-Currency Net Change", AddCurrCurrencyFactor) -
                            "Net Change"),
                          "Net Change",
                          "Additional-Currency Net Change");
                    "Exchange Rate Adjustment"::"Adjust Additional-Currency Amount":
                        PostGLAccAdjmt(
                          "No.", "Exchange Rate Adjustment"::"Adjust Additional-Currency Amount",
                          Round(
                            CurrExchRate2.ExchangeAmtLCYToFCY(
                              PostingDate, GLSetup."Additional Reporting Currency",
                              "Net Change", AddCurrCurrencyFactor) -
                            "Additional-Currency Net Change",
                            Currency3."Amount Rounding Precision"),
                          "Net Change",
                          "Additional-Currency Net Change");
                end;
            end;

            trigger OnPostDataItem()
            begin
                if AdjGLAcc then begin
                    PostGLAccAdjmtTotal();
                    TotalGLAccountsAdjusted += 1;
                end;
            end;

            trigger OnPreDataItem()
            begin
                // NAVCZ
                if TestMode then
                    CurrReport.Break();
                // NAVCZ

                if not AdjGLAcc then
                    CurrReport.Break();

                Window.Open(
                  Text014Txt +
                  Text015Txt);

                GLAccNoTotal := Count;
                SetRange("Date Filter", StartDate, EndDate);
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
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies text for the general ledger entries that are created by the batch job. The default text is Exchange Rate Adjmt. of %1 %2, in which %1 is replaced by the currency code and %2 is replaced by the currency amount that is adjusted. For example, Exchange Rate Adjmt. of DEM 38,000.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date on which the general ledger entries are posted. This date is usually the same as the ending date in the Ending Date field.';

                        trigger OnValidate()
                        begin
                            CheckPostingDate;
                        end;
                    }
                    field(DocumentNo; PostingDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the document number that will appear on the general ledger entries that are created by the batch job.';
                    }
                    field(AdjCustVendBank; AdjCustVendBank)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Customer, Vendor and Bank Accounts';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to adjust customer, vendor, and bank accounts for currency fluctuations.';
                        Visible = false;
                    }
                    field(AdjCust; AdjCust)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Customer';
                        ToolTip = 'Specifies if customer''s entries have to be adjusted.';
                    }
                    field(AdjVend; AdjVend)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Vendor';
                        ToolTip = 'Specifies if vendor''s entries have to be adjusted.';
                    }
                    field(AdjBank; AdjBank)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Bank Accounts';
                        ToolTip = 'Specifies if bank accounts has to be adjusted.';
                    }
                    field(AdjGLAcc; AdjGLAcc)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Adjust G/L Accounts for Add.-Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to post in an additional reporting currency and adjust general ledger accounts for currency fluctuations between LCY and the additional reporting currency.';
                    }
                    field(TestMode; TestMode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only test run';
                        ToolTip = 'Specifies only for test run. The Entries will not be posted.';
                    }
                    field(SummarizeEntries; SummarizeEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sumarize Entries';
                        ToolTip = 'Specifies if the etries will be summarized';

                        trigger OnValidate()
                        begin
                            if not SummarizeEntries then
                                PostingDescription := TextCZ001Txt
                            else
                                PostingDescription := TextCZ002Txt;
                        end;
                    }
                    group(Dimension)
                    {
                        Caption = 'Dimension';
                        field(DimMoveType; DimMoveType)
                        {
                            ApplicationArea = Dimensions;
                            Caption = 'Dimension Move';
                            OptionCaption = 'No move,Source Entry,By G/L Account';
                            ToolTip = 'Specifies dimension move into new entries - no move, move for source entry or move by G/L account.';
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
#if not CLEAN19
            OnBeforeOpenPage(AdjCustVendBank, AdjGLAcc, PostingDocNo);
#endif
            if PostingDescription = '' then
                // NAVCZ
                PostingDescription := TextCZ002Txt;
            if not (AdjCust or AdjVend or AdjBank or AdjGLAcc) then begin
                AdjCust := true;
                AdjVend := true;
                AdjBank := true;
            end;
            TestMode := true;
            if not SummarizeEntries then
                PostingDescription := TextCZ001Txt;
            // NAVCZ
        end;
    }

    labels
    {
        ReportCaption = 'Adjust Exchange Rates';
        DateCaption = 'To date';
        PageCaption = 'Page';
        TestModeCaption = 'Test Mode';
        TotalCaption = 'Total';
        BankAccNoCaption = 'No';
        BankAccNameCaption = 'Name';
        BankAccCurrencyCodeCaption = 'Currency Code';
        BankAccFactorCaption = 'Factor';
        BankAccBalToDateCaption = 'Balance to Date';
        BankAccBalToDateLCYCaption = 'Balance to Date (LCY)';
        BankAccModBaltoDateLCYCaption = 'Mod. Bal. to Date (LCY)';
        GainLossCaption = 'Gain / Loss';
        ModAmountDebitCaption = 'Mod. Debit Amount (LCY)';
        ModAmountCreditCaption = 'Mod. Credit Amount (LCY)';
        DocumentTypeCaption = 'Type';
        DocumentNoCaption = 'Document No';
        PostingDateCaption = 'Post. Date';
        CurrencyCodeCaption = 'Currency Code';
        OriginalCurrencyCaption = 'Original Factor';
        ModifiedAmtCaption = 'Modified Factor';
        RemainingAmtCaption = 'Remaining Amount';
        RemainingAmtLCYCaption = 'Remaining Amount (LCY)';
        ModRemainingAmtLCYCaption = 'Mod. Remaining Amount (LCY)';
        BankAccountTableCaption = 'Bank Account';
        CustLdgEntryTableCaption = 'Customer Ledger Entry';
        VendLdgEntryTableCaption = 'Vendor Ledger Entry';
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

    trigger OnPostReport()
    begin
        if GenJnlPostLine.IsGLEntryInconsistent() then
            GenJnlPostLine.ShowInconsistentEntries();

        if not TestMode then // NAVCZ
            Commit();

        UpdateAnalysisView.UpdateAll(0, true);

        if not TestMode then // NAVCZ
            if TotalCustomersAdjusted + TotalVendorsAdjusted + TotalBankAccountsAdjusted + TotalGLAccountsAdjusted < 1 then
                Message(NothingToAdjustMsg)
            else
                Message(RatesAdjustedMsg);

        OnAfterPostReport(ExchRateAdjReg, PostingDate);
    end;

    trigger OnPreReport()
    begin
        if EndDateReq = 0D then
            EndDate := DMY2Date(31, 12, 9999)
        else
            EndDate := EndDateReq;
        if PostingDocNo = '' then
            Error(Text000Err);
        if not AdjCustVendBank and AdjGLAcc then
            if not Confirm(Text001Txt + Text004Txt, false) then
                Error(Text005Err);

        SourceCodeSetup.Get();

        if ExchRateAdjReg.FindLast then
            ExchRateAdjReg.Init();

        GLSetup.Get();

        if AdjGLAcc then begin
            GLSetup.TestField("Additional Reporting Currency");

            Currency3.Get(GLSetup."Additional Reporting Currency");
            "G/L Account".Get(Currency3.GetRealizedGLGainsAccount);
            "G/L Account".TestField("Exchange Rate Adjustment", "G/L Account"."Exchange Rate Adjustment"::"No Adjustment");

            "G/L Account".Get(Currency3.GetRealizedGLLossesAccount);
            "G/L Account".TestField("Exchange Rate Adjustment", "G/L Account"."Exchange Rate Adjustment"::"No Adjustment");

            with VATPostingSetup2 do
                if Find('-') then
                    repeat
                        if "VAT Calculation Type" <> "VAT Calculation Type"::"Sales Tax" then begin
                            CheckExchRateAdjustment(
                              "Purchase VAT Account", TableCaption(), FieldCaption("Purchase VAT Account"));
                            CheckExchRateAdjustment(
                              "Reverse Chrg. VAT Acc.", TableCaption(), FieldCaption("Reverse Chrg. VAT Acc."));
                            CheckExchRateAdjustment(
                              "Purch. VAT Unreal. Account", TableCaption(), FieldCaption("Purch. VAT Unreal. Account"));
                            CheckExchRateAdjustment(
                              "Reverse Chrg. VAT Unreal. Acc.", TableCaption(), FieldCaption("Reverse Chrg. VAT Unreal. Acc."));
                            CheckExchRateAdjustment(
                              "Sales VAT Account", TableCaption(), FieldCaption("Sales VAT Account"));
                            CheckExchRateAdjustment(
                              "Sales VAT Unreal. Account", TableCaption(), FieldCaption("Sales VAT Unreal. Account"));
                        end;
                    until Next() = 0;

            with TaxJurisdiction2 do
                if Find('-') then
                    repeat
                        CheckExchRateAdjustment(
                          "Tax Account (Purchases)", TableCaption, FieldCaption("Tax Account (Purchases)"));
                        CheckExchRateAdjustment(
                          "Reverse Charge (Purchases)", TableCaption, FieldCaption("Reverse Charge (Purchases)"));
                        CheckExchRateAdjustment(
                          "Unreal. Tax Acc. (Purchases)", TableCaption, FieldCaption("Unreal. Tax Acc. (Purchases)"));
                        CheckExchRateAdjustment(
                          "Unreal. Rev. Charge (Purch.)", TableCaption, FieldCaption("Unreal. Rev. Charge (Purch.)"));
                        CheckExchRateAdjustment(
                          "Tax Account (Sales)", TableCaption, FieldCaption("Tax Account (Sales)"));
                        CheckExchRateAdjustment(
                          "Unreal. Tax Acc. (Sales)", TableCaption, FieldCaption("Unreal. Tax Acc. (Sales)"));
                    until Next() = 0;

            AddCurrCurrencyFactor :=
              CurrExchRate2.ExchangeRateAdjmt(PostingDate, GLSetup."Additional Reporting Currency");
        end;

        // NAVCZ
        BankAccFilters := "Bank Account".GetFilters;
        CustFilters := Customer.GetFilters;
        VendFilters := Vendor.GetFilters;
        // NAVCZ
    end;

    var
        Text000Err: Label 'Document No. must be entered.';
        Text001Txt: Label 'Do you want to adjust general ledger entries for currency fluctuations without adjusting customer, vendor and bank ledger entries? This may result in incorrect currency adjustments to payables, receivables and bank accounts.\\ ';
        Text004Txt: Label 'Do you wish to continue?';
        Text005Err: Label 'The adjustment of exchange rates has been canceled.';
        Text006Txt: Label 'Adjusting exchange rates...\\';
        Text007Txt: Label 'Bank Account    @1@@@@@@@@@@@@@\\';
        Text008Txt: Label 'Customer        @2@@@@@@@@@@@@@\';
        Text009Txt: Label 'Vendor          @3@@@@@@@@@@@@@\';
        Text010Txt: Label 'Adjustment      #4#############';
        Text011Err: Label 'No currencies have been found.';
        Text012Txt: Label 'Adjusting VAT Entries...\\';
        Text013Txt: Label 'VAT Entry    @1@@@@@@@@@@@@@';
        Text014Txt: Label 'Adjusting general ledger...\\';
        Text015Txt: Label 'G/L Account    @1@@@@@@@@@@@@@';
        Text017Err: Label '%1 on %2 %3 must be %4. When this %2 is used in %5, the exchange rate adjustment is defined in the %6 field in the %7. %2 %3 is used in the %8 field in the %5. ';
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
        TempDtldCustLedgEntrySums: Record "Detailed Cust. Ledg. Entry" temporary;
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TempDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
        TempDtldVendLedgEntrySums: Record "Detailed Vendor Ledg. Entry" temporary;
        ExchRateAdjReg: Record "Exch. Rate Adjmt. Reg.";
        SourceCodeSetup: Record "Source Code Setup";
        TempAdjExchRateBuffer: Record "Adjust Exchange Rate Buffer" temporary;
        TempAdjExchRateBuffer2: Record "Adjust Exchange Rate Buffer" temporary;
        TempCurrencyToAdjust: Record Currency temporary;
        Currency3: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        CurrExchRate2: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
        VATEntryTotalBase: Record "VAT Entry";
        TaxJurisdiction: Record "Tax Jurisdiction";
        VATPostingSetup2: Record "VAT Posting Setup";
        TaxJurisdiction2: Record "Tax Jurisdiction";
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        TmpDtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry" temporary;
        TmpDtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry" temporary;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        DimMgt: Codeunit DimensionManagement;
        DimBufMgt: Codeunit "Dimension Buffer Management";
        Window: Dialog;
        TotalAdjBase: Decimal;
        TotalAdjBaseLCY: Decimal;
        TotalAdjAmount: Decimal;
        GainsAmount: Decimal;
        LossesAmount: Decimal;
        PostingDate: Date;
        PostingDescription: Text[100];
        CurrAdjBase: Decimal;
        CurrAdjBaseLCY: Decimal;
        CurrAdjAmount: Decimal;
        CurrAdjAmount2: Decimal;
        CustNo: Decimal;
        CustNoTotal: Decimal;
        VendNo: Decimal;
        VendNoTotal: Decimal;
        BankAccNo: Decimal;
        BankAccNoTotal: Decimal;
        GLAccNo: Decimal;
        GLAccNoTotal: Decimal;
        GLAmtTotal: Decimal;
        GLAddCurrAmtTotal: Decimal;
        GLNetChangeTotal: Decimal;
        GLAddCurrNetChangeTotal: Decimal;
        GLNetChangeBase: Decimal;
        GLAddCurrNetChangeBase: Decimal;
        PostingDocNo: Code[20];
        StartDate: Date;
        EndDate: Date;
        EndDateReq: Date;
        Correction: Boolean;
        HideUI: Boolean;
        OK: Boolean;
        AdjCustVendBank: Boolean;
        AdjGLAcc: Boolean;
        AddCurrCurrencyFactor: Decimal;
        VATEntryNoTotal: Decimal;
        VATEntryNo: Decimal;
        NewEntryNo: Integer;
        Text018Err: Label 'This posting date cannot be entered because it does not occur within the adjustment period. Reenter the posting date.';
        FirstEntry: Boolean;
        MaxAdjExchRateBufIndex: Integer;
        RatesAdjustedMsg: Label 'One or more currency exchange rates have been adjusted.';
        NothingToAdjustMsg: Label 'There is nothing to adjust.';
        TotalBankAccountsAdjusted: Integer;
        TotalCustomersAdjusted: Integer;
        TotalVendorsAdjusted: Integer;
        TotalGLAccountsAdjusted: Integer;
        AdjCust: Boolean;
        AdjVend: Boolean;
        AdjBank: Boolean;
        TestMode: Boolean;
        SummarizeEntries: Boolean;
        GainOrLoss: Text[30];
        AdjDebit: Decimal;
        AdjCredit: Decimal;
        AdjustedFactor: Decimal;
        RealGainLossAmt: Decimal;
        TableType: Integer;
        DimMoveType: Option "No move","Source Entry","By G/L Account";
        BankAccFilters: Text;
        CustFilters: Text;
        VendFilters: Text;
        TextCZ001Txt: Label 'Exchange Rate Adjmt. of %1 %2 %3 %4';
        TextCZ002Txt: Label 'Exch. Rate Adj. of %1 %2';
        TextCZ003Txt: Label 'Gain';
        TextCZ004Txt: Label 'Loss';

    local procedure PostAdjmt(GLAccNo: Code[20]; PostingAmount: Decimal; AdjBase2: Decimal; CurrencyCode2: Code[10]; var DimSetEntry: Record "Dimension Set Entry"; PostingDate2: Date; ICCode: Code[20]) TransactionNo: Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if PostingAmount = 0 then
            exit;

        GenJnlLine.Init();
        GenJnlLine.Validate("Posting Date", PostingDate2);
        GenJnlLine."Document No." := PostingDocNo;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", GLAccNo);
        // NAVCZ
        GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
        GenJnlLine."Gen. Bus. Posting Group" := '';
        GenJnlLine."Gen. Prod. Posting Group" := '';
        GenJnlLine."VAT Bus. Posting Group" := '';
        GenJnlLine."VAT Prod. Posting Group" := '';
        // Description := PADSTR(STRSUBSTNO(PostingDescription,CurrencyCode2,AdjBase2),MAXSTRLEN(Description));
        if SummarizeEntries then
            GenJnlLine.Description := CopyStr(StrSubstNo(PostingDescription, CurrencyCode2, AdjBase2), 1, MaxStrLen(GenJnlLine.Description))
        else
            GenJnlLine.Description := CopyStr(StrSubstNo(PostingDescription, CurrencyCode2, AdjBase2,
                  TempAdjExchRateBuffer2."Document Type", TempAdjExchRateBuffer2."Document No."), 1, MaxStrLen(GenJnlLine.Description));
        // NAVCZ
        GenJnlLine.Validate(Amount, PostingAmount);
        GenJnlLine."Source Currency Code" := CurrencyCode2;
        GenJnlLine."IC Partner Code" := ICCode;
        if CurrencyCode2 = GLSetup."Additional Reporting Currency" then
            GenJnlLine."Source Currency Amount" := 0;
        GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
        GenJnlLine."System-Created Entry" := true;

        TransactionNo := PostGenJnlLine(GenJnlLine, DimSetEntry);
    end;

    local procedure PostBankAccAdjmt(BankAccount: Record "Bank Account")
    var
        GenJnlLine: Record "Gen. Journal Line";
        AccNo: Code[20];
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine."Document No." := PostingDocNo;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Bank Account";
        GenJnlLine.Validate("Account No.", BankAccount."No.");
        GenJnlLine.Description := PadStr(StrSubstNo(PostingDescription, Currency.Code, CurrAdjBase), MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate(Amount, 0);
        GenJnlLine."Amount (LCY)" := CurrAdjAmount;
        GenJnlLine."Source Currency Code" := Currency.Code;
        if Currency.Code = GLSetup."Additional Reporting Currency" then
            GenJnlLine."Source Currency Amount" := 0;
        GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
        GenJnlLine."System-Created Entry" := true;
        GetJnlLineDefDim(GenJnlLine, TempDimSetEntry);
        CopyDimSetEntryToDimBuf(TempDimSetEntry, TempDimBuf);
        if not TestMode then  // NAVCZ
            PostGenJnlLine(GenJnlLine, TempDimSetEntry);

        // NAVCZ
        if CurrAdjAmount > 0 then begin
            GainOrLoss := TextCZ003Txt;
            AdjCredit := CurrAdjAmount;
        end else begin
            GainOrLoss := TextCZ004Txt;
            AdjDebit := -CurrAdjAmount;
        end;
        // NAVCZ

        if (CurrAdjAmount <> 0) and (not TestMode) then begin // NAVCZ
            GetDimSetEntry(GetDimCombID(TempDimBuf), TempDimSetEntry);
            if CurrAdjAmount > 0 then
                AccNo := GetRealizedGainsAccount(Currency)
            else
                AccNo := GetRealizedLossesAccount(Currency);
            PostAdjmt(
                AccNo, -CurrAdjAmount, CurrAdjBase, BankAccount."Currency Code", TempDimSetEntry, PostingDate, '');
        end;
    end;

    local procedure GetRealizedGainsAccount(Currency: Record Currency) AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRealizedGainsAccount(Currency, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        exit(Currency.GetRealizedGainsAccount());
    end;

    local procedure GetRealizedLossesAccount(Currency: Record Currency) AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRealizedLossesAccount(Currency, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        exit(Currency.GetRealizedLossesAccount());
    end;

    local procedure PostCustAdjmt(AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var TempDimSetEntry: Record "Dimension Set Entry" temporary)
    var
        CustPostingGr: Record "Customer Posting Group";
    begin
        OnBeforePostCustAdjmt(AdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry, TempAdjExchRateBuffer);
        CustPostingGr.Get(TempAdjExchRateBuffer."Posting Group");
        // NAVCZ
        TempDtldCVLedgEntryBuf."Transaction No." :=
            PostAdjmt(
                AdjExchRateBuffer."Initial G/L Account No.", AdjExchRateBuffer.AdjAmount,
                AdjExchRateBuffer.AdjBase, AdjExchRateBuffer."Currency Code", TempDimSetEntry,
                AdjExchRateBuffer."Posting Date", AdjExchRateBuffer."IC Partner Code");
        // NAVCZ
        if TempDtldCVLedgEntryBuf.Insert() then;
        InsertExchRateAdjmtReg(1, AdjExchRateBuffer."Posting Group", AdjExchRateBuffer."Currency Code");
        TotalCustomersAdjusted += 1;
    end;

    local procedure PostVendAdjmt(AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var TempDimSetEntry: Record "Dimension Set Entry" temporary)
    var
        VendPostingGr: Record "Vendor Posting Group";
    begin
        OnBeforePostVendAdjmt(AdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry, TempAdjExchRateBuffer);
        VendPostingGr.Get(TempAdjExchRateBuffer."Posting Group");
        // NAVCZ
        TempDtldCVLedgEntryBuf."Transaction No." :=
            PostAdjmt(
                AdjExchRateBuffer."Initial G/L Account No.", AdjExchRateBuffer.AdjAmount,
                AdjExchRateBuffer.AdjBase, AdjExchRateBuffer."Currency Code", TempDimSetEntry,
                AdjExchRateBuffer."Posting Date", AdjExchRateBuffer."IC Partner Code");
        // NAVCZ
        if TempDtldCVLedgEntryBuf.Insert() then;
        InsertExchRateAdjmtReg(2, AdjExchRateBuffer."Posting Group", AdjExchRateBuffer."Currency Code");
        TotalVendorsAdjusted += 1;
    end;

    local procedure GetDimSetEntry(EntryNo: Integer; var TempDimSetEntry: Record "Dimension Set Entry" temporary)
    begin
        TempDimSetEntry.Reset();
        TempDimSetEntry.DeleteAll();
        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
        DimBufMgt.GetDimensions(EntryNo, TempDimBuf);
        DimMgt.CopyDimBufToDimSetEntry(TempDimBuf, TempDimSetEntry);
    end;

    local procedure InsertExchRateAdjmtReg(AdjustAccType: Integer; PostingGrCode: Code[20]; CurrencyCode: Code[10])
    begin
        // NAVCZ
        if TestMode then
            exit;
        // NAVCZ

        if TempCurrencyToAdjust.Code <> CurrencyCode then
            TempCurrencyToAdjust.Get(CurrencyCode);

        with ExchRateAdjReg do begin
            "No." := "No." + 1;
            "Creation Date" := PostingDate;
            "Account Type" := AdjustAccType;
            "Posting Group" := PostingGrCode;
            "Currency Code" := TempCurrencyToAdjust.Code;
            "Currency Factor" := TempCurrencyToAdjust."Currency Factor";
            "Adjusted Base" := TempAdjExchRateBuffer.AdjBase;
            "Adjusted Base (LCY)" := TempAdjExchRateBuffer.AdjBaseLCY;
            "Adjusted Amt. (LCY)" := TempAdjExchRateBuffer.AdjAmount;
            Insert;
        end;
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
        AdjCustVendBank := NewAdjCustVendBank;
        AdjGLAcc := NewAdjGLAcc;
    end;

    local procedure AdjExchRateBufferUpdate(CurrencyCode2: Code[10]; PostingGroup2: Code[20]; AdjBase2: Decimal; AdjBaseLCY2: Decimal; AdjAmount2: Decimal; GainsAmount2: Decimal; LossesAmount2: Decimal; DimEntryNo: Integer; Postingdate2: Date; ICCode: Code[20]; Advance: Boolean; InitialGLAccNo: Code[20]): Integer
    begin
        TempAdjExchRateBuffer.Init();
        OK := TempAdjExchRateBuffer.Get(CurrencyCode2, PostingGroup2, DimEntryNo, Postingdate2, ICCode, Advance, InitialGLAccNo); // NAVCZ

        TempAdjExchRateBuffer.AdjBase += AdjBase2;
        TempAdjExchRateBuffer.AdjBaseLCY += AdjBaseLCY2;
        TempAdjExchRateBuffer.AdjAmount += AdjAmount2;
        TempAdjExchRateBuffer.TotalGainsAmount += GainsAmount2;
        TempAdjExchRateBuffer.TotalLossesAmount += LossesAmount2;

        if not OK then begin
            TempAdjExchRateBuffer."Currency Code" := CurrencyCode2;
            TempAdjExchRateBuffer."Posting Group" := PostingGroup2;
            TempAdjExchRateBuffer."Dimension Entry No." := DimEntryNo;
            TempAdjExchRateBuffer."Posting Date" := Postingdate2;
            TempAdjExchRateBuffer."IC Partner Code" := ICCode;
            MaxAdjExchRateBufIndex += 1;
            TempAdjExchRateBuffer.Index := MaxAdjExchRateBufIndex;
            // NAVCZ
            TempAdjExchRateBuffer.Advance := Advance;
            TempAdjExchRateBuffer."Initial G/L Account No." := InitialGLAccNo;
            // NAVCZ
            TempAdjExchRateBuffer.Insert();
        end else
            TempAdjExchRateBuffer.Modify();

        exit(TempAdjExchRateBuffer.Index);
    end;

    local procedure AdjExchRateBufferUpdateUnrealGain(CurrencyCode2: Code[10]; PostingGroup2: Code[20]; AdjBase2: Decimal; AdjBaseLCY2: Decimal; AdjAmount2: Decimal; DimEntryNo: Integer; Postingdate2: Date; ICCode: Code[20]; Advance: Boolean; InitialGLAccNo: Code[20]): Integer
    var
        AdjExchRateBufIndex: Integer;
    begin
        // NAVCZ
        AdjExchRateBufferUpdate(
          CurrencyCode2, PostingGroup2, AdjBase2, AdjBaseLCY2, AdjAmount2,
          0, 0, DimEntryNo, Postingdate2, ICCode, Advance, InitialGLAccNo);

        GainsAmount := -RealGainLossAmt;
        TotalAdjAmount := TotalAdjAmount + GainsAmount;
        AdjExchRateBufferUpdate(
          CurrencyCode2, PostingGroup2, AdjBase2, AdjBaseLCY2, 0,
          GainsAmount, 0, DimEntryNo, Postingdate2, ICCode, Advance, InitialGLAccNo);

        LossesAmount := CurrAdjAmount - GainsAmount;
        TotalAdjAmount := TotalAdjAmount + LossesAmount;
        AdjExchRateBufIndex :=
          AdjExchRateBufferUpdate(
            CurrencyCode2, PostingGroup2, AdjBase2, AdjBaseLCY2, 0,
            0, LossesAmount, DimEntryNo, Postingdate2, ICCode, Advance, InitialGLAccNo);

        exit(AdjExchRateBufIndex);
    end;

    local procedure AdjExchRateBufferUpdateUnrealLoss(CurrencyCode2: Code[10]; PostingGroup2: Code[20]; AdjBase2: Decimal; AdjBaseLCY2: Decimal; AdjAmount2: Decimal; DimEntryNo: Integer; Postingdate2: Date; ICCode: Code[20]; Advance: Boolean; InitialGLAccNo: Code[20]): Integer
    var
        AdjExchRateBufIndex: Integer;
    begin
        // NAVCZ
        AdjExchRateBufferUpdate(
          CurrencyCode2, PostingGroup2, AdjBase2, AdjBaseLCY2, AdjAmount2,
          0, 0, DimEntryNo, Postingdate2, ICCode, Advance, InitialGLAccNo);

        LossesAmount := -RealGainLossAmt;
        TotalAdjAmount := TotalAdjAmount + LossesAmount;
        AdjExchRateBufferUpdate(
          CurrencyCode2, PostingGroup2, AdjBase2, AdjBaseLCY2, 0,
          0, LossesAmount, DimEntryNo, Postingdate2, ICCode, Advance, InitialGLAccNo);

        GainsAmount := CurrAdjAmount - LossesAmount;
        TotalAdjAmount := TotalAdjAmount + GainsAmount;
        AdjExchRateBufIndex :=
          AdjExchRateBufferUpdate(
            CurrencyCode2, PostingGroup2, AdjBase2, AdjBaseLCY2, 0,
            GainsAmount, 0, DimEntryNo, Postingdate2, ICCode, Advance, InitialGLAccNo);

        exit(AdjExchRateBufIndex);
    end;

    local procedure HandlePostAdjmt(AdjustAccType: Integer)
    var
        TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary;
    begin
        SummarizeExchRateAdjmtBuffer(TempAdjExchRateBuffer, TempAdjExchRateBuffer2);

        // Post per posting group and per currency
        if TempAdjExchRateBuffer2.Find('-') then
            repeat
                TempAdjExchRateBuffer.SetRange("Currency Code", TempAdjExchRateBuffer2."Currency Code");
                TempAdjExchRateBuffer.SetRange("Dimension Entry No.", TempAdjExchRateBuffer2."Dimension Entry No.");
                TempAdjExchRateBuffer.SetRange("Posting Date", TempAdjExchRateBuffer2."Posting Date");
                TempAdjExchRateBuffer.SetRange("IC Partner Code", TempAdjExchRateBuffer2."IC Partner Code");
                TempAdjExchRateBuffer.SetRange("Initial G/L Account No.", TempAdjExchRateBuffer2."Initial G/L Account No."); // NAVCZ
                TempAdjExchRateBuffer.Find('-');

                GetDimSetEntry(TempAdjExchRateBuffer."Dimension Entry No.", TempDimSetEntry);
                repeat
                    TempDtldCVLedgEntryBuf.Init();
                    TempDtldCVLedgEntryBuf."Entry No." := TempAdjExchRateBuffer.Index;
                    if TempAdjExchRateBuffer.AdjAmount <> 0 then
                        case AdjustAccType of
                            1: // Customer
                                PostCustAdjmt(TempAdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry);
                            2: // Vendor
                                PostVendAdjmt(TempAdjExchRateBuffer, TempDtldCVLedgEntryBuf, TempDimSetEntry);
                        end;
                until TempAdjExchRateBuffer.Next() = 0;

                TempCurrencyToAdjust.Get(TempAdjExchRateBuffer2."Currency Code");
                if TempAdjExchRateBuffer2.TotalGainsAmount <> 0 then
                    PostAdjmt(
                        TempCurrencyToAdjust.GetUnrealizedGainsAccount(),
                        -TempAdjExchRateBuffer2.TotalGainsAmount, -TempAdjExchRateBuffer2.AdjBase,
                        TempAdjExchRateBuffer2."Currency Code", TempDimSetEntry,
                        TempAdjExchRateBuffer2."Posting Date", TempAdjExchRateBuffer2."IC Partner Code");
                if TempAdjExchRateBuffer2.TotalLossesAmount <> 0 then
                    PostAdjmt(
                        TempCurrencyToAdjust.GetUnrealizedLossesAccount(),
                        -TempAdjExchRateBuffer2.TotalLossesAmount, -TempAdjExchRateBuffer2.AdjBase,
                        TempAdjExchRateBuffer2."Currency Code", TempDimSetEntry,
                        TempAdjExchRateBuffer2."Posting Date", TempAdjExchRateBuffer2."IC Partner Code");
            until TempAdjExchRateBuffer2.Next() = 0;

        case AdjustAccType of
            1: // Customer
                InsertCustLedgEntries(TempDtldCustLedgEntry, TempDtldCVLedgEntryBuf);
            2: // Vendor
                InsertVendLedgEntries(TempDtldVendLedgEntry, TempDtldCVLedgEntryBuf);
        end;

        ResetTempAdjmtBuffer();
        ResetTempAdjmtBuffer2();

        TempDtldCustLedgEntry.Reset();
        TempDtldCustLedgEntry.DeleteAll();
        TempDtldVendLedgEntry.Reset();
        TempDtldVendLedgEntry.DeleteAll();
    end;

    local procedure SummarizeExchRateAdjmtBuffer(var TempAdjExchRateBuffer: Record "Adjust Exchange Rate Buffer" temporary; var TempAdjExchRateBuffer2: Record "Adjust Exchange Rate Buffer" temporary)
    begin
        if TempAdjExchRateBuffer.Find('-') then
            // Summarize per currency and dimension combination
            repeat
                TempAdjExchRateBuffer2.Init();
                OK :=
                  TempAdjExchRateBuffer2.Get(
                    TempAdjExchRateBuffer."Currency Code",
                    '',
                    TempAdjExchRateBuffer."Dimension Entry No.",
                    TempAdjExchRateBuffer."Posting Date",
                    TempAdjExchRateBuffer."IC Partner Code",
                    // NAVCZ
                    TempAdjExchRateBuffer.Advance,
                    TempAdjExchRateBuffer."Initial G/L Account No.");
                // NAVCZ

                TempAdjExchRateBuffer2.AdjBase += TempAdjExchRateBuffer.AdjBase;
                TempAdjExchRateBuffer2.TotalGainsAmount += TempAdjExchRateBuffer.TotalGainsAmount;
                TempAdjExchRateBuffer2.TotalLossesAmount += TempAdjExchRateBuffer.TotalLossesAmount;
                TempAdjExchRateBuffer2."Document Type" := TempAdjExchRateBuffer."Document Type"; // NAVCZ
                TempAdjExchRateBuffer2."Document No." := TempAdjExchRateBuffer."Document No."; // NAVCZ
                if not OK then begin
                    TempAdjExchRateBuffer2."Currency Code" := TempAdjExchRateBuffer."Currency Code";
                    TempAdjExchRateBuffer2."Dimension Entry No." := TempAdjExchRateBuffer."Dimension Entry No.";
                    TempAdjExchRateBuffer2."Posting Date" := TempAdjExchRateBuffer."Posting Date";
                    TempAdjExchRateBuffer2."IC Partner Code" := TempAdjExchRateBuffer."IC Partner Code";
                    TempAdjExchRateBuffer2."Initial G/L Account No." := TempAdjExchRateBuffer."Initial G/L Account No."; // NAVCZ
                    TempAdjExchRateBuffer2.Insert();
                end else
                    TempAdjExchRateBuffer2.Modify();
            until TempAdjExchRateBuffer.Next() = 0;
    end;

    local procedure InsertCustLedgEntries(var TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary)
    var
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        GLEntry.GetLastEntry(LastEntryNo, LastTransactionNo);

        if TempDtldCustLedgEntry.Find('-') then
            repeat
                if TempDtldCVLedgEntryBuf.Get(TempDtldCustLedgEntry."Transaction No.") then
                    TempDtldCustLedgEntry."Transaction No." := TempDtldCVLedgEntryBuf."Transaction No."
                else
                    TempDtldCustLedgEntry."Transaction No." := LastTransactionNo;
                DtldCustLedgEntry2 := TempDtldCustLedgEntry;
                if not TestMode then  // NAVCZ
                    DtldCustLedgEntry2.Insert(true);
            until TempDtldCustLedgEntry.Next() = 0;
    end;

    local procedure InsertVendLedgEntries(var TempDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary)
    var
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        GLEntry.GetLastEntry(LastEntryNo, LastTransactionNo);

        if TempDtldVendLedgEntry.Find('-') then
            repeat
                if TempDtldCVLedgEntryBuf.Get(TempDtldVendLedgEntry."Transaction No.") then
                    TempDtldVendLedgEntry."Transaction No." := TempDtldCVLedgEntryBuf."Transaction No."
                else
                    TempDtldVendLedgEntry."Transaction No." := LastTransactionNo;
                DtldVendLedgEntry2 := TempDtldVendLedgEntry;
                if not TestMode then  // NAVCZ
                    DtldVendLedgEntry2.Insert(true);
            until TempDtldVendLedgEntry.Next() = 0;
    end;

    local procedure PrepareTempCustLedgEntry(Customer: Record Customer; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        TempCustLedgerEntry.DeleteAll();

        Currency.CopyFilter(Code, CustLedgerEntry2."Currency Code");
        CustLedgerEntry2.FilterGroup(2);
        CustLedgerEntry2.SetFilter("Currency Code", '<>%1', '');
        CustLedgerEntry2.FilterGroup(0);

        DtldCustLedgEntry2.Reset();
        DtldCustLedgEntry2.SetCurrentKey("Customer No.", "Posting Date", "Entry Type");
        DtldCustLedgEntry2.SetRange("Customer No.", Customer."No.");
        DtldCustLedgEntry2.SetRange("Posting Date", CalcDate('<+1D>', EndDate), DMY2Date(31, 12, 9999));
        if DtldCustLedgEntry2.Find('-') then
            repeat
                CustLedgerEntry2."Entry No." := DtldCustLedgEntry2."Cust. Ledger Entry No.";
                if CustLedgerEntry2.Find('=') then
                    if (CustLedgerEntry2."Posting Date" >= StartDate) and
                        (CustLedgerEntry2."Posting Date" <= EndDate)
                    then begin
                        TempCustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No.";
                        if TempCustLedgerEntry.Insert() then;
                    end;
            until DtldCustLedgEntry2.Next() = 0;

        CustLedgerEntry2.SetCurrentKey("Customer No.", Open);
        CustLedgerEntry2.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry2.SetRange(Open, true);
        CustLedgerEntry2.SetRange("Posting Date", 0D, EndDate);
        if CustLedgerEntry2.Find('-') then
            repeat
                TempCustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No.";
                if TempCustLedgerEntry.Insert() then;
            until CustLedgerEntry2.Next() = 0;
        CustLedgerEntry2.Reset();
    end;

    local procedure PrepareTempVendLedgEntry(Vendor: Record Vendor; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary);
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        TempVendorLedgerEntry.DeleteAll();

        Currency.CopyFilter(Code, VendorLedgerEntry2."Currency Code");
        VendorLedgerEntry2.FilterGroup(2);
        VendorLedgerEntry2.SetFilter("Currency Code", '<>%1', '');
        VendorLedgerEntry2.FilterGroup(0);

        DtldVendLedgEntry2.Reset();
        DtldVendLedgEntry2.SetCurrentKey("Vendor No.", "Posting Date", "Entry Type");
        DtldVendLedgEntry2.SetRange("Vendor No.", Vendor."No.");
        DtldVendLedgEntry2.SetRange("Posting Date", CalcDate('<+1D>', EndDate), DMY2Date(31, 12, 9999));
        if DtldVendLedgEntry2.Find('-') then
            repeat
                VendorLedgerEntry2."Entry No." := DtldVendLedgEntry2."Vendor Ledger Entry No.";
                if VendorLedgerEntry2.Find('=') then
                    if (VendorLedgerEntry2."Posting Date" >= StartDate) and
                        (VendorLedgerEntry2."Posting Date" <= EndDate)
                    then begin
                        TempVendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No.";
                        if TempVendorLedgerEntry.Insert() then;
                    end;
            until DtldVendLedgEntry2.Next() = 0;

        VendorLedgerEntry2.SetCurrentKey("Vendor No.", Open);
        VendorLedgerEntry2.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry2.SetRange(Open, true);
        VendorLedgerEntry2.SetRange("Posting Date", 0D, EndDate);
        if VendorLedgerEntry2.Find('-') then
            repeat
                TempVendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No.";
                if TempVendorLedgerEntry.Insert() then;
            until VendorLedgerEntry2.Next() = 0;
        VendorLedgerEntry2.Reset();
    end;

    local procedure AdjustVATEntries(VATType: Enum "General Posting Type"; UseTax: Boolean)
    begin
        Clear(VATEntry2);
        VATEntry.SetRange(Type, VATType);
        VATEntry.SetRange("Use Tax", UseTax);
        if VATEntry.Find('-') then
            repeat
                Accumulate(VATEntry2.Base, VATEntry.Base);
                Accumulate(VATEntry2.Amount, VATEntry.Amount);
                Accumulate(VATEntry2."Unrealized Amount", VATEntry."Unrealized Amount");
                Accumulate(VATEntry2."Unrealized Base", VATEntry."Unrealized Base");
                Accumulate(VATEntry2."Remaining Unrealized Amount", VATEntry."Remaining Unrealized Amount");
                Accumulate(VATEntry2."Remaining Unrealized Base", VATEntry."Remaining Unrealized Base");
                Accumulate(VATEntry2."Additional-Currency Amount", VATEntry."Additional-Currency Amount");
                Accumulate(VATEntry2."Additional-Currency Base", VATEntry."Additional-Currency Base");
                Accumulate(VATEntry2."Add.-Currency Unrealized Amt.", VATEntry."Add.-Currency Unrealized Amt.");
                Accumulate(VATEntry2."Add.-Currency Unrealized Base", VATEntry."Add.-Currency Unrealized Base");
                Accumulate(VATEntry2."Add.-Curr. Rem. Unreal. Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                Accumulate(VATEntry2."Add.-Curr. Rem. Unreal. Base", VATEntry."Add.-Curr. Rem. Unreal. Base");

                Accumulate(VATEntryTotalBase.Base, VATEntry.Base);
                Accumulate(VATEntryTotalBase.Amount, VATEntry.Amount);
                Accumulate(VATEntryTotalBase."Unrealized Amount", VATEntry."Unrealized Amount");
                Accumulate(VATEntryTotalBase."Unrealized Base", VATEntry."Unrealized Base");
                Accumulate(VATEntryTotalBase."Remaining Unrealized Amount", VATEntry."Remaining Unrealized Amount");
                Accumulate(VATEntryTotalBase."Remaining Unrealized Base", VATEntry."Remaining Unrealized Base");
                Accumulate(VATEntryTotalBase."Additional-Currency Amount", VATEntry."Additional-Currency Amount");
                Accumulate(VATEntryTotalBase."Additional-Currency Base", VATEntry."Additional-Currency Base");
                Accumulate(VATEntryTotalBase."Add.-Currency Unrealized Amt.", VATEntry."Add.-Currency Unrealized Amt.");
                Accumulate(VATEntryTotalBase."Add.-Currency Unrealized Base", VATEntry."Add.-Currency Unrealized Base");
                Accumulate(
                    VATEntryTotalBase."Add.-Curr. Rem. Unreal. Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                Accumulate(VATEntryTotalBase."Add.-Curr. Rem. Unreal. Base", VATEntry."Add.-Curr. Rem. Unreal. Base");

                AdjustVATAmount(VATEntry.Base, VATEntry."Additional-Currency Base");
                AdjustVATAmount(VATEntry.Amount, VATEntry."Additional-Currency Amount");
                AdjustVATAmount(VATEntry."Unrealized Amount", VATEntry."Add.-Currency Unrealized Amt.");
                AdjustVATAmount(VATEntry."Unrealized Base", VATEntry."Add.-Currency Unrealized Base");
                AdjustVATAmount(VATEntry."Remaining Unrealized Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                AdjustVATAmount(VATEntry."Remaining Unrealized Base", VATEntry."Add.-Curr. Rem. Unreal. Base");
                VATEntry.Modify();

                Accumulate(VATEntry2.Base, -VATEntry.Base);
                Accumulate(VATEntry2.Amount, -VATEntry.Amount);
                Accumulate(VATEntry2."Unrealized Amount", -VATEntry."Unrealized Amount");
                Accumulate(VATEntry2."Unrealized Base", -VATEntry."Unrealized Base");
                Accumulate(VATEntry2."Remaining Unrealized Amount", -VATEntry."Remaining Unrealized Amount");
                Accumulate(VATEntry2."Remaining Unrealized Base", -VATEntry."Remaining Unrealized Base");
                Accumulate(VATEntry2."Additional-Currency Amount", -VATEntry."Additional-Currency Amount");
                Accumulate(VATEntry2."Additional-Currency Base", -VATEntry."Additional-Currency Base");
                Accumulate(VATEntry2."Add.-Currency Unrealized Amt.", -VATEntry."Add.-Currency Unrealized Amt.");
                Accumulate(VATEntry2."Add.-Currency Unrealized Base", -VATEntry."Add.-Currency Unrealized Base");
                Accumulate(VATEntry2."Add.-Curr. Rem. Unreal. Amount", -VATEntry."Add.-Curr. Rem. Unreal. Amount");
                Accumulate(VATEntry2."Add.-Curr. Rem. Unreal. Base", -VATEntry."Add.-Curr. Rem. Unreal. Base");
            until VATEntry.Next() = 0;
    end;

    local procedure AdjustVATAmount(var AmountLCY: Decimal; var AmountAddCurr: Decimal)
    begin
        case GLSetup."VAT Exchange Rate Adjustment" of
            GLSetup."VAT Exchange Rate Adjustment"::"Adjust Amount":
                AmountLCY :=
                  Round(
                    CurrExchRate2.ExchangeAmtFCYToLCYAdjmt(
                      PostingDate, GLSetup."Additional Reporting Currency",
                      AmountAddCurr, AddCurrCurrencyFactor));
            GLSetup."VAT Exchange Rate Adjustment"::"Adjust Additional-Currency Amount":
                AmountAddCurr :=
                  Round(
                    CurrExchRate2.ExchangeAmtLCYToFCY(
                      PostingDate, GLSetup."Additional Reporting Currency",
                      AmountLCY, AddCurrCurrencyFactor));
        end;
    end;

    local procedure AdjustVATAccount(AccNo: Code[20]; AmountLCY: Decimal; AmountAddCurr: Decimal; BaseLCY: Decimal; BaseAddCurr: Decimal)
    begin
        "G/L Account".Get(AccNo);
        "G/L Account".SetRange("Date Filter", StartDate, EndDate);
        case GLSetup."VAT Exchange Rate Adjustment" of
            GLSetup."VAT Exchange Rate Adjustment"::"Adjust Amount":
                PostGLAccAdjmt(
                  AccNo, GLSetup."VAT Exchange Rate Adjustment"::"Adjust Amount",
                  -AmountLCY, BaseLCY, BaseAddCurr);
            GLSetup."VAT Exchange Rate Adjustment"::"Adjust Additional-Currency Amount":
                PostGLAccAdjmt(
                  AccNo, GLSetup."VAT Exchange Rate Adjustment"::"Adjust Additional-Currency Amount",
                  -AmountAddCurr, BaseLCY, BaseAddCurr);
        end;
    end;

    local procedure AdjustPurchTax(UseTax: Boolean)
    begin
        if (VATEntry2.Amount <> 0) or (VATEntry2."Additional-Currency Amount" <> 0) then begin
            TaxJurisdiction.TestField("Tax Account (Purchases)");
            AdjustVATAccount(
              TaxJurisdiction."Tax Account (Purchases)",
              VATEntry2.Amount, VATEntry2."Additional-Currency Amount",
              VATEntryTotalBase.Amount, VATEntryTotalBase."Additional-Currency Amount");
            if UseTax then begin
                TaxJurisdiction.TestField("Reverse Charge (Purchases)");
                AdjustVATAccount(
                  TaxJurisdiction."Reverse Charge (Purchases)",
                  -VATEntry2.Amount, -VATEntry2."Additional-Currency Amount",
                  -VATEntryTotalBase.Amount, -VATEntryTotalBase."Additional-Currency Amount");
            end;
        end;
        if (VATEntry2."Remaining Unrealized Amount" <> 0) or
           (VATEntry2."Add.-Curr. Rem. Unreal. Amount" <> 0)
        then begin
            TaxJurisdiction.TestField("Unrealized VAT Type");
            TaxJurisdiction.TestField("Unreal. Tax Acc. (Purchases)");
            AdjustVATAccount(
              TaxJurisdiction."Unreal. Tax Acc. (Purchases)",
              VATEntry2."Remaining Unrealized Amount", VATEntry2."Add.-Curr. Rem. Unreal. Amount",
              VATEntryTotalBase."Remaining Unrealized Amount", VATEntry2."Add.-Curr. Rem. Unreal. Amount");

            if UseTax then begin
                TaxJurisdiction.TestField("Unreal. Rev. Charge (Purch.)");
                AdjustVATAccount(
                  TaxJurisdiction."Unreal. Rev. Charge (Purch.)",
                  -VATEntry2."Remaining Unrealized Amount",
                  -VATEntry2."Add.-Curr. Rem. Unreal. Amount",
                  -VATEntryTotalBase."Remaining Unrealized Amount",
                  -VATEntryTotalBase."Add.-Curr. Rem. Unreal. Amount");
            end;
        end;
    end;

    local procedure AdjustSalesTax()
    begin
        TaxJurisdiction.TestField("Tax Account (Sales)");
        AdjustVATAccount(
          TaxJurisdiction."Tax Account (Sales)",
          VATEntry2.Amount, VATEntry2."Additional-Currency Amount",
          VATEntryTotalBase.Amount, VATEntryTotalBase."Additional-Currency Amount");
        if (VATEntry2."Remaining Unrealized Amount" <> 0) or
           (VATEntry2."Add.-Curr. Rem. Unreal. Amount" <> 0)
        then begin
            TaxJurisdiction.TestField("Unrealized VAT Type");
            TaxJurisdiction.TestField("Unreal. Tax Acc. (Sales)");
            AdjustVATAccount(
              TaxJurisdiction."Unreal. Tax Acc. (Sales)",
              VATEntry2."Remaining Unrealized Amount",
              VATEntry2."Add.-Curr. Rem. Unreal. Amount",
              VATEntryTotalBase."Remaining Unrealized Amount",
              VATEntryTotalBase."Add.-Curr. Rem. Unreal. Amount");
        end;
    end;

    local procedure Accumulate(var TotalAmount: Decimal; AmountToAdd: Decimal)
    begin
        TotalAmount := TotalAmount + AmountToAdd;
    end;

    local procedure PostGLAccAdjmt(GLAccNo: Code[20]; ExchRateAdjmt: Integer; Amount: Decimal; NetChange: Decimal; AddCurrNetChange: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.Init();
        case ExchRateAdjmt of
            "G/L Account"."Exchange Rate Adjustment"::"Adjust Amount":
                begin
                    GenJnlLine."Additional-Currency Posting" := GenJnlLine."Additional-Currency Posting"::"Amount Only";
                    GenJnlLine."Currency Code" := '';
                    GenJnlLine.Amount := Amount;
                    GenJnlLine."Amount (LCY)" := GenJnlLine.Amount;
                    GLAmtTotal := GLAmtTotal + GenJnlLine.Amount;
                    GLAddCurrNetChangeTotal := GLAddCurrNetChangeTotal + AddCurrNetChange;
                    GLNetChangeBase := GLNetChangeBase + NetChange;
                end;
            "G/L Account"."Exchange Rate Adjustment"::"Adjust Additional-Currency Amount":
                begin
                    GenJnlLine."Additional-Currency Posting" := GenJnlLine."Additional-Currency Posting"::"Additional-Currency Amount Only";
                    GenJnlLine."Currency Code" := GLSetup."Additional Reporting Currency";
                    GenJnlLine.Amount := Amount;
                    GenJnlLine."Amount (LCY)" := 0;
                    GLAddCurrAmtTotal := GLAddCurrAmtTotal + GenJnlLine.Amount;
                    GLNetChangeTotal := GLNetChangeTotal + NetChange;
                    GLAddCurrNetChangeBase := GLAddCurrNetChangeBase + AddCurrNetChange;
                end;
        end;
        if GenJnlLine.Amount <> 0 then begin
            GenJnlLine."Document No." := PostingDocNo;
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine."Account No." := GLAccNo;
            GenJnlLine."Posting Date" := PostingDate;
            case GenJnlLine."Additional-Currency Posting" of
                GenJnlLine."Additional-Currency Posting"::"Amount Only":
                    GenJnlLine.Description :=
                      StrSubstNo(
                        PostingDescription,
                        GLSetup."Additional Reporting Currency",
                        AddCurrNetChange);
                GenJnlLine."Additional-Currency Posting"::"Additional-Currency Amount Only":
                    GenJnlLine.Description :=
                      StrSubstNo(
                        PostingDescription,
                        '',
                        NetChange);
            end;
            GenJnlLine."System-Created Entry" := true;
            GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
            GetJnlLineDefDim(GenJnlLine, TempDimSetEntry);
            PostGenJnlLine(GenJnlLine, TempDimSetEntry);
        end;
    end;

    local procedure PostGLAccAdjmtTotal()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.Init();
        GenJnlLine."Document No." := PostingDocNo;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
        GenJnlLine."System-Created Entry" := true;

        if GLAmtTotal <> 0 then begin
            if GLAmtTotal < 0 then
                GenJnlLine."Account No." := Currency3.GetRealizedGLLossesAccount
            else
                GenJnlLine."Account No." := Currency3.GetRealizedGLGainsAccount;
            GenJnlLine.Description :=
                StrSubstNo(
                PostingDescription,
                GLSetup."Additional Reporting Currency",
                GLAddCurrNetChangeTotal);
            GenJnlLine."Additional-Currency Posting" := GenJnlLine."Additional-Currency Posting"::"Amount Only";
            GenJnlLine."Currency Code" := '';
            GenJnlLine.Amount := -GLAmtTotal;
            GenJnlLine."Amount (LCY)" := -GLAmtTotal;
            GetJnlLineDefDim(GenJnlLine, TempDimSetEntry);
            PostGenJnlLine(GenJnlLine, TempDimSetEntry);
        end;
        if GLAddCurrAmtTotal <> 0 then begin
            if GLAddCurrAmtTotal < 0 then
                GenJnlLine."Account No." := Currency3.GetRealizedGLLossesAccount
            else
                GenJnlLine."Account No." := Currency3.GetRealizedGLGainsAccount;
            GenJnlLine.Description :=
                StrSubstNo(
                PostingDescription, '',
                GLNetChangeTotal);
            GenJnlLine."Additional-Currency Posting" := GenJnlLine."Additional-Currency Posting"::"Additional-Currency Amount Only";
            GenJnlLine."Currency Code" := GLSetup."Additional Reporting Currency";
            GenJnlLine.Amount := -GLAddCurrAmtTotal;
            GenJnlLine."Amount (LCY)" := 0;
            GetJnlLineDefDim(GenJnlLine, TempDimSetEntry);
            PostGenJnlLine(GenJnlLine, TempDimSetEntry);
        end;

        with ExchRateAdjReg do begin
            "No." := "No." + 1;
            "Creation Date" := PostingDate;
            "Account Type" := "Account Type"::"G/L Account";
            "Posting Group" := '';
            "Currency Code" := GLSetup."Additional Reporting Currency";
            "Currency Factor" := CurrExchRate2."Adjustment Exch. Rate Amount";
            "Adjusted Base" := 0;
            "Adjusted Base (LCY)" := GLNetChangeBase;
            "Adjusted Amt. (LCY)" := GLAmtTotal;
            "Adjusted Base (Add.-Curr.)" := GLAddCurrNetChangeBase;
            "Adjusted Amt. (Add.-Curr.)" := GLAddCurrAmtTotal;
            Insert;
        end;
    end;

    local procedure CheckExchRateAdjustment(AccNo: Code[20]; SetupTableName: Text[100]; SetupFieldName: Text[100])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo = '' then
            exit;
        GLAcc.Get(AccNo);
        if GLAcc."Exchange Rate Adjustment" <> GLAcc."Exchange Rate Adjustment"::"No Adjustment" then begin
            GLAcc."Exchange Rate Adjustment" := GLAcc."Exchange Rate Adjustment"::"No Adjustment";
            Error(
              Text017Err,
              GLAcc.FieldCaption("Exchange Rate Adjustment"), GLAcc.TableCaption,
              GLAcc."No.", GLAcc."Exchange Rate Adjustment",
              SetupTableName, GLSetup.FieldCaption("VAT Exchange Rate Adjustment"),
              GLSetup.TableCaption, SetupFieldName);
        end;
    end;

    local procedure HandleCustDebitCredit(Correction: Boolean; AdjAmount: Decimal)
    begin
        if (AdjAmount > 0) and not Correction or
           (AdjAmount < 0) and Correction
        then begin
            TempDtldCustLedgEntry."Debit Amount (LCY)" := AdjAmount;
            TempDtldCustLedgEntry."Credit Amount (LCY)" := 0;
        end else begin
            TempDtldCustLedgEntry."Debit Amount (LCY)" := 0;
            TempDtldCustLedgEntry."Credit Amount (LCY)" := -AdjAmount;
        end;
    end;

    local procedure HandleVendDebitCredit(Correction: Boolean; AdjAmount: Decimal)
    begin
        if (AdjAmount > 0) and not Correction or
           (AdjAmount < 0) and Correction
        then begin
            TempDtldVendLedgEntry."Debit Amount (LCY)" := AdjAmount;
            TempDtldVendLedgEntry."Credit Amount (LCY)" := 0;
        end else begin
            TempDtldVendLedgEntry."Debit Amount (LCY)" := 0;
            TempDtldVendLedgEntry."Credit Amount (LCY)" := -AdjAmount;
        end;
    end;

    local procedure GetJnlLineDefDim(var GenJnlLine: Record "Gen. Journal Line"; var DimSetEntry: Record "Dimension Set Entry")
    var
        DimSetID: Integer;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::"G/L Account":
                TableID[1] := DATABASE::"G/L Account";
            GenJnlLine."Account Type"::"Bank Account":
                TableID[1] := DATABASE::"Bank Account";
        end;
        No[1] := GenJnlLine."Account No.";
        DimSetID :=
            DimMgt.GetDefaultDimID(
                TableID, No, GenJnlLine."Source Code",
                GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code",
                GenJnlLine."Dimension Set ID", 0);
        DimMgt.GetDimensionSet(DimSetEntry, DimSetID);
    end;

    local procedure CopyDimSetEntryToDimBuf(var DimSetEntry: Record "Dimension Set Entry"; var DimBuf: Record "Dimension Buffer")
    begin
        if DimSetEntry.Find('-') then
            repeat
                DimBuf."Table ID" := DATABASE::"Dimension Buffer";
                DimBuf."Entry No." := 0;
                DimBuf."Dimension Code" := DimSetEntry."Dimension Code";
                DimBuf."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                DimBuf.Insert();
            until DimSetEntry.Next() = 0;
    end;

    local procedure GetDimCombID(var DimBuf: Record "Dimension Buffer"): Integer
    var
        DimEntryNo: Integer;
    begin
        DimEntryNo := DimBufMgt.FindDimensions(DimBuf);
        if DimEntryNo = 0 then
            DimEntryNo := DimBufMgt.InsertDimensions(DimBuf);
        exit(DimEntryNo);
    end;

    local procedure PostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var DimSetEntry: Record "Dimension Set Entry") Result: Integer
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostGenJnlLine(GenJnlLine, DimSetEntry, GenJnlPostLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        // NAVCZ
        case DimMoveType of
            DimMoveType::"No move":
                begin
                    ;
                    // no dimension
                    GenJnlLine."Shortcut Dimension 1 Code" := '';
                    GenJnlLine."Shortcut Dimension 2 Code" := '';
                    GenJnlLine."Dimension Set ID" := 0;
                end;
            DimMoveType::"Source Entry":
                begin
                    ;
                    // default dim for G/L account, other by source entries
                    GenJnlLine."Shortcut Dimension 1 Code" := GetGlobalDimVal(GLSetup."Global Dimension 1 Code", DimSetEntry);
                    GenJnlLine."Shortcut Dimension 2 Code" := GetGlobalDimVal(GLSetup."Global Dimension 2 Code", DimSetEntry);
                    GenJnlLine."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
                end;
            DimMoveType::"By G/L Account":
                begin
                    ;
                    // source entries dimension -> default dim for G/L account
                    if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account" then begin
                        TableID[1] := DATABASE::"G/L Account";
                        No[1] := GenJnlLine."Account No.";
                        GenJnlLine."Dimension Set ID" :=
                          DimMgt.GetDefaultDimID(TableID, No,
                            GenJnlLine."Source Code", GenJnlLine."Shortcut Dimension 1 Code",
                            GenJnlLine."Shortcut Dimension 2 Code", 0, 0);
                    end;
                end;
        end;

        if not TestMode then begin // NAVCZ
            OnPostGenJnlLineOnBeforeGenJnlPostLineRun(GenJnlLine);
            GenJnlPostLine.Run(GenJnlLine);
            OnPostGenJnlLineOnAfterGenJnlPostLineRun(GenJnlLine, GenJnlPostLine);

            exit(GenJnlPostLine.GetNextTransactionNo);
        end;
    end;

    local procedure GetGlobalDimVal(GlobalDimCode: Code[20]; var DimSetEntry: Record "Dimension Set Entry"): Code[20]
    var
        DimVal: Code[20];
    begin
        if GlobalDimCode = '' then
            DimVal := ''
        else begin
            DimSetEntry.SetRange("Dimension Code", GlobalDimCode);
            if DimSetEntry.Find('-') then
                DimVal := DimSetEntry."Dimension Value Code"
            else
                DimVal := '';
            DimSetEntry.SetRange("Dimension Code");
        end;
        exit(DimVal);
    end;

    procedure CheckPostingDate()
    begin
        if PostingDate < StartDate then
            Error(Text018Err);
        if PostingDate > EndDateReq then
            Error(Text018Err);
    end;

    procedure AdjustCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; PostingDate2: Date)
    var
        DimSetEntry: Record "Dimension Set Entry";
        DimEntryNo: Integer;
        OldAdjAmount: Decimal;
        Adjust: Boolean;
        UpdateBuffer: Boolean;
        AdjExchRateBufIndex: Integer;
    begin
        CustLedgerEntry.SetRange("Date Filter", 0D, PostingDate2);
        TempCurrencyToAdjust.Get(CustLedgerEntry."Currency Code");
        GainsAmount := 0;
        LossesAmount := 0;
        OldAdjAmount := 0;
        Adjust := false;
        UpdateBuffer := true; // NAVCZ

        TempDimSetEntry.Reset();
        TempDimSetEntry.DeleteAll();
        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
        DimSetEntry.SetRange("Dimension Set ID", CustLedgerEntry."Dimension Set ID");
        CopyDimSetEntryToDimBuf(DimSetEntry, TempDimBuf);
        DimEntryNo := GetDimCombID(TempDimBuf);

        CustLedgerEntry.CalcFields(
            Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)", "Original Amt. (LCY)",
            "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");

        // Calculate Old Unrealized Gains and Losses
        SetUnrealizedGainLossFilterCust(DtldCustLedgEntry, CustLedgerEntry."Entry No.");
        DtldCustLedgEntry.CalcSums("Amount (LCY)");

        SetUnrealizedGainLossFilterCust(TempDtldCustLedgEntrySums, CustLedgerEntry."Entry No.");
        TempDtldCustLedgEntrySums.CalcSums("Amount (LCY)");
        OldAdjAmount := DtldCustLedgEntry."Amount (LCY)" + TempDtldCustLedgEntrySums."Amount (LCY)";
        CustLedgerEntry."Remaining Amt. (LCY)" += TempDtldCustLedgEntrySums."Amount (LCY)";
        CustLedgerEntry."Debit Amount (LCY)" += TempDtldCustLedgEntrySums."Amount (LCY)";
        CustLedgerEntry."Credit Amount (LCY)" += TempDtldCustLedgEntrySums."Amount (LCY)";
        TempDtldCustLedgEntrySums.Reset();

        // Modify Currency factor on Customer Ledger Entry
        if CustLedgerEntry."Adjusted Currency Factor" <> TempCurrencyToAdjust."Currency Factor" then begin
            CustLedgerEntry."Adjusted Currency Factor" := TempCurrencyToAdjust."Currency Factor";
            if not TestMode then  // NAVCZ
                CustLedgerEntry.Modify();
        end;

        AdjustedFactor := Round(1 / CustLedgerEntry."Adjusted Currency Factor", 0.0001);  // NAVCZ

        // Calculate New Unrealized Gains and Losses
        CurrAdjAmount :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCYAdjmt(
                    PostingDate2, TempCurrencyToAdjust.Code, CustLedgerEntry."Remaining Amount", TempCurrencyToAdjust."Currency Factor")) -
                CustLedgerEntry."Remaining Amt. (LCY)";

        if CurrAdjAmount <> 0 then begin
            OnAdjustCustomerLedgerEntryOnBeforeInitDtldCustLedgEntry(Customer, CustLedgerEntry);
            InitDtldCustLedgEntry(CustLedgerEntry, TempDtldCustLedgEntry);
            TempDtldCustLedgEntry."Entry No." := NewEntryNo;
            TempDtldCustLedgEntry."Posting Date" := PostingDate2;
            TempDtldCustLedgEntry."Document No." := PostingDocNo;
            // NAVCZ
            TempDtldCustLedgEntry."Customer Posting Group" := CustLedgerEntry."Customer Posting Group";
            TempDtldCustLedgEntry.Advance :=
                CustLedgerEntry."Prepayment Type" = CustLedgerEntry."Prepayment Type"::Advance;
            // NAVCZ

            Correction :=
                (CustLedgerEntry."Debit Amount" < 0) or
                (CustLedgerEntry."Credit Amount" < 0) or
                (CustLedgerEntry."Debit Amount (LCY)" < 0) or
                (CustLedgerEntry."Credit Amount (LCY)" < 0);

            // NAVCZ
            if (OldAdjAmount > 0) and (RealGainLossAmt > 0) and (CurrAdjAmount < 0) then
                CreateDtldCustLedgEntryUnrealGain(
                  CustLedgerEntry, TempDtldCustLedgEntry, DimEntryNo, PostingDate2, UpdateBuffer, Adjust);
            if (OldAdjAmount < 0) and (RealGainLossAmt < 0) and (CurrAdjAmount > 0) then
                CreateDtldCustLedgEntryUnrealLoss(
                  CustLedgerEntry, TempDtldCustLedgEntry, DimEntryNo, PostingDate2, UpdateBuffer, Adjust);
            // NAVCZ

            if not Adjust then begin
                TempDtldCustLedgEntry."Amount (LCY)" := CurrAdjAmount;
                HandleCustDebitCredit(Correction, TempDtldCustLedgEntry."Amount (LCY)");
                TempDtldCustLedgEntry."Entry No." := NewEntryNo;
                if CurrAdjAmount < 0 then begin
                    TempDtldCustLedgEntry."Entry Type" := TempDtldCustLedgEntry."Entry Type"::"Unrealized Loss";
                    GainsAmount := 0;
                    LossesAmount := CurrAdjAmount;
                end else
                    if CurrAdjAmount > 0 then begin
                        TempDtldCustLedgEntry."Entry Type" := TempDtldCustLedgEntry."Entry Type"::"Unrealized Gain";
                        GainsAmount := CurrAdjAmount;
                        LossesAmount := 0;
                    end;
                InsertTempDtldCustomerLedgerEntry();
                NewEntryNo := NewEntryNo + 1;
            end;

            if UpdateBuffer then begin // NAVCZ
                TotalAdjAmount := TotalAdjAmount + CurrAdjAmount;
                if not HideUI then
                    Window.Update(4, TotalAdjAmount);
                AdjExchRateBufIndex :=
                  AdjExchRateBufferUpdate(
                    CustLedgerEntry."Currency Code", CustLedgerEntry."Customer Posting Group",
                    CustLedgerEntry."Remaining Amount", CustLedgerEntry."Remaining Amt. (LCY)", TempDtldCustLedgEntry."Amount (LCY)",
                    GainsAmount, LossesAmount, DimEntryNo, PostingDate2, Customer."IC Partner Code",
                    TempDtldCustLedgEntry.Advance, GetInitialGLAccountNo(CustLedgerEntry."Entry No.", 0, CustLedgerEntry."Customer Posting Group")); // NAVCZ
                TempDtldCustLedgEntry."Transaction No." := AdjExchRateBufIndex;
                ModifyTempDtldCustomerLedgerEntry();

                // NAVCZ
                TempAdjExchRateBuffer."Document Type" := CustLedgerEntry."Document Type".AsInteger();
                TempAdjExchRateBuffer."Document No." := CustLedgerEntry."Document No.";
                TempAdjExchRateBuffer.Modify();
                // NAVCZ
            end; // NAVCZ
        end;
    end;

    procedure AdjustVendorLedgerEntry(VendLedgerEntry: Record "Vendor Ledger Entry"; PostingDate2: Date)
    var
        DimSetEntry: Record "Dimension Set Entry";
        DimEntryNo: Integer;
        OldAdjAmount: Decimal;
        Adjust: Boolean;
        UpdateBuffer: Boolean;
        AdjExchRateBufIndex: Integer;
    begin
        VendLedgerEntry.SetRange("Date Filter", 0D, PostingDate2);
        TempCurrencyToAdjust.Get(VendLedgerEntry."Currency Code");
        GainsAmount := 0;
        LossesAmount := 0;
        OldAdjAmount := 0;
        Adjust := false;
        UpdateBuffer := true; // NAVCZ

        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
        DimSetEntry.SetRange("Dimension Set ID", VendLedgerEntry."Dimension Set ID");
        CopyDimSetEntryToDimBuf(DimSetEntry, TempDimBuf);
        DimEntryNo := GetDimCombID(TempDimBuf);

        VendLedgerEntry.CalcFields(
            Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)", "Original Amt. (LCY)",
            "Debit Amount", "Credit Amount", "Debit Amount (LCY)", "Credit Amount (LCY)");

        // Calculate Old Unrealized GainLoss
        SetUnrealizedGainLossFilterVend(DtldVendLedgEntry, VendLedgerEntry."Entry No.");
        DtldVendLedgEntry.CalcSums("Amount (LCY)");

        SetUnrealizedGainLossFilterVend(TempDtldVendLedgEntrySums, VendLedgerEntry."Entry No.");
        TempDtldVendLedgEntrySums.CalcSums("Amount (LCY)");
        OldAdjAmount := DtldVendLedgEntry."Amount (LCY)" + TempDtldVendLedgEntrySums."Amount (LCY)";
        VendLedgerEntry."Remaining Amt. (LCY)" += TempDtldVendLedgEntrySums."Amount (LCY)";
        VendLedgerEntry."Debit Amount (LCY)" += TempDtldVendLedgEntrySums."Amount (LCY)";
        VendLedgerEntry."Credit Amount (LCY)" += TempDtldVendLedgEntrySums."Amount (LCY)";
        TempDtldVendLedgEntrySums.Reset();

        // Modify Currency factor on Vendor Ledger Entry
        if VendLedgerEntry."Adjusted Currency Factor" <> TempCurrencyToAdjust."Currency Factor" then begin
            VendLedgerEntry."Adjusted Currency Factor" := TempCurrencyToAdjust."Currency Factor";
            if not TestMode then  // NAVCZ
                VendLedgerEntry.Modify();
        end;

        AdjustedFactor := Round(1 / VendLedgerEntry."Adjusted Currency Factor", 0.0001);  // NAVCZ

        // Calculate New Unrealized Gains and Losses
        CurrAdjAmount :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCYAdjmt(
                    PostingDate2, TempCurrencyToAdjust.Code, VendLedgerEntry."Remaining Amount", TempCurrencyToAdjust."Currency Factor")) -
                VendLedgerEntry."Remaining Amt. (LCY)";

        if CurrAdjAmount <> 0 then begin
            OnAdjustVendorLedgerEntryOnBeforeInitDtldVendLedgEntry(Vendor, VendLedgerEntry);
            InitDtldVendLedgEntry(VendLedgerEntry, TempDtldVendLedgEntry);
            TempDtldVendLedgEntry."Entry No." := NewEntryNo;
            TempDtldVendLedgEntry."Posting Date" := PostingDate2;
            TempDtldVendLedgEntry."Document No." := PostingDocNo;
            // NAVCZ
            TempDtldVendLedgEntry."Vendor Posting Group" := VendLedgerEntry."Vendor Posting Group";
            TempDtldVendLedgEntry.Advance :=
              VendorLedgerEntry."Prepayment Type" = VendLedgerEntry."Prepayment Type"::Advance;
            // NAVCZ

            Correction :=
                (VendLedgerEntry."Debit Amount" < 0) or
                (VendLedgerEntry."Credit Amount" < 0) or
                (VendLedgerEntry."Debit Amount (LCY)" < 0) or
                (VendLedgerEntry."Credit Amount (LCY)" < 0);

            // NAVCZ
            if (OldAdjAmount > 0) and (RealGainLossAmt > 0) and (CurrAdjAmount < 0) then
                CreateDtldVendLedgEntryUnrealGain(
                  VendLedgerEntry, TempDtldVendLedgEntry, DimEntryNo, PostingDate2, UpdateBuffer, Adjust);
            if (OldAdjAmount < 0) and (RealGainLossAmt < 0) and (CurrAdjAmount > 0) then
                CreateDtldVendLedgEntryUnrealLoss(
                  VendLedgerEntry, TempDtldVendLedgEntry, DimEntryNo, PostingDate2, UpdateBuffer, Adjust);
            // NAVCZ

            if not Adjust then begin
                TempDtldVendLedgEntry."Amount (LCY)" := CurrAdjAmount;
                HandleVendDebitCredit(Correction, TempDtldVendLedgEntry."Amount (LCY)");
                TempDtldVendLedgEntry."Entry No." := NewEntryNo;
                if CurrAdjAmount < 0 then begin
                    TempDtldVendLedgEntry."Entry Type" := TempDtldVendLedgEntry."Entry Type"::"Unrealized Loss";
                    GainsAmount := 0;
                    LossesAmount := CurrAdjAmount;
                end else
                    if CurrAdjAmount > 0 then begin
                        TempDtldVendLedgEntry."Entry Type" := TempDtldVendLedgEntry."Entry Type"::"Unrealized Gain";
                        GainsAmount := CurrAdjAmount;
                        LossesAmount := 0;
                    end;
                InsertTempDtldVendorLedgerEntry();
                NewEntryNo := NewEntryNo + 1;
            end;

            if UpdateBuffer then begin // NAVCZ
                TotalAdjAmount := TotalAdjAmount + CurrAdjAmount;
                if not HideUI then
                    Window.Update(4, TotalAdjAmount);
                AdjExchRateBufIndex :=
                    AdjExchRateBufferUpdate(
                        VendLedgerEntry."Currency Code", VendLedgerEntry."Vendor Posting Group",
                        VendLedgerEntry."Remaining Amount", VendLedgerEntry."Remaining Amt. (LCY)",
                        TempDtldVendLedgEntry."Amount (LCY)", GainsAmount, LossesAmount, DimEntryNo, PostingDate2, Vendor."IC Partner Code",
                        TempDtldVendLedgEntry.Advance, GetInitialGLAccountNo(VendLedgerEntry."Entry No.", 1, VendLedgerEntry."Vendor Posting Group")); // NAVCZ
                TempDtldVendLedgEntry."Transaction No." := AdjExchRateBufIndex;
                ModifyTempDtldVendorLedgerEntry();

                // NAVCZ
                TempAdjExchRateBuffer."Document Type" := VendLedgerEntry."Document Type".AsInteger();
                TempAdjExchRateBuffer."Document No." := VendLedgerEntry."Document No.";
                TempAdjExchRateBuffer.Modify();
                // NAVCZ
            end; // NAVCZ
        end;
    end;

    [Scope('OnPrem')]
    procedure AdjustExchRateCust(GenJournalLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PostingDate2: Date;
    begin
        PostingDate2 := GenJournalLine."Posting Date";
        if TempCustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry2.Get(TempCustLedgerEntry."Entry No.");
                CustLedgerEntry2.SetRange("Date Filter", 0D, PostingDate2);
                CustLedgerEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                if ShouldAdjustEntry(
                        PostingDate2, CustLedgerEntry2."Currency Code", CustLedgerEntry2."Remaining Amount",
                        CustLedgerEntry2."Remaining Amt. (LCY)", CustLedgerEntry2."Adjusted Currency Factor")
                then begin
                    InitVariablesForSetLedgEntry(GenJournalLine);
                    SetCustLedgEntry(CustLedgerEntry2);
                    AdjustCustomerLedgerEntry(CustLedgerEntry2, PostingDate2);

                    DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
                    DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry2."Entry No.");
                    DetailedCustLedgEntry.SetFilter("Posting Date", '%1..', CalcDate('<+1D>', PostingDate2));
                    if DetailedCustLedgEntry.FindSet() then
                        repeat
                            AdjustCustomerLedgerEntry(CustLedgerEntry2, DetailedCustLedgEntry."Posting Date");
                        until DetailedCustLedgEntry.Next() = 0;
                    HandlePostAdjmt(1);
                end;
            until TempCustLedgerEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure AdjustExchRateVend(GenJournalLine: Record "Gen. Journal Line"; var TempVendLedgerEntry: Record "Vendor Ledger Entry" temporary)
    var
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PostingDate2: Date;
    begin
        PostingDate2 := GenJournalLine."Posting Date";
        if TempVendLedgerEntry.FindSet() then
            repeat
                VendLedgerEntry2.Get(TempVendLedgerEntry."Entry No.");
                VendLedgerEntry2.SetRange("Date Filter", 0D, PostingDate2);
                VendLedgerEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                if ShouldAdjustEntry(
                        PostingDate2, VendLedgerEntry2."Currency Code",
                        VendLedgerEntry2."Remaining Amount", VendLedgerEntry2."Remaining Amt. (LCY)", VendLedgerEntry2."Adjusted Currency Factor")
                then begin
                    InitVariablesForSetLedgEntry(GenJournalLine);
                    SetVendLedgEntry(VendLedgerEntry2);
                    AdjustVendorLedgerEntry(VendLedgerEntry2, PostingDate2);

                    DetailedVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
                    DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgerEntry2."Entry No.");
                    DetailedVendLedgEntry.SetFilter("Posting Date", '%1..', CalcDate('<+1D>', PostingDate2));
                    if DetailedVendLedgEntry.FindSet() then
                        repeat
                            AdjustVendorLedgerEntry(VendLedgerEntry2, DetailedVendLedgEntry."Posting Date");
                        until DetailedVendLedgEntry.Next() = 0;
                    HandlePostAdjmt(2);
                end;
            until TempVendLedgerEntry.Next() = 0;
    end;

    local procedure ResetTempAdjmtBuffer()
    begin
        TempAdjExchRateBuffer.Reset();
        TempAdjExchRateBuffer.DeleteAll();
    end;

    local procedure ResetTempAdjmtBuffer2()
    begin
        TempAdjExchRateBuffer2.Reset();
        TempAdjExchRateBuffer2.DeleteAll();
    end;

    local procedure SetCustLedgEntry(CustLedgerEntryToAdjust: Record "Cust. Ledger Entry")
    begin
        Customer.Get(CustLedgerEntryToAdjust."Customer No.");
        AddCurrency(CustLedgerEntryToAdjust."Currency Code", CustLedgerEntryToAdjust."Adjusted Currency Factor");
        DtldCustLedgEntry.LockTable();
        CustLedgerEntry.LockTable();
        NewEntryNo := DtldCustLedgEntry.GetLastEntryNo() + 1;
    end;

    local procedure SetVendLedgEntry(VendLedgerEntryToAdjust: Record "Vendor Ledger Entry")
    begin
        Vendor.Get(VendLedgerEntryToAdjust."Vendor No.");
        AddCurrency(VendLedgerEntryToAdjust."Currency Code", VendLedgerEntryToAdjust."Adjusted Currency Factor");
        DtldVendLedgEntry.LockTable();
        VendorLedgerEntry.LockTable();
        NewEntryNo := DtldVendLedgEntry.GetLastEntryNo() + 1;
    end;

    local procedure ShouldAdjustEntry(PostingDate: Date; CurCode: Code[10]; RemainingAmount: Decimal; RemainingAmtLCY: Decimal; AdjCurFactor: Decimal): Boolean
    begin
        exit(Round(CurrExchRate.ExchangeAmtFCYToLCYAdjmt(PostingDate, CurCode, RemainingAmount, AdjCurFactor)) - RemainingAmtLCY <> 0);
    end;

    local procedure InitVariablesForSetLedgEntry(GenJournalLine: Record "Gen. Journal Line")
    begin
        InitializeRequest(
            GenJournalLine."Posting Date", GenJournalLine."Posting Date", TextCZ002Txt, GenJournalLine."Posting Date");
        PostingDocNo := GenJournalLine."Document No.";
        HideUI := true;
        GLSetup.Get();
        SourceCodeSetup.Get();
        if ExchRateAdjReg.FindLast then
            ExchRateAdjReg.Init();
    end;

    local procedure AddCurrency(CurrencyCode: Code[10]; CurrencyFactor: Decimal)
    var
        CurrencyToAdd: Record Currency;
    begin
        if TempCurrencyToAdjust.Get(CurrencyCode) then begin
            TempCurrencyToAdjust."Currency Factor" := CurrencyFactor;
            TempCurrencyToAdjust.Modify();
        end else begin
            CurrencyToAdd.Get(CurrencyCode);
            TempCurrencyToAdjust := CurrencyToAdd;
            TempCurrencyToAdjust."Currency Factor" := CurrencyFactor;
            TempCurrencyToAdjust.Insert();
        end;
    end;

    local procedure InitDtldCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        DtldCustLedgEntry.Init();
        DtldCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntry."Entry No.";
        DtldCustLedgEntry.Amount := 0;
        DtldCustLedgEntry."Customer No." := CustLedgEntry."Customer No.";
        DtldCustLedgEntry."Currency Code" := CustLedgEntry."Currency Code";
        DtldCustLedgEntry."User ID" := UserId;
        DtldCustLedgEntry."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
        DtldCustLedgEntry."Journal Batch Name" := CustLedgEntry."Journal Batch Name";
        DtldCustLedgEntry."Reason Code" := CustLedgEntry."Reason Code";
        DtldCustLedgEntry."Initial Entry Due Date" := CustLedgEntry."Due Date";
        DtldCustLedgEntry."Initial Entry Global Dim. 1" := CustLedgEntry."Global Dimension 1 Code";
        DtldCustLedgEntry."Initial Entry Global Dim. 2" := CustLedgEntry."Global Dimension 2 Code";
        DtldCustLedgEntry."Initial Document Type" := CustLedgEntry."Document Type";

        OnAfterInitDtldCustLedgerEntry(DtldCustLedgEntry);
    end;

    local procedure InitDtldVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        DtldVendLedgEntry.Init();
        DtldVendLedgEntry."Vendor Ledger Entry No." := VendLedgEntry."Entry No.";
        DtldVendLedgEntry.Amount := 0;
        DtldVendLedgEntry."Vendor No." := VendLedgEntry."Vendor No.";
        DtldVendLedgEntry."Currency Code" := VendLedgEntry."Currency Code";
        DtldVendLedgEntry."User ID" := UserId;
        DtldVendLedgEntry."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
        DtldVendLedgEntry."Journal Batch Name" := VendLedgEntry."Journal Batch Name";
        DtldVendLedgEntry."Reason Code" := VendLedgEntry."Reason Code";
        DtldVendLedgEntry."Initial Entry Due Date" := VendLedgEntry."Due Date";
        DtldVendLedgEntry."Initial Entry Global Dim. 1" := VendLedgEntry."Global Dimension 1 Code";
        DtldVendLedgEntry."Initial Entry Global Dim. 2" := VendLedgEntry."Global Dimension 2 Code";
        DtldVendLedgEntry."Initial Document Type" := VendLedgEntry."Document Type";

        OnAfterInitDtldVendLedgerEntry(DtldVendLedgEntry);
    end;

    local procedure CreateDtldCustLedgEntryUnrealGain(CustLedgEntry: Record "Cust. Ledger Entry"; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DimEntryNo: Integer; PostingDate2: Date; var UpdateBuffer: Boolean; var Adjust: Boolean)
    begin
        CreateDtldCustLedgEntryUnreal(
          CustLedgEntry, DtldCustLedgEntry, DimEntryNo, PostingDate2,
          UpdateBuffer, Adjust, DtldCustLedgEntry."Entry Type"::"Unrealized Gain");
    end;

    local procedure CreateDtldCustLedgEntryUnrealLoss(CustLedgEntry: Record "Cust. Ledger Entry"; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DimEntryNo: Integer; PostingDate2: Date; var UpdateBuffer: Boolean; var Adjust: Boolean)
    begin
        CreateDtldCustLedgEntryUnreal(
          CustLedgEntry, DtldCustLedgEntry, DimEntryNo, PostingDate2,
          UpdateBuffer, Adjust, DtldCustLedgEntry."Entry Type"::"Unrealized Loss");
    end;

    local procedure CreateDtldCustLedgEntryUnreal(CustLedgEntry: Record "Cust. Ledger Entry"; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DimEntryNo: Integer; PostingDate2: Date; var UpdateBuffer: Boolean; var Adjust: Boolean; DtldCustLedgEntryType: Enum "Detailed CV Ledger Entry Type")
    var
        AdjExchRateBufIndex: Integer;
    begin
        with CustLedgEntry do
            if Abs(CurrAdjAmount) > Abs(RealGainLossAmt) then begin
                DtldCustLedgEntry."Amount (LCY)" := CurrAdjAmount;
                DtldCustLedgEntry."Entry Type" := DtldCustLedgEntryType;
                HandleCustDebitCredit(Correction, DtldCustLedgEntry."Amount (LCY)");
                InsertTempDtldCustomerLedgerEntry;
                NewEntryNo := NewEntryNo + 1;

                case DtldCustLedgEntryType of
                    DtldCustLedgEntry."Entry Type"::"Unrealized Gain":
                        AdjExchRateBufIndex :=
                          AdjExchRateBufferUpdateUnrealGain(
                            "Currency Code", "Customer Posting Group", "Remaining Amount", "Remaining Amt. (LCY)",
                            DtldCustLedgEntry."Amount (LCY)", DimEntryNo, PostingDate2, Customer."IC Partner Code",
                            DtldCustLedgEntry.Advance, GetInitialGLAccountNo("Entry No.", 0, "Customer Posting Group"));
                    DtldCustLedgEntry."Entry Type"::"Unrealized Loss":
                        AdjExchRateBufIndex :=
                          AdjExchRateBufferUpdateUnrealLoss(
                            "Currency Code", "Customer Posting Group", "Remaining Amount", "Remaining Amt. (LCY)",
                            DtldCustLedgEntry."Amount (LCY)", DimEntryNo, PostingDate2, Customer."IC Partner Code",
                            DtldCustLedgEntry.Advance, GetInitialGLAccountNo("Entry No.", 0, "Customer Posting Group"));
                end;

                TempAdjExchRateBuffer."Document Type" := "Document Type".AsInteger();
                TempAdjExchRateBuffer."Document No." := "Document No.";
                TempAdjExchRateBuffer.Modify();

                DtldCustLedgEntry."Transaction No." := AdjExchRateBufIndex;
                ModifyTempDtldCustomerLedgerEntry;

                UpdateBuffer := false;
                Adjust := true;
            end else begin
                DtldCustLedgEntry."Amount (LCY)" := CurrAdjAmount;
                DtldCustLedgEntry."Entry Type" := DtldCustLedgEntryType;
                HandleCustDebitCredit(Correction, DtldCustLedgEntry."Amount (LCY)");
                case DtldCustLedgEntryType of
                    DtldCustLedgEntry."Entry Type"::"Unrealized Gain":
                        GainsAmount := CurrAdjAmount;
                    DtldCustLedgEntry."Entry Type"::"Unrealized Loss":
                        LossesAmount := CurrAdjAmount;
                end;
                InsertTempDtldCustomerLedgerEntry;
                NewEntryNo := NewEntryNo + 1;
                Adjust := true;
            end;
    end;

    local procedure CreateDtldVendLedgEntryUnrealGain(VendLedgEntry: Record "Vendor Ledger Entry"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DimEntryNo: Integer; PostingDate2: Date; var UpdateBuffer: Boolean; var Adjust: Boolean)
    begin
        CreateDtldVendLedgEntryUnreal(
          VendLedgEntry, DtldVendLedgEntry, DimEntryNo, PostingDate2,
          UpdateBuffer, Adjust, DtldVendLedgEntry."Entry Type"::"Unrealized Gain");
    end;

    local procedure CreateDtldVendLedgEntryUnrealLoss(VendLedgEntry: Record "Vendor Ledger Entry"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DimEntryNo: Integer; PostingDate2: Date; var UpdateBuffer: Boolean; var Adjust: Boolean)
    begin
        CreateDtldVendLedgEntryUnreal(
          VendLedgEntry, DtldVendLedgEntry, DimEntryNo, PostingDate2,
          UpdateBuffer, Adjust, DtldVendLedgEntry."Entry Type"::"Unrealized Loss");
    end;

    local procedure CreateDtldVendLedgEntryUnreal(VendLedgEntry: Record "Vendor Ledger Entry"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DimEntryNo: Integer; PostingDate2: Date; var UpdateBuffer: Boolean; var Adjust: Boolean; DtldCustLedgEntryType: Enum "Detailed CV Ledger Entry Type")
    var
        AdjExchRateBufIndex: Integer;
    begin
        with VendLedgEntry do
            if Abs(CurrAdjAmount) > Abs(RealGainLossAmt) then begin
                DtldVendLedgEntry."Amount (LCY)" := CurrAdjAmount;
                DtldVendLedgEntry."Entry Type" := DtldCustLedgEntryType;
                HandleVendDebitCredit(Correction, DtldVendLedgEntry."Amount (LCY)");
                InsertTempDtldVendorLedgerEntry;
                NewEntryNo := NewEntryNo + 1;

                case DtldCustLedgEntryType of
                    DtldCustLedgEntry."Entry Type"::"Unrealized Gain":
                        AdjExchRateBufIndex :=
                          AdjExchRateBufferUpdateUnrealGain(
                            "Currency Code", "Vendor Posting Group", "Remaining Amount", "Remaining Amt. (LCY)",
                            DtldVendLedgEntry."Amount (LCY)", DimEntryNo, PostingDate2, Vendor."IC Partner Code",
                            DtldVendLedgEntry.Advance, GetInitialGLAccountNo("Entry No.", 1, "Vendor Posting Group"));
                    DtldCustLedgEntry."Entry Type"::"Unrealized Loss":
                        AdjExchRateBufIndex :=
                          AdjExchRateBufferUpdateUnrealLoss(
                            "Currency Code", "Vendor Posting Group", "Remaining Amount", "Remaining Amt. (LCY)",
                            DtldVendLedgEntry."Amount (LCY)", DimEntryNo, PostingDate2, Vendor."IC Partner Code",
                            DtldVendLedgEntry.Advance, GetInitialGLAccountNo("Entry No.", 1, "Vendor Posting Group"));
                end;

                TempAdjExchRateBuffer."Document Type" := "Document Type".AsInteger();
                TempAdjExchRateBuffer."Document No." := "Document No.";
                TempAdjExchRateBuffer.Modify();

                DtldVendLedgEntry."Transaction No." := AdjExchRateBufIndex;
                ModifyTempDtldVendorLedgerEntry;

                UpdateBuffer := false;
                Adjust := true;
            end else begin
                DtldVendLedgEntry."Amount (LCY)" := CurrAdjAmount;
                DtldVendLedgEntry."Entry Type" := DtldCustLedgEntryType;
                HandleVendDebitCredit(Correction, DtldVendLedgEntry."Amount (LCY)");
                case DtldCustLedgEntryType of
                    DtldCustLedgEntry."Entry Type"::"Unrealized Gain":
                        GainsAmount := CurrAdjAmount;
                    DtldCustLedgEntry."Entry Type"::"Unrealized Loss":
                        LossesAmount := CurrAdjAmount;
                end;
                InsertTempDtldVendorLedgerEntry;
                NewEntryNo := NewEntryNo + 1;
                Adjust := true;
            end;
    end;

    local procedure SetUnrealizedGainLossFilterCust(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EntryNo: Integer)
    begin
        with DtldCustLedgEntry do begin
            Reset;
            SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
            SetRange("Cust. Ledger Entry No.", EntryNo);
            SetRange("Entry Type", "Entry Type"::"Unrealized Loss", "Entry Type"::"Unrealized Gain");
        end;
    end;

    local procedure SetUnrealizedGainLossFilterVend(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; EntryNo: Integer)
    begin
        with DtldVendLedgEntry do begin
            Reset;
            SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
            SetRange("Vendor Ledger Entry No.", EntryNo);
            SetRange("Entry Type", "Entry Type"::"Unrealized Loss", "Entry Type"::"Unrealized Gain");
        end;
    end;

    local procedure InsertTempDtldCustomerLedgerEntry()
    begin
        TempDtldCustLedgEntry.Insert();
        TempDtldCustLedgEntrySums := TempDtldCustLedgEntry;
        TempDtldCustLedgEntrySums.Insert();
    end;

    local procedure InsertTempDtldVendorLedgerEntry()
    begin
        TempDtldVendLedgEntry.Insert();
        TempDtldVendLedgEntrySums := TempDtldVendLedgEntry;
        TempDtldVendLedgEntrySums.Insert();
    end;

    local procedure ModifyTempDtldCustomerLedgerEntry()
    begin
        TempDtldCustLedgEntry.Modify();
        TempDtldCustLedgEntrySums := TempDtldCustLedgEntry;
        TempDtldCustLedgEntrySums.Modify();
    end;

    local procedure ModifyTempDtldVendorLedgerEntry()
    begin
        TempDtldVendLedgEntry.Modify();
        TempDtldVendLedgEntrySums := TempDtldVendLedgEntry;
        TempDtldVendLedgEntrySums.Modify();
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest2CZ(NewStartDate: Date; NewEndDate: Date; NewPostingDescription: Text[100]; NewPostingDate: Date; NewPostingDocNo: Code[20]; NewAdjCust: Boolean; NewAdjVend: Boolean; NewAdjBank: Boolean; NewAdjGLAcc: Boolean; NewTestMode: Boolean; NewSummarizeEntries: Boolean)
    begin
        // NAVCZ
        InitializeRequest(NewStartDate, NewEndDate, NewPostingDescription, NewPostingDate);
        PostingDocNo := NewPostingDocNo;
        AdjCust := NewAdjCust;
        AdjVend := NewAdjVend;
        AdjBank := NewAdjBank;
        AdjGLAcc := NewAdjGLAcc;
        TestMode := NewTestMode;
        SummarizeEntries := NewSummarizeEntries;
    end;

    [Scope('OnPrem')]
    procedure CreateCustRealGainLossEntries(var DtldCustLedgEntry3: Record "Detailed Cust. Ledg. Entry")
    var
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry4: Record "Detailed Cust. Ledg. Entry";
    begin
        // NAVCZ
        TmpDtldCustLedgEntry2.Reset();
        TmpDtldCustLedgEntry2.DeleteAll();
        DtldCustLedgEntry4.Copy(DtldCustLedgEntry3);
        if DtldCustLedgEntry4.Find('-') then
            repeat
                DtldCustLedgEntry2.Reset();
                DtldCustLedgEntry2.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
                DtldCustLedgEntry2.SetRange("Cust. Ledger Entry No.", DtldCustLedgEntry4."Applied Cust. Ledger Entry No.");
                DtldCustLedgEntry2.SetRange(
                  "Entry Type",
                  DtldCustLedgEntry2."Entry Type"::"Realized Loss",
                  DtldCustLedgEntry2."Entry Type"::"Realized Gain");
                if DtldCustLedgEntry2.Find('-') then
                    repeat
                        if DtldCustLedgEntry2."Cust. Ledger Entry No." <> DtldCustLedgEntry4."Cust. Ledger Entry No." then begin
                            TmpDtldCustLedgEntry2.Init();
                            TmpDtldCustLedgEntry2.TransferFields(DtldCustLedgEntry2);
                            if TmpDtldCustLedgEntry2.Insert() then;
                        end;
                    until DtldCustLedgEntry2.Next() = 0;
            until DtldCustLedgEntry4.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CalcCustRealGainLossAmount(CustLedgEntryNo: Integer; EntryPostingDate: Date)
    var
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        // NAVCZ
        if not SummarizeEntries then
            RealGainLossAmt := 0;

        DtldCustLedgEntry2.Reset();
        DtldCustLedgEntry2.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DtldCustLedgEntry2.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        DtldCustLedgEntry2.SetRange("Posting Date", EntryPostingDate);
        DtldCustLedgEntry2.SetRange(
          "Entry Type",
          DtldCustLedgEntry2."Entry Type"::"Realized Loss",
          DtldCustLedgEntry2."Entry Type"::"Realized Gain");
        DtldCustLedgEntry2.CalcSums("Amount (LCY)");

        TmpDtldCustLedgEntry2.SetRange("Posting Date", EntryPostingDate);
        TmpDtldCustLedgEntry2.CalcSums("Amount (LCY)");

        RealGainLossAmt := DtldCustLedgEntry2."Amount (LCY)" + TmpDtldCustLedgEntry2."Amount (LCY)";
    end;

    [Scope('OnPrem')]
    procedure CreateVendRealGainLossEntries(var DtldVendLedgEntry3: Record "Detailed Vendor Ledg. Entry")
    var
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry4: Record "Detailed Vendor Ledg. Entry";
    begin
        // NAVCZ
        TmpDtldVendLedgEntry2.Reset();
        TmpDtldVendLedgEntry2.DeleteAll();
        DtldVendLedgEntry4.Copy(DtldVendLedgEntry3);
        if DtldVendLedgEntry4.Find('-') then
            repeat
                DtldVendLedgEntry2.Reset();
                DtldVendLedgEntry2.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
                DtldVendLedgEntry2.SetRange("Vendor Ledger Entry No.", DtldVendLedgEntry4."Applied Vend. Ledger Entry No.");
                DtldVendLedgEntry2.SetRange(
                  "Entry Type",
                  DtldVendLedgEntry2."Entry Type"::"Realized Loss",
                  DtldVendLedgEntry2."Entry Type"::"Realized Gain");
                if DtldVendLedgEntry2.Find('-') then
                    repeat
                        if DtldVendLedgEntry2."Vendor Ledger Entry No." <> DtldVendLedgEntry4."Vendor Ledger Entry No." then begin
                            TmpDtldVendLedgEntry2.Init();
                            TmpDtldVendLedgEntry2.TransferFields(DtldVendLedgEntry2);
                            if TmpDtldVendLedgEntry2.Insert() then;
                        end;
                    until DtldVendLedgEntry2.Next() = 0;
            until DtldVendLedgEntry4.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CalcVendRealGainLossAmount(VendLedgEntryNo: Integer; EntryPostingDate: Date)
    var
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        // NAVCZ
        if not SummarizeEntries then
            RealGainLossAmt := 0;

        DtldVendLedgEntry2.Reset();
        DtldVendLedgEntry2.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        DtldVendLedgEntry2.SetRange("Vendor Ledger Entry No.", VendLedgEntryNo);
        DtldVendLedgEntry2.SetRange("Posting Date", EntryPostingDate);
        DtldVendLedgEntry2.SetRange(
          "Entry Type",
          DtldVendLedgEntry2."Entry Type"::"Realized Loss",
          DtldVendLedgEntry2."Entry Type"::"Realized Gain");
        DtldVendLedgEntry2.CalcSums("Amount (LCY)");

        TmpDtldVendLedgEntry2.SetRange("Posting Date", EntryPostingDate);
        TmpDtldVendLedgEntry2.CalcSums("Amount (LCY)");

        RealGainLossAmt := DtldVendLedgEntry2."Amount (LCY)" + TmpDtldVendLedgEntry2."Amount (LCY)";
    end;

    [Scope('OnPrem')]
    procedure GetInitialGLAccountNo(InitialEntryNo: Integer; SourceType: Option Customer,Vendor; PostingGroup: Code[20]): Code[20]
    var
        CustPostingGr: Record "Customer Posting Group";
        VendPostingGr: Record "Vendor Posting Group";
        GLEntry: Record "G/L Entry";
    begin
        // NAVCZ
        if GLEntry.Get(InitialEntryNo) then
            exit(GLEntry."G/L Account No.");

        if SourceType = SourceType::Customer then begin
            CustPostingGr.Get(PostingGroup);
            if CustLedgerEntry."Prepayment Type" <> CustLedgerEntry."Prepayment Type"::Advance then
                exit(CustPostingGr."Receivables Account");

            exit(CustPostingGr."Advance Account");
        end;
        if SourceType = SourceType::Vendor then begin
            VendPostingGr.Get(PostingGroup);
            if VendorLedgerEntry."Prepayment Type" <> VendorLedgerEntry."Prepayment Type"::Advance then
                exit(VendPostingGr."Payables Account");

            exit(VendPostingGr."Advance Account");
        end;
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnBeforeOnInitReport(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDtldCustLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDtldVendLedgerEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport(ExchRateAdjReg: Record "Exch. Rate Adjmt. Reg."; PostingDate: Date);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustomerAfterGetRecordOnAfterFindCustLedgerEntriesToAdjust(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustCustomerLedgerEntryOnBeforeInitDtldCustLedgEntry(var Customer: Record Customer; CusLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustVendorLedgerEntryOnBeforeInitDtldVendLedgEntry(var Vendor: Record Vendor; VendLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRealizedGainsAccount(Currency: Record Currency; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRealizedLossesAccount(Currency: Record Currency; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN19
    [Obsolete('To be replaced by new events after refactoring', '19.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPage(var AdjCustVendBank: Boolean; var AdjGLAcc: Boolean; var PostingDocNo: Code[20])
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustAdjmt(var AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var TempDimSetEntry: Record "Dimension Set Entry" temporary; var TempAdjExchRateBuffer: Record "Adjust Exchange Rate Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVendAdjmt(var AdjExchRateBuffer: Record "Adjust Exchange Rate Buffer"; var TempDtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer" temporary; var TempDimSetEntry: Record "Dimension Set Entry" temporary; var TempAdjExchRateBuffer: Record "Adjust Exchange Rate Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var DimSetEntry: Record "Dimension Set Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendorAfterGetRecordOnAfterFindVendLedgerEntriesToAdjust(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGenJnlLineOnAfterGenJnlPostLineRun(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostGenJnlLineOnBeforeGenJnlPostLineRun(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
}
#endif
