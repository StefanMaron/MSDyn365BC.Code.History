﻿namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Security.User;
using System.Utilities;

report 2 "General Journal - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/GeneralJournalTest.rdlc';
    Caption = 'General Journal - Test';
    PreviewMode = PrintLayout;

    dataset
    {
        dataitem("Gen. Journal Batch"; "Gen. Journal Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            column(JnlTmplName_GenJnlBatch; "Journal Template Name")
            {
            }
            column(Name_GenJnlBatch; Name)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GeneralJnlTestCaption; GeneralJnlTestCap)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(JnlTemplateName_GenJnlBatch; "Gen. Journal Batch"."Journal Template Name")
                {
                }
                column(JnlName_GenJnlBatch; "Gen. Journal Batch".Name)
                {
                }
                column(GenJnlLineFilter; GenJnlLineFilter)
                {
                }
                column(GenJnlLineFilterTableCaption; "Gen. Journal Line".TableCaption + ': ' + GenJnlLineFilter)
                {
                }
                column(Number_Integer; Number)
                {
                }
                column(PageNoCaption; PageNoCap)
                {
                }
                column(JnlTmplNameCaption_GenJnlBatch; "Gen. Journal Batch".FieldCaption("Journal Template Name"))
                {
                }
                column(JournalBatchCaption; JnlBatchNameCap)
                {
                }
                column(PostingDateCaption; PostingDateCap)
                {
                }
                column(DocumentTypeCaption; DocumentTypeCap)
                {
                }
                column(DocNoCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("Document No."))
                {
                }
                column(AccountTypeCaption; AccountTypeCap)
                {
                }
                column(AccNoCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("Account No."))
                {
                }
                column(AccNameCaption; AccNameCap)
                {
                }
                column(DescCaption_GenJnlLine; "Gen. Journal Line".FieldCaption(Description))
                {
                }
                column(PostingTypeCaption; GenPostingTypeCap)
                {
                }
                column(GenBusPostGroupCaption; GenBusPostingGroupCap)
                {
                }
                column(GenProdPostGroupCaption; GenProdPostingGroupCap)
                {
                }
                column(AmountCaption_GenJnlLine; "Gen. Journal Line".FieldCaption(Amount))
                {
                }
                column(BalAccNoCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("Bal. Account No."))
                {
                }
                column(BalLCYCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("Balance (LCY)"))
                {
                }
#if not CLEAN23
                column(VATCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("VAT Code"))
                {
                }
#endif
                column(VATNumberCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("VAT Number"))
                {
                }
                column(BalGenPostTypeCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("Bal. Gen. Posting Type"))
                {
                }
#if not CLEAN23
                column(BalVATCodeCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("Bal. VAT Code"))
                {
                }
#endif
                column(BalVATNumberCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("Bal. VAT Number"))
                {
                }
                dataitem("Gen. Journal Line"; "Gen. Journal Line")
                {
                    DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                    DataItemLinkReference = "Gen. Journal Batch";
                    DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
                    RequestFilterFields = "Posting Date";
                    column(PostingDate_GenJnlLine; Format("Posting Date"))
                    {
                    }
                    column(DocType_GenJnlLine; "Document Type")
                    {
                    }
                    column(DocNo_GenJnlLine; "Document No.")
                    {
                    }
                    column(ExtDocNo_GenJnlLine; "External Document No.")
                    {
                    }
                    column(AccountType_GenJnlLine; "Account Type")
                    {
                    }
                    column(AccountNo_GenJnlLine; "Account No.")
                    {
                    }
                    column(AccName; AccName)
                    {
                    }
                    column(Description_GenJnlLine; Description)
                    {
                    }
                    column(GenPostType_GenJnlLine; "Gen. Posting Type")
                    {
                    }
                    column(GenBusPosGroup_GenJnlLine; "Gen. Bus. Posting Group")
                    {
                    }
                    column(GenProdPostGroup_GenJnlLine; "Gen. Prod. Posting Group")
                    {
                    }
                    column(Amount_GenJnlLine; Amount)
                    {
                    }
                    column(CurrencyCode_GenJnlLine; "Currency Code")
                    {
                    }
                    column(BalAccNo_GenJnlLine; "Bal. Account No.")
                    {
                    }
                    column(BalanceLCY_GenJnlLine; "Balance (LCY)")
                    {
                    }
                    column(AmountLCY; AmountLCY)
                    {
                    }
                    column(BalanceLCY; BalanceLCY)
                    {
                    }
                    column(AmountLCY_GenJnlLine; "Amount (LCY)")
                    {
                    }
                    column(JnlTmplName_GenJnlLine; "Journal Template Name")
                    {
                    }
                    column(JnlBatchName_GenJnlLine; "Journal Batch Name")
                    {
                    }
                    column(LineNo_GenJnlLine; "Line No.")
                    {
                    }
                    column(TotalLCYCaption; AmountLCYCap)
                    {
                    }
#if not CLEAN23
                    column(VATCode_GenJnlLine; "VAT Code")
                    {
                    }
#endif
                    column(VATNumber_GenJnlLine; "VAT Number")
                    {
                    }
                    column(BalGenPostType_GenJnlLine; "Bal. Gen. Posting Type")
                    {
                    }
#if not CLEAN23
                    column(BalVATCode_GenJnlLine; "Bal. VAT Code")
                    {
                    }
#endif
                    column(BalVATNumber_GenJnlLine; "Bal. VAT Number")
                    {
                    }
                    dataitem(DimensionLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(Number_DimensionLoop; Number)
                        {
                        }
                        column(DimensionsCaption; DimensionsCap)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            DimText := GetDimensionText(DimSetEntry);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowDim then
                                CurrReport.Break();
                            DimSetEntry.Reset();
                            DimSetEntry.SetRange("Dimension Set ID", "Gen. Journal Line"."Dimension Set ID")
                        end;
                    }
                    dataitem("Gen. Jnl. Allocation"; "Gen. Jnl. Allocation")
                    {
                        DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field("Journal Batch Name"), "Journal Line No." = field("Line No.");
                        DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Journal Line No.", "Line No.");
                        column(AccountNo_GenJnlAllocation; "Account No.")
                        {
                        }
                        column(AccountName_GenJnlAllocation; "Account Name")
                        {
                        }
                        column(AllocationQuantity_GenJnlAllocation; "Allocation Quantity")
                        {
                        }
                        column(AllocationPct_GenJnlAllocation; "Allocation %")
                        {
                        }
                        column(Amount_GenJnlAllocation; Amount)
                        {
                        }
                        column(JournalLineNo_GenJnlAllocation; "Journal Line No.")
                        {
                        }
                        column(LineNo_GenJnlAllocation; "Line No.")
                        {
                        }
                        column(JournalBatchName_GenJnlAllocation; "Journal Batch Name")
                        {
                        }
                        column(AccountNoCaption_GenJnlAllocation; FieldCaption("Account No."))
                        {
                        }
                        column(AccountNameCaption_GenJnlAllocation; FieldCaption("Account Name"))
                        {
                        }
                        column(AllocationQuantityCaption_GenJnlAllocation; FieldCaption("Allocation Quantity"))
                        {
                        }
                        column(AllocationPctCaption_GenJnlAllocation; FieldCaption("Allocation %"))
                        {
                        }
                        column(AmountCaption_GenJnlAllocation; FieldCaption(Amount))
                        {
                        }
                        column(Recurring_GenJnlTemplate; GenJnlTemplate.Recurring)
                        {
                        }
                        dataitem(DimensionLoopAllocations; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(AllocationDimText; AllocationDimText)
                            {
                            }
                            column(Number_DimensionLoopAllocations; Number)
                            {
                            }
                            column(DimensionAllocationsCaption; DimensionAllocationsCap)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry.FindFirst() then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                AllocationDimText := GetDimensionText(DimSetEntry);
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowDim then
                                    CurrReport.Break();
                                DimSetEntry.Reset();
                                DimSetEntry.SetRange("Dimension Set ID", "Gen. Jnl. Allocation"."Dimension Set ID")
                            end;
                        }
                    }
                    dataitem(ErrorLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorTextNumber; ErrorText[Number])
                        {
                        }
                        column(WarningCaption; WarningCap)
                        {
                        }

                        trigger OnPostDataItem()
                        begin
                            ErrorCounter := 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, ErrorCounter);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    var
                        PaymentTerms: Record "Payment Terms";
                        UserSetupManagement: Codeunit "User Setup Management";
                    begin
                        OnBeforeGenJournalLineOnAfterGetRecord("Gen. Journal Line", "Gen. Journal Batch", GenJnlTemplate);

                        if "Currency Code" = '' then
                            "Amount (LCY)" := Amount;

                        UpdateLineBalance();

                        AccName := '';
                        BalAccName := '';

                        if not EmptyLine() then begin
                            MakeRecurringTexts("Gen. Journal Line");

                            AmountError := false;

                            if ("Account No." = '') and ("Bal. Account No." = '') then
                                AddError(StrSubstNo(Text001, FieldCaption("Account No."), FieldCaption("Bal. Account No.")))
                            else
                                if ("Account Type" <> "Account Type"::"Fixed Asset") and
                                   ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
                                then
                                    TestFixedAssetFields("Gen. Journal Line");
                            CheckICDocument();
                            if "Account No." <> '' then
                                case "Account Type" of
                                    "Account Type"::"G/L Account":
                                        begin
                                            if ("Gen. Bus. Posting Group" <> '') or ("Gen. Prod. Posting Group" <> '') or
                                               ("VAT Bus. Posting Group" <> '') or ("VAT Prod. Posting Group" <> '')
                                            then begin
                                                if "Gen. Posting Type" = "Gen. Posting Type"::" " then
                                                    AddError(StrSubstNo(Text002, FieldCaption("Gen. Posting Type")));
                                            end;
                                            if ("Gen. Posting Type" <> "Gen. Posting Type"::" ") and
                                               ("VAT Posting" = "VAT Posting"::"Automatic VAT Entry")
                                            then begin
                                                if "VAT Amount" + "VAT Base Amount" <> Amount then
                                                    AddError(
                                                      StrSubstNo(
                                                        Text003, FieldCaption("VAT Amount"), FieldCaption("VAT Base Amount"),
                                                        FieldCaption(Amount)));
                                                if "Currency Code" <> '' then
                                                    if "VAT Amount (LCY)" + "VAT Base Amount (LCY)" <> "Amount (LCY)" then
                                                        AddError(
                                                          StrSubstNo(
                                                            Text003, FieldCaption("VAT Amount (LCY)"),
                                                            FieldCaption("VAT Base Amount (LCY)"), FieldCaption("Amount (LCY)")));
                                            end;
                                            TestJobFields("Gen. Journal Line");

                                            OnAfterGetRecordGenJournalLineOnAfterCheckAccTypeGLAccAccNo("Gen. Journal Line");
                                        end;
                                    "Account Type"::Customer, "Account Type"::Vendor:
                                        begin
                                            if "Gen. Posting Type" <> "Gen. Posting Type"::" " then
                                                AddError(
                                                  StrSubstNo(
                                                    Text004,
                                                    FieldCaption("Gen. Posting Type"), FieldCaption("Account Type"), "Account Type"));
                                            if ("Gen. Bus. Posting Group" <> '') or ("Gen. Prod. Posting Group" <> '') or
                                               ("VAT Bus. Posting Group" <> '') or ("VAT Prod. Posting Group" <> '')
                                            then
                                                AddError(
                                                  StrSubstNo(
                                                    Text005,
                                                    FieldCaption("Gen. Bus. Posting Group"), FieldCaption("Gen. Prod. Posting Group"),
                                                    FieldCaption("VAT Bus. Posting Group"), FieldCaption("VAT Prod. Posting Group"),
                                                    FieldCaption("Account Type"), "Account Type"));

                                            if "Document Type" <> "Document Type"::" " then begin
                                                if "Account Type" = "Account Type"::Customer then
                                                    case "Document Type" of
                                                        "Document Type"::"Credit Memo":
                                                            WarningIfPositiveAmt("Gen. Journal Line");
                                                        "Document Type"::Payment:
                                                            if ("Applies-to Doc. Type" = "Applies-to Doc. Type"::"Credit Memo") and
                                                               ("Applies-to Doc. No." <> '')
                                                            then
                                                                WarningIfNegativeAmt("Gen. Journal Line")
                                                            else
                                                                WarningIfPositiveAmt("Gen. Journal Line");
                                                        "Document Type"::Refund:
                                                            WarningIfNegativeAmt("Gen. Journal Line");
                                                        else
                                                            WarningIfNegativeAmt("Gen. Journal Line");
                                                    end
                                                else
                                                    case "Document Type" of
                                                        "Document Type"::"Credit Memo":
                                                            WarningIfNegativeAmt("Gen. Journal Line");
                                                        "Document Type"::Payment:
                                                            if ("Applies-to Doc. Type" = "Applies-to Doc. Type"::"Credit Memo") and
                                                               ("Applies-to Doc. No." <> '')
                                                            then
                                                                WarningIfPositiveAmt("Gen. Journal Line")
                                                            else
                                                                WarningIfNegativeAmt("Gen. Journal Line");
                                                        "Document Type"::Refund:
                                                            WarningIfPositiveAmt("Gen. Journal Line");
                                                        else
                                                            WarningIfPositiveAmt("Gen. Journal Line");
                                                    end
                                            end;

                                            if Amount * "Sales/Purch. (LCY)" < 0 then
                                                AddError(
                                                  StrSubstNo(
                                                    Text008,
                                                    FieldCaption("Sales/Purch. (LCY)"), FieldCaption(Amount)));
                                            if "Job No." <> '' then
                                                AddError(StrSubstNo(Text009, FieldCaption("Job No.")));
                                        end;
                                    "Account Type"::"Bank Account":
                                        begin
                                            if "Gen. Posting Type" <> "Gen. Posting Type"::" " then
                                                AddError(
                                                  StrSubstNo(
                                                    Text004,
                                                    FieldCaption("Gen. Posting Type"), FieldCaption("Account Type"), "Account Type"));
                                            if ("Gen. Bus. Posting Group" <> '') or ("Gen. Prod. Posting Group" <> '') or
                                               ("VAT Bus. Posting Group" <> '') or ("VAT Prod. Posting Group" <> '')
                                            then
                                                AddError(
                                                  StrSubstNo(
                                                    Text005,
                                                    FieldCaption("Gen. Bus. Posting Group"), FieldCaption("Gen. Prod. Posting Group"),
                                                    FieldCaption("VAT Bus. Posting Group"), FieldCaption("VAT Prod. Posting Group"),
                                                    FieldCaption("Account Type"), "Account Type"));

                                            if "Job No." <> '' then
                                                AddError(StrSubstNo(Text009, FieldCaption("Job No.")));
                                            if (Amount < 0) and ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") then
                                                if not "Check Printed" then
                                                    AddError(StrSubstNo(Text010, FieldCaption("Check Printed")));
                                        end;
                                    "Account Type"::"Fixed Asset":
                                        TestFixedAsset("Gen. Journal Line");
                                end;

                            if "Bal. Account No." <> '' then
                                case "Bal. Account Type" of
                                    "Bal. Account Type"::"G/L Account":
                                        begin
                                            if ("Bal. Gen. Bus. Posting Group" <> '') or ("Bal. Gen. Prod. Posting Group" <> '') or
                                               ("Bal. VAT Bus. Posting Group" <> '') or ("Bal. VAT Prod. Posting Group" <> '')
                                            then begin
                                                if "Bal. Gen. Posting Type" = "Bal. Gen. Posting Type"::" " then
                                                    AddError(StrSubstNo(Text002, FieldCaption("Bal. Gen. Posting Type")));
                                            end;
                                            if ("Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" ") and
                                               ("VAT Posting" = "VAT Posting"::"Automatic VAT Entry")
                                            then begin
                                                if "Bal. VAT Amount" + "Bal. VAT Base Amount" <> -Amount then
                                                    AddError(
                                                      StrSubstNo(
                                                        Text011, FieldCaption("Bal. VAT Amount"), FieldCaption("Bal. VAT Base Amount"),
                                                        FieldCaption(Amount)));
                                                if "Currency Code" <> '' then
                                                    if "Bal. VAT Amount (LCY)" + "Bal. VAT Base Amount (LCY)" <> -"Amount (LCY)" then
                                                        AddError(
                                                          StrSubstNo(
                                                            Text011, FieldCaption("Bal. VAT Amount (LCY)"),
                                                            FieldCaption("Bal. VAT Base Amount (LCY)"), FieldCaption("Amount (LCY)")));
                                            end;
                                            OnAfterGetRecordGenJournalLineOnAfterCheckBalAccTypeGLAccBalAccNo("Gen. Journal Line");
                                        end;
                                    "Bal. Account Type"::Customer, "Bal. Account Type"::Vendor:
                                        begin
                                            if "Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" " then
                                                AddError(
                                                  StrSubstNo(
                                                    Text004,
                                                    FieldCaption("Bal. Gen. Posting Type"), FieldCaption("Bal. Account Type"), "Bal. Account Type"));
                                            if ("Bal. Gen. Bus. Posting Group" <> '') or ("Bal. Gen. Prod. Posting Group" <> '') or
                                               ("Bal. VAT Bus. Posting Group" <> '') or ("Bal. VAT Prod. Posting Group" <> '')
                                            then
                                                AddError(
                                                  StrSubstNo(
                                                    Text005,
                                                    FieldCaption("Bal. Gen. Bus. Posting Group"), FieldCaption("Bal. Gen. Prod. Posting Group"),
                                                    FieldCaption("Bal. VAT Bus. Posting Group"), FieldCaption("Bal. VAT Prod. Posting Group"),
                                                    FieldCaption("Bal. Account Type"), "Bal. Account Type"));

                                            if "Document Type" <> "Document Type"::" " then begin
                                                if ("Bal. Account Type" = "Bal. Account Type"::Customer) =
                                                   ("Document Type" in ["Document Type"::Payment, "Document Type"::"Credit Memo"])
                                                then
                                                    WarningIfNegativeAmt("Gen. Journal Line")
                                                else
                                                    WarningIfPositiveAmt("Gen. Journal Line")
                                            end;
                                            if Amount * "Sales/Purch. (LCY)" > 0 then
                                                AddError(
                                                  StrSubstNo(
                                                    Text012,
                                                    FieldCaption("Sales/Purch. (LCY)"), FieldCaption(Amount)));
                                            if "Job No." <> '' then
                                                AddError(StrSubstNo(Text009, FieldCaption("Job No.")));
                                        end;
                                    "Bal. Account Type"::"Bank Account":
                                        begin
                                            if "Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" " then
                                                AddError(
                                                  StrSubstNo(
                                                    Text004,
                                                    FieldCaption("Bal. Gen. Posting Type"), FieldCaption("Bal. Account Type"), "Bal. Account Type"));
                                            if ("Bal. Gen. Bus. Posting Group" <> '') or ("Bal. Gen. Prod. Posting Group" <> '') or
                                               ("Bal. VAT Bus. Posting Group" <> '') or ("Bal. VAT Prod. Posting Group" <> '')
                                            then
                                                AddError(
                                                  StrSubstNo(
                                                    Text005,
                                                    FieldCaption("Bal. Gen. Bus. Posting Group"), FieldCaption("Bal. Gen. Prod. Posting Group"),
                                                    FieldCaption("Bal. VAT Bus. Posting Group"), FieldCaption("Bal. VAT Prod. Posting Group"),
                                                    FieldCaption("Bal. Account Type"), "Bal. Account Type"));

                                            if "Job No." <> '' then
                                                AddError(StrSubstNo(Text009, FieldCaption("Job No.")));
                                            if (Amount > 0) and ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") then
                                                if not "Check Printed" then
                                                    AddError(StrSubstNo(Text010, FieldCaption("Check Printed")));
                                        end;
                                    "Bal. Account Type"::"Fixed Asset":
                                        TestFixedAsset("Gen. Journal Line");
                                end;

                            if ("Account No." <> '') and
                               not "System-Created Entry" and
                               (Amount = 0) and
                               not GenJnlTemplate.Recurring and
                               not "Allow Zero-Amount Posting" and
                               ("Account Type" <> "Account Type"::"Fixed Asset")
                            then
                                WarningIfZeroAmt("Gen. Journal Line");

                            CheckRecurringLine("Gen. Journal Line");
                            CheckAllocations("Gen. Journal Line");

                            if "Posting Date" = 0D then
                                AddError(StrSubstNo(Text002, FieldCaption("Posting Date")))
                            else begin
                                if "Posting Date" <> NormalDate("Posting Date") then
                                    if ("Account Type" <> "Account Type"::"G/L Account") or
                                       ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account")
                                    then
                                        AddError(
                                          StrSubstNo(
                                            Text013, FieldCaption("Posting Date")));

                                if not UserSetupManagement.TestAllowedPostingDate("Posting Date", TempErrorText) then
                                    AddError(TempErrorText);

                                if "Gen. Journal Batch"."No. Series" <> '' then begin
                                    if NoSeries."Date Order" and ("Posting Date" < LastEntrdDate) then
                                        AddError(Text015);
                                    LastEntrdDate := "Posting Date";
                                end;
                            end;

                            if "Document Date" <> 0D then
                                if ("Document Date" <> NormalDate("Document Date")) and
                                   (("Account Type" <> "Account Type"::"G/L Account") or
                                    ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account"))
                                then
                                    AddError(
                                      StrSubstNo(
                                        Text013, FieldCaption("Document Date")));

                            if "Document No." = '' then
                                AddError(StrSubstNo(Text002, FieldCaption("Document No.")))
                            else
                                if "Gen. Journal Batch"."No. Series" <> '' then
                                    if IsGapInNosForDocNo("Gen. Journal Line") then
                                        AddError(Text016);

                            if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset"]) and
                               ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset"])
                            then
                                AddError(
                                  StrSubstNo(
                                    Text017,
                                    FieldCaption("Account Type"), FieldCaption("Bal. Account Type")));

                            if Amount * "Amount (LCY)" < 0 then
                                AddError(
                                  StrSubstNo(
                                    Text008, FieldCaption("Amount (LCY)"), FieldCaption(Amount)));

                            if ("Account Type" = "Account Type"::"G/L Account") and
                               ("Bal. Account Type" = "Bal. Account Type"::"G/L Account")
                            then
                                if "Applies-to Doc. No." <> '' then
                                    AddError(StrSubstNo(Text009, FieldCaption("Applies-to Doc. No.")));

                            if (("Account Type" = "Account Type"::"G/L Account") and
                                ("Bal. Account Type" = "Bal. Account Type"::"G/L Account")) or
                               ("Document Type" <> "Document Type"::Invoice)
                            then
                                if PaymentTerms.Get("Payment Terms Code") then begin
                                    if ("Document Type" = "Document Type"::"Credit Memo") and
                                       (not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos")
                                    then begin
                                        if "Pmt. Discount Date" <> 0D then
                                            AddError(StrSubstNo(Text009, FieldCaption("Pmt. Discount Date")));
                                        if "Payment Discount %" <> 0 then
                                            AddError(StrSubstNo(Text018, FieldCaption("Payment Discount %")));
                                    end;
                                end else begin
                                    if "Pmt. Discount Date" <> 0D then
                                        AddError(StrSubstNo(Text009, FieldCaption("Pmt. Discount Date")));
                                    if "Payment Discount %" <> 0 then
                                        AddError(StrSubstNo(Text018, FieldCaption("Payment Discount %")));
                                end;

                            if (("Account Type" = "Account Type"::"G/L Account") and
                                ("Bal. Account Type" = "Bal. Account Type"::"G/L Account")) or
                               ("Applies-to Doc. No." <> '')
                            then
                                if "Applies-to ID" <> '' then
                                    AddError(StrSubstNo(Text009, FieldCaption("Applies-to ID")));

                            if ("Account Type" <> "Account Type"::"Bank Account") and
                               ("Bal. Account Type" <> "Bal. Account Type"::"Bank Account")
                            then
                                if GenJnlLine2."Bank Payment Type" <> GenJnlLine2."Bank Payment Type"::" " then
                                    AddError(StrSubstNo(Text009, FieldCaption("Bank Payment Type")));

                            if ("Account No." <> '') and ("Bal. Account No." <> '') then begin
                                PurchPostingType := false;
                                SalesPostingType := false;
                            end;
                            if "Account No." <> '' then
                                CheckAccountTypes("Account Type", AccName);
                            if "Bal. Account No." <> '' then begin
                                CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", "Gen. Journal Line");
                                CheckAccountTypes("Account Type", BalAccName);
                                CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", "Gen. Journal Line");
                            end;

                            CheckDimensions("Gen. Journal Line");

                            OnAfterCheckGenJnlLine("Gen. Journal Line", ErrorCounter, ErrorText);
                        end;

                        CheckBalance();
                        AmountLCY += "Amount (LCY)";
                        BalanceLCY += "Balance (LCY)";
                    end;

                    trigger OnPreDataItem()
                    begin
                        CopyFilter("Journal Batch Name", "Gen. Journal Batch".Name);
                        GenJnlLineFilter := GetFilters();

                        GenJnlTemplate.Get("Gen. Journal Batch"."Journal Template Name");
                        if GenJnlTemplate.Recurring then begin
                            if GetFilter("Posting Date") <> '' then
                                AddError(
                                  StrSubstNo(
                                    Text000,
                                    FieldCaption("Posting Date")));
                            SetRange("Posting Date", 0D, WorkDate());
                            if GetFilter("Expiration Date") <> '' then
                                AddError(
                                  StrSubstNo(
                                    Text000,
                                    FieldCaption("Expiration Date")));
                            SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate());
                        end;

                        // If simple view is used then order gen. journal lines by doc no. and line no.
                        if not GenJnlTemplate.Recurring then
                            if GenJnlManagement.GetJournalSimplePageModePreference(PAGE::"General Journal") then
                                SetCurrentKey("Document No.", "Line No.");

                        LastEnteredDocNo := '';
                        if "Gen. Journal Batch"."No. Series" <> '' then begin
                            NoSeries.Get("Gen. Journal Batch"."No. Series");
                            LastEnteredDocNo := GetLastEnteredDocumentNo("Gen. Journal Line");
                            LastEntrdDate := 0D;
                        end;

                        TempGenJournalLineCustVendIC.Reset();
                        TempGenJournalLineCustVendIC.DeleteAll();
                        VATEntryCreated := false;

                        GenJnlLine2.Reset();
                        GenJnlLine2.CopyFilters("Gen. Journal Line");

                        GLAccNetChange.DeleteAll();
                    end;
                }
                dataitem(ReconcileLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(GLAccNetChangeNo; GLAccNetChange."No.")
                    {
                    }
                    column(GLAccNetChangeName; GLAccNetChange.Name)
                    {
                    }
                    column(GLAccNetChangeNetChangeJnl; GLAccNetChange."Net Change in Jnl.")
                    {
                    }
                    column(GLAccNetChangeBalafterPost; GLAccNetChange."Balance after Posting")
                    {
                    }
                    column(ReconciliationCaption; ReconciliationCap)
                    {
                    }
                    column(NoCaption; NoCap)
                    {
                    }
                    column(NameCaption; NameCap)
                    {
                    }
                    column(NetChangeinJnlCaption; NetChangeinJnlCap)
                    {
                    }
                    column(BalafterPostingCaption; BalafterPostingCap)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            GLAccNetChange.Find('-')
                        else
                            GLAccNetChange.Next();
                    end;

                    trigger OnPostDataItem()
                    begin
                        GLAccNetChange.DeleteAll();
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, GLAccNetChange.Count);
                    end;
                }
            }

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                SalesSetup.Get();
                PurchSetup.Get();
                AmountLCY := 0;
                BalanceLCY := 0;

                if (GetFilter(Name) = '') and (GetFilter("Journal Template Name") = '') then begin
                    "Gen. Journal Line".CopyFilter("Journal Batch Name", Name);
                    "Gen. Journal Line".CopyFilter("Journal Template Name", "Journal Template Name");
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
                    field(ShowDim; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines to be included in the report.';
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
        Text000: Label '%1 cannot be filtered when you post recurring journals.';
        Text001: Label '%1 or %2 must be specified.';
        Text002: Label '%1 must be specified.';
        Text003: Label '%1 + %2 must be %3.';
        Text004: Label '%1 must be " " when %2 is %3.';
        Text005: Label '%1, %2, %3 or %4 must not be completed when %5 is %6.';
        Text006: Label '%1 must be negative.';
        Text007: Label '%1 must be positive.';
        Text008: Label '%1 must have the same sign as %2.';
        Text009: Label '%1 cannot be specified.';
        Text010: Label '%1 must be Yes.';
        Text011: Label '%1 + %2 must be -%3.';
        Text012: Label '%1 must have a different sign than %2.';
        Text013: Label '%1 must only be a closing date for G/L entries.';
        Text015: Label 'The lines are not listed according to Posting Date because they were not entered in that order.';
        Text016: Label 'There is a gap in the number series.';
        Text017: Label '%1 or %2 must be G/L Account or Bank Account.';
        Text018: Label '%1 must be 0.';
        Text019: Label '%1 cannot be specified when using recurring journals.';
        Text020: Label '%1 must not be %2 when %3 = %4.';
        Text021: Label 'Allocations can only be used with recurring journals.';
        Text022: Label 'Specify %1 in the %2 allocation lines.';
        Text024: Label '%1 %2 posted on %3, must be separated by an empty line.', Comment = '%1 - document type, %2 - document number, %3 - posting date';
        Text025: Label '%1 %2 is out of balance by %3.';
        Text026: Label 'The reversing entries for %1 %2 are out of balance by %3.';
        Text027: Label 'As of %1, the lines are out of balance by %2.';
        Text028: Label 'As of %1, the reversing entries are out of balance by %2.';
        Text029: Label 'The total of the lines is out of balance by %1.';
        Text030: Label 'The total of the reversing entries is out of balance by %1.';
        Text031: Label '%1 %2 does not exist.';
        Text032: Label '%1 must be %2 for %3 %4.';
        Text036: Label '%1 %2 %3 does not exist.';
        Text037: Label '%1 must be %2.';
        Text038: Label 'The currency %1 cannot be found. Check the currency table.';
        Text039: Label 'Sales %1 %2 already exists.';
        Text040: Label 'Purchase %1 %2 already exists.';
        Text041: Label '%1 must be entered.';
        Text042: Label '%1 must not be filled when %2 is different in %3 and %4.';
        Text043: Label '%1 %2 must not have %3 = %4.';
        Text044: Label '%1 must not be specified in fixed asset journal lines.';
        Text045: Label '%1 must be specified in fixed asset journal lines.';
        Text046: Label '%1 must be different than %2.';
        Text047: Label '%1 and %2 must not both be %3.';
        Text049: Label '%1 must not be specified when %2 = %3.';
        Text050: Label 'must not be specified together with %1 = %2.';
        Text051: Label '%1 must be identical to %2.';
        Text052: Label '%1 cannot be a closing date.';
        Text053: Label '%1 is not within your range of allowed posting dates.';
        Text054: Label 'Insurance integration is not activated for %1 %2.';
        Text055: Label 'must not be specified when %1 is specified.';
        Text056: Label 'When G/L integration is not activated, %1 must not be posted in the general journal.';
        Text057: Label 'When G/L integration is not activated, %1 must not be specified in the general journal.';
        Text058: Label '%1 must not be specified.';
        Text059: Label 'The combination of Customer and Gen. Posting Type Purchase is not allowed.';
        Text060: Label 'The combination of Vendor and Gen. Posting Type Sales is not allowed.';
        Text061: Label 'The Balance and Reversing Balance recurring methods can be used only with Allocations.';
        Text062: Label '%1 must not be 0.';
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        UserSetup: Record "User Setup";
        AccountingPeriod: Record "Accounting Period";
        GLAcc: Record "G/L Account";
        Currency: Record Currency;
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAccPostingGr: Record "Bank Account Posting Group";
        BankAcc: Record "Bank Account";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine2: Record "Gen. Journal Line";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        TempGenJournalLineCustVendIC: Record "Gen. Journal Line" temporary;
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        OldCustLedgEntry: Record "Cust. Ledger Entry";
        OldVendLedgEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        NoSeries: Record "No. Series";
        FA: Record "Fixed Asset";
        ICPartner: Record "IC Partner";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        GLAccNetChange: Record "G/L Account Net Change" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        Employee: Record Employee;
        GenJnlManagement: Codeunit GenJnlManagement;
        GenJnlLineFilter: Text;
        AllowFAPostingFrom: Date;
        AllowFAPostingTo: Date;
        LastDate: Date;
        LastDocType: Enum "Gen. Journal Document Type";
        LastDocNo: Code[20];
        LastEnteredDocNo: Code[20];
        LastEntrdDate: Date;
        BalanceLCY: Decimal;
        AmountLCY: Decimal;
        DocBalanceReverse: Decimal;
        DateBalanceReverse: Decimal;
        TotalBalanceReverse: Decimal;
        AccName: Text[100];
        LastLineNo: Integer;
        AmountError: Boolean;
        ErrorCounter: Integer;
        ErrorText: array[50] of Text[250];
        TempErrorText: Text[250];
        BalAccName: Text[100];
        VATEntryCreated: Boolean;
        CustPosting: Boolean;
        VendPosting: Boolean;
        SalesPostingType: Boolean;
        PurchPostingType: Boolean;
        DimText: Text[75];
        AllocationDimText: Text[75];
        ShowDim: Boolean;
        Continue: Boolean;
        Text064: Label '%1 %2 is already used in line %3 (%4 %5).';
        Text065: Label '%1 must not be blocked with type %2 when %3 is %4.';
        CurrentICPartner: Code[20];
        Text066: Label 'You cannot enter G/L Account or Bank Account in both %1 and %2.';
        Text067: Label '%1 %2 is linked to %3 %4.';
        Text069: Label '%1 must not be specified when %2 is %3.';
        Text070: Label '%1 must not be specified when the document is not an intercompany transaction.';
        Text071: Label '%1 %2 does not exist.';
        Text072: Label '%1 must not be %2 for %3 %4.';
        Text073: Label '%1 %2 already exists.';
        GeneralJnlTestCap: Label 'General Journal - Test';
        PageNoCap: Label 'Page';
        JnlBatchNameCap: Label 'Journal Batch';
        PostingDateCap: Label 'Posting Date';
        DocumentTypeCap: Label 'Document Type';
        AccountTypeCap: Label 'Account Type';
        AccNameCap: Label 'Name';
        GenPostingTypeCap: Label 'Gen. Posting Type';
        GenBusPostingGroupCap: Label 'Gen. Bus. Posting Group';
        GenProdPostingGroupCap: Label 'Gen. Prod. Posting Group';
        AmountLCYCap: Label 'Total (LCY)';
        DimensionsCap: Label 'Dimensions';
        WarningCap: Label 'Warning!';
        ReconciliationCap: Label 'Reconciliation';
        NoCap: Label 'No.';
        NameCap: Label 'Name';
        NetChangeinJnlCap: Label 'Net Change in Jnl.';
        BalafterPostingCap: Label 'Balance after Posting';
        DimensionAllocationsCap: Label 'Allocation Dimensions';

    local procedure CheckRecurringLine(GenJnlLine2: Record "Gen. Journal Line")
    begin
        with GenJnlLine2 do
            if GenJnlTemplate.Recurring then begin
                if "Recurring Method" = "Recurring Method"::" " then
                    AddError(StrSubstNo(Text002, FieldCaption("Recurring Method")));
                if Format("Recurring Frequency") = '' then
                    AddError(StrSubstNo(Text002, FieldCaption("Recurring Frequency")));
                if "Bal. Account No." <> '' then
                    AddError(
                      StrSubstNo(
                        Text019,
                        FieldCaption("Bal. Account No.")));
                case "Recurring Method" of
                    "Recurring Method"::"V  Variable", "Recurring Method"::"RV Reversing Variable",
                  "Recurring Method"::"F  Fixed", "Recurring Method"::"RF Reversing Fixed":
                        WarningIfZeroAmt("Gen. Journal Line");
                    "Recurring Method"::"B  Balance", "Recurring Method"::"RB Reversing Balance":
                        WarningIfNonZeroAmt("Gen. Journal Line");
                end;
                if "Recurring Method".AsInteger() > "Recurring Method"::"V  Variable".AsInteger() then begin
                    if "Account Type" = "Account Type"::"Fixed Asset" then
                        AddError(
                          StrSubstNo(
                            Text020,
                            FieldCaption("Recurring Method"), "Recurring Method",
                            FieldCaption("Account Type"), "Account Type"));
                    if "Bal. Account Type" = "Bal. Account Type"::"Fixed Asset" then
                        AddError(
                          StrSubstNo(
                            Text020,
                            FieldCaption("Recurring Method"), "Recurring Method",
                            FieldCaption("Bal. Account Type"), "Bal. Account Type"));
                end;
            end else begin
                if "Recurring Method" <> "Recurring Method"::" " then
                    AddError(StrSubstNo(Text009, FieldCaption("Recurring Method")));
                if Format("Recurring Frequency") <> '' then
                    AddError(StrSubstNo(Text009, FieldCaption("Recurring Frequency")));
            end;
    end;

    local procedure CheckAllocations(GenJnlLine2: Record "Gen. Journal Line")
    begin
        with GenJnlLine2 do begin
            if "Recurring Method" in
               ["Recurring Method"::"B  Balance",
                "Recurring Method"::"RB Reversing Balance"]
            then begin
                GenJnlAlloc.Reset();
                GenJnlAlloc.SetRange("Journal Template Name", "Journal Template Name");
                GenJnlAlloc.SetRange("Journal Batch Name", "Journal Batch Name");
                GenJnlAlloc.SetRange("Journal Line No.", "Line No.");
                if not GenJnlAlloc.FindFirst() then
                    AddError(Text061);
            end;

            GenJnlAlloc.Reset();
            GenJnlAlloc.SetRange("Journal Template Name", "Journal Template Name");
            GenJnlAlloc.SetRange("Journal Batch Name", "Journal Batch Name");
            GenJnlAlloc.SetRange("Journal Line No.", "Line No.");
            GenJnlAlloc.SetFilter(Amount, '<>0');
            if GenJnlAlloc.FindFirst() then
                if not GenJnlTemplate.Recurring then
                    AddError(Text021)
                else begin
                    GenJnlAlloc.SetRange("Account No.", '');
                    if GenJnlAlloc.FindFirst() then
                        AddError(
                          StrSubstNo(
                            Text022,
                            GenJnlAlloc.FieldCaption("Account No."), GenJnlAlloc.Count));
                end;
        end;
    end;

    local procedure MakeRecurringTexts(var GenJnlLine2: Record "Gen. Journal Line")
    begin
        with GenJnlLine2 do
            if ("Posting Date" <> 0D) and ("Account No." <> '') and ("Recurring Method" <> "Recurring Method"::" ") then
                AccountingPeriod.MakeRecurringTexts("Posting Date", "Document No.", Description);
    end;

    local procedure CheckBalance()
    var
        GenJnlLine: Record "Gen. Journal Line";
        NextGenJnlLine: Record "Gen. Journal Line";
        DocBalance: Decimal;
        DateBalance: Decimal;
        TotalBalance: Decimal;
    begin
        GenJnlLine.Copy("Gen. Journal Line");
        LastLineNo := "Gen. Journal Line"."Line No.";
        NextGenJnlLine.Copy("Gen. Journal Line");
        NextGenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        NextGenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        if NextGenJnlLine.Next() = 0 then;
        MakeRecurringTexts(NextGenJnlLine);
        with GenJnlLine do
            if not EmptyLine() then begin
                DocBalance := CalculateDocBalance(GenJnlLine);
                DateBalance := CalculateDateBalance(GenJnlLine);
                TotalBalance := CalculateTotalBalance(GenJnlLine);
                if "Recurring Method".AsInteger() >= "Recurring Method"::"RF Reversing Fixed".AsInteger() then begin
                    DocBalanceReverse := DocBalanceReverse + "Balance (LCY)";
                    DateBalanceReverse := DateBalanceReverse + "Balance (LCY)";
                    TotalBalanceReverse := TotalBalanceReverse + "Balance (LCY)";
                end;
                LastDocType := "Document Type";
                LastDocNo := "Document No.";
                LastDate := "Posting Date";
                if TotalBalance = 0 then
                    VATEntryCreated := false;
                if GenJnlTemplate."Force Doc. Balance" then begin
                    VATEntryCreated :=
                      VATEntryCreated or
                      (("Account Type" = "Account Type"::"G/L Account") and ("Account No." <> '') and
                       ("Gen. Posting Type" in ["Gen. Posting Type"::Purchase, "Gen. Posting Type"::Sale])) or
                      (("Bal. Account Type" = "Bal. Account Type"::"G/L Account") and ("Bal. Account No." <> '') and
                       ("Bal. Gen. Posting Type" in ["Bal. Gen. Posting Type"::Purchase, "Bal. Gen. Posting Type"::Sale]));
                    TempGenJournalLineCustVendIC.IsCustVendICAdded(GenJnlLine);
                    if (TempGenJournalLineCustVendIC.Count > 1) and VATEntryCreated then
                        AddError(
                          StrSubstNo(
                            Text024,
                            "Document Type", "Document No.", "Posting Date"));
                end;
            end;

        with NextGenJnlLine do begin
            if (LastDate <> 0D) and (LastDocNo <> '') and
               (("Posting Date" <> LastDate) or
                ("Document Type" <> LastDocType) or
                ("Document No." <> LastDocNo) or
                ("Line No." = LastLineNo))
            then begin
                if GenJnlTemplate."Force Doc. Balance" then begin
                    case true of
                        DocBalance <> 0:
                            AddError(StrSubstNo(Text025, LastDocType, LastDocNo, DocBalance));
                        DocBalanceReverse <> 0:
                            AddError(StrSubstNo(Text026, LastDocType, LastDocNo, DocBalanceReverse));
                    end;
                    DocBalanceReverse := 0;
                end;
                if ("Posting Date" <> LastDate) or
                   ("Document Type" <> LastDocType) or ("Document No." <> LastDocNo)
                then begin
                    TempGenJournalLineCustVendIC.Reset();
                    TempGenJournalLineCustVendIC.DeleteAll();
                    VATEntryCreated := false;
                    CustPosting := false;
                    VendPosting := false;
                    SalesPostingType := false;
                    PurchPostingType := false;
                end;
            end;

            if (LastDate <> 0D) and (("Posting Date" <> LastDate) or ("Line No." = LastLineNo)) then begin
                case true of
                    DateBalance <> 0:
                        AddError(
                          StrSubstNo(
                            Text027,
                            LastDate, DateBalance));
                    DateBalanceReverse <> 0:
                        AddError(
                          StrSubstNo(
                            Text028,
                            LastDate, DateBalanceReverse));
                end;
                DocBalanceReverse := 0;
                DateBalanceReverse := 0;
            end;

            if "Line No." = LastLineNo then begin
                case true of
                    TotalBalance <> 0:
                        AddError(
                          StrSubstNo(
                            Text029,
                            TotalBalance));
                    TotalBalanceReverse <> 0:
                        AddError(
                          StrSubstNo(
                            Text030,
                            TotalBalanceReverse));
                end;
                DocBalanceReverse := 0;
                DateBalanceReverse := 0;
                TotalBalanceReverse := 0;
                LastDate := 0D;
                LastDocType := LastDocType::" ";
                LastDocNo := '';
            end;
        end;
    end;

    local procedure CheckDimensions(GenJournalLine: Record "Gen. Journal Line")
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        SkipCheck: Boolean;
    begin
        with GenJournalLine do begin
            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                AddError(DimMgt.GetDimCombErr());

            TableID[1] := DimMgt.TypeToTableID1("Account Type".AsInteger());
            No[1] := "Account No.";
            TableID[2] := DimMgt.TypeToTableID1("Bal. Account Type".AsInteger());
            No[2] := "Bal. Account No.";
            TableID[3] := Database::Job;
            No[3] := "Job No.";
            TableID[4] := Database::"Salesperson/Purchaser";
            No[4] := "Salespers./Purch. Code";
            TableID[5] := Database::Campaign;
            No[5] := "Campaign No.";
            SkipCheck := false;
            OnAfterAssignDimTableID(GenJournalLine, TableID, No, SkipCheck);
            if not SkipCheck then
                if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                    AddError(DimMgt.GetDimValuePostingErr());
        end;
    end;

    local procedure CalculateDocBalance(GenJournalLine: Record "Gen. Journal Line"): Decimal
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.SetRange("Document Type", GenJournalLine."Document Type");
        GenJournalLine2.SetRange("Document No.", GenJournalLine."Document No.");
        GenJournalLine2.CalcSums("Balance (LCY)");
        exit(GenJournalLine2."Balance (LCY)");
    end;

    local procedure CalculateDateBalance(GenJournalLine: Record "Gen. Journal Line"): Decimal
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.SetRange("Posting Date", GenJournalLine."Posting Date");
        GenJournalLine2.CalcSums("Balance (LCY)");
        exit(GenJournalLine2."Balance (LCY)");
    end;

    local procedure CalculateTotalBalance(GenJournalLine: Record "Gen. Journal Line"): Decimal
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.CalcSums("Balance (LCY)");
        exit(GenJournalLine2."Balance (LCY)");
    end;

    procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure ReconcileGLAccNo(GLAccNo: Code[20]; ReconcileAmount: Decimal)
    begin
        if not GLAccNetChange.Get(GLAccNo) then begin
            GLAcc.Get(GLAccNo);
            GLAcc.CalcFields("Balance at Date");
            GLAccNetChange.Init();
            GLAccNetChange."No." := GLAcc."No.";
            GLAccNetChange.Name := GLAcc.Name;
            GLAccNetChange."Balance after Posting" := GLAcc."Balance at Date";
            OnReconcileGLAccNoOnBeforeGLAccNetChangeInsert(GLAccNo, ReconcileAmount, GLAccNetChange);
            GLAccNetChange.Insert();
        end;
        GLAccNetChange."Net Change in Jnl." := GLAccNetChange."Net Change in Jnl." + ReconcileAmount;
        GLAccNetChange."Balance after Posting" := GLAccNetChange."Balance after Posting" + ReconcileAmount;
        OnReconcileGLAccNoOnBeforeGLAccNetChangeModify(GLAccNo, ReconcileAmount, GLAccNetChange);
        GLAccNetChange.Modify();
    end;

    local procedure CheckGLAcc(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        with GenJnlLine do
            if not GLAcc.Get("Account No.") then
                AddError(
                  StrSubstNo(
                    Text031,
                    GLAcc.TableCaption(), "Account No."))
            else begin
                AccName := GLAcc.Name;

                if GLAcc.Blocked then
                    AddError(
                      StrSubstNo(
                        Text032,
                        GLAcc.FieldCaption(Blocked), false, GLAcc.TableCaption(), "Account No."));
                if GLAcc."Account Type" <> GLAcc."Account Type"::Posting then begin
                    GLAcc."Account Type" := GLAcc."Account Type"::Posting;
                    AddError(
                      StrSubstNo(
                        Text032,
                        GLAcc.FieldCaption("Account Type"), GLAcc."Account Type", GLAcc.TableCaption(), "Account No."));
                end;
                if not "System-Created Entry" then
                    if "Posting Date" = NormalDate("Posting Date") then
                        if not GLAcc."Direct Posting" then
                            AddError(
                              StrSubstNo(
                                Text032,
                                GLAcc.FieldCaption("Direct Posting"), true, GLAcc.TableCaption(), "Account No."));

                if "Gen. Posting Type" <> "Gen. Posting Type"::" " then begin
                    case "Gen. Posting Type" of
                        "Gen. Posting Type"::Sale:
                            SalesPostingType := true;
                        "Gen. Posting Type"::Purchase:
                            PurchPostingType := true;
                    end;
                    TestPostingType();

                    if not VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                        AddError(
                          StrSubstNo(
                            Text036,
                            VATPostingSetup.TableCaption(), "VAT Bus. Posting Group", "VAT Prod. Posting Group"))
                    else
                        if "VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type" then
                            AddError(
                              StrSubstNo(
                                Text037,
                                FieldCaption("VAT Calculation Type"), VATPostingSetup."VAT Calculation Type"))
                end;

                if GLAcc."Reconciliation Account" then
                    ReconcileGLAccNo("Account No.", Round("Amount (LCY)" / (1 + "VAT %" / 100)));

                OnAfterCheckGLAcc(GenJnlLine, GLAcc, ErrorCounter, ErrorText);
            end;
    end;

    local procedure CheckCust(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        with GenJnlLine do
            if not Cust.Get("Account No.") then
                AddError(
                  StrSubstNo(
                    Text031,
                    Cust.TableCaption(), "Account No."))
            else begin
                AccName := Cust.Name;
                if Cust."Privacy Blocked" then
                    AddError(Cust.GetPrivacyBlockedGenericErrorText(Cust));
                if ((Cust.Blocked = Cust.Blocked::All) or
                    ((Cust.Blocked = Cust.Blocked::Invoice) and
                     ("Document Type" in ["Document Type"::Invoice, "Document Type"::" "]))
                    )
                then
                    AddError(
                      StrSubstNo(
                        Text065,
                        "Account Type", Cust.Blocked, FieldCaption("Document Type"), "Document Type"));
                if "Currency Code" <> '' then
                    if not Currency.Get("Currency Code") then
                        AddError(
                          StrSubstNo(
                            Text038,
                            "Currency Code"));
                if (Cust."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) then
                    if ICPartner.Get(Cust."IC Partner Code") then begin
                        if ICPartner.Blocked then
                            AddError(
                              StrSubstNo(
                                '%1 %2',
                                StrSubstNo(
                                  Text067,
                                  Cust.TableCaption(), "Account No.", ICPartner.TableCaption(), "IC Partner Code"),
                                StrSubstNo(
                                  Text032,
                                  ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Cust."IC Partner Code")));
                    end else
                        AddError(
                          StrSubstNo(
                            '%1 %2',
                            StrSubstNo(
                              Text067,
                              Cust.TableCaption(), "Account No.", ICPartner.TableCaption(), Cust."IC Partner Code"),
                            StrSubstNo(
                              Text031,
                              ICPartner.TableCaption(), Cust."IC Partner Code")));
                CustPosting := true;
                TestPostingType();

                if "Recurring Method" = "Recurring Method"::" " then
                    if "Document Type" in
                       ["Document Type"::Invoice, "Document Type"::"Credit Memo",
                        "Document Type"::"Finance Charge Memo", "Document Type"::Reminder]
                    then begin
                        OldCustLedgEntry.Reset();
                        OldCustLedgEntry.SetCurrentKey("Document No.");
                        OldCustLedgEntry.SetRange("Document Type", "Document Type");
                        OldCustLedgEntry.SetRange("Document No.", "Document No.");
                        if OldCustLedgEntry.FindFirst() then
                            AddError(
                              StrSubstNo(
                                Text039, "Document Type", "Document No."));

                        if SalesSetup."Ext. Doc. No. Mandatory" or
                           ("External Document No." <> '')
                        then begin
                            if "External Document No." = '' then
                                AddError(
                                  StrSubstNo(
                                    Text041, FieldCaption("External Document No.")));

                            OldCustLedgEntry.Reset();
                            OldCustLedgEntry.SetCurrentKey("External Document No.");
                            OldCustLedgEntry.SetRange("Document Type", "Document Type");
                            OldCustLedgEntry.SetRange("Customer No.", "Account No.");
                            OldCustLedgEntry.SetRange("External Document No.", "External Document No.");
                            if OldCustLedgEntry.FindFirst() then
                                AddError(
                                  StrSubstNo(
                                    Text039,
                                    "Document Type", "External Document No."));
                            CheckAgainstPrevLines("Gen. Journal Line");
                        end;
                    end;
            end;
    end;

    local procedure CheckVend(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    var
        VendorMgt: Codeunit "Vendor Mgt.";
    begin
        with GenJnlLine do
            if not Vend.Get("Account No.") then
                AddError(
                  StrSubstNo(
                    Text031,
                    Vend.TableCaption(), "Account No."))
            else begin
                AccName := Vend.Name;
                if Vend."Privacy Blocked" then
                    AddError(Vend.GetPrivacyBlockedGenericErrorText(Vend));
                if ((Vend.Blocked = Vend.Blocked::All) or
                    ((Vend.Blocked = Vend.Blocked::Payment) and ("Document Type" = "Document Type"::Payment))
                    )
                then
                    AddError(
                      StrSubstNo(
                        Text065,
                        "Account Type", Vend.Blocked, FieldCaption("Document Type"), "Document Type"));
                if "Currency Code" <> '' then
                    if not Currency.Get("Currency Code") then
                        AddError(
                          StrSubstNo(
                            Text038,
                            "Currency Code"));

                if (Vend."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) then
                    if ICPartner.Get(Vend."IC Partner Code") then begin
                        if ICPartner.Blocked then
                            AddError(
                              StrSubstNo(
                                '%1 %2',
                                StrSubstNo(
                                  Text067,
                                  Vend.TableCaption(), "Account No.", ICPartner.TableCaption(), Vend."IC Partner Code"),
                                StrSubstNo(
                                  Text032,
                                  ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Vend."IC Partner Code")));
                    end else
                        AddError(
                          StrSubstNo(
                            '%1 %2',
                            StrSubstNo(
                              Text067,
                              Vend.TableCaption(), "Account No.", ICPartner.TableCaption(), "IC Partner Code"),
                            StrSubstNo(
                              Text031,
                              ICPartner.TableCaption(), Vend."IC Partner Code")));
                VendPosting := true;
                TestPostingType();

                if "Recurring Method" = "Recurring Method"::" " then
                    if "Document Type" in
                       ["Document Type"::Invoice, "Document Type"::"Credit Memo",
                        "Document Type"::"Finance Charge Memo", "Document Type"::Reminder]
                    then begin
                        OldVendLedgEntry.Reset();
                        OldVendLedgEntry.SetCurrentKey("Document No.");
                        OldVendLedgEntry.SetRange("Document Type", "Document Type");
                        OldVendLedgEntry.SetRange("Document No.", "Document No.");
                        if OldVendLedgEntry.FindFirst() then
                            AddError(
                              StrSubstNo(
                                Text040,
                                "Document Type", "Document No."));

                        if PurchSetup."Ext. Doc. No. Mandatory" or
                           ("External Document No." <> '')
                        then begin
                            if "External Document No." = '' then
                                AddError(
                                  StrSubstNo(
                                    Text041, FieldCaption("External Document No.")));

                            OldVendLedgEntry.Reset();
                            OldVendLedgEntry.SetCurrentKey("External Document No.");
                            VendorMgt.SetFilterForExternalDocNo(
                              OldVendLedgEntry, "Document Type", "External Document No.", "Account No.", "Document Date");
                            if OldVendLedgEntry.FindFirst() then
                                AddError(
                                  StrSubstNo(
                                    Text040,
                                    "Document Type", "External Document No."));
                            CheckAgainstPrevLines("Gen. Journal Line");
                        end;
                    end;
            end;
    end;

    local procedure CheckEmployee(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        with GenJnlLine do
            if not Employee.Get("Account No.") then
                AddError(StrSubstNo(Text031, Employee.TableCaption(), "Account No."))
            else begin
                AccName := Employee."No.";
                if Employee."Privacy Blocked" then
                    AddError(StrSubstNo(Text032, Employee.FieldCaption("Privacy Blocked"), false, Employee.TableCaption(), AccName))
            end;
    end;

    local procedure CheckBankAcc(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        with GenJnlLine do
            if not BankAcc.Get("Account No.") then
                AddError(
                  StrSubstNo(
                    Text031,
                    BankAcc.TableCaption(), "Account No."))
            else begin
                AccName := BankAcc.Name;

                if BankAcc.Blocked then
                    AddError(
                      StrSubstNo(
                        Text032,
                        BankAcc.FieldCaption(Blocked), false, BankAcc.TableCaption(), "Account No."));
                if ("Currency Code" <> BankAcc."Currency Code") and (BankAcc."Currency Code" <> '') then
                    AddError(
                      StrSubstNo(
                        Text037,
                        FieldCaption("Currency Code"), BankAcc."Currency Code"));

                if "Currency Code" <> '' then
                    if not Currency.Get("Currency Code") then
                        AddError(
                          StrSubstNo(
                            Text038,
                            "Currency Code"));

                if "Bank Payment Type" <> "Bank Payment Type"::" " then
                    if ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") and (Amount < 0) then
                        if BankAcc."Currency Code" <> "Currency Code" then
                            AddError(
                              StrSubstNo(
                                Text042,
                                FieldCaption("Bank Payment Type"), FieldCaption("Currency Code"),
                                TableCaption, BankAcc.TableCaption()));

                if BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group") then
                    if BankAccPostingGr."G/L Account No." <> '' then
                        ReconcileGLAccNo(
                          BankAccPostingGr."G/L Account No.",
                          Round("Amount (LCY)" / (1 + "VAT %" / 100)));
            end;
    end;

    local procedure CheckFixedAsset(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        with GenJnlLine do
            if not FA.Get("Account No.") then
                AddError(
                  StrSubstNo(
                    Text031,
                    FA.TableCaption(), "Account No."))
            else begin
                AccName := FA.Description;
                if FA.Blocked then
                    AddError(
                      StrSubstNo(
                        Text032,
                        FA.FieldCaption(Blocked), false, FA.TableCaption(), "Account No."));
                if FA.Inactive then
                    AddError(
                      StrSubstNo(
                        Text032,
                        FA.FieldCaption(Inactive), false, FA.TableCaption(), "Account No."));
                if FA."Budgeted Asset" then
                    AddError(
                      StrSubstNo(
                        Text043,
                        FA.TableCaption(), "Account No.", FA.FieldCaption("Budgeted Asset"), true));
                if DeprBook.Get("Depreciation Book Code") then
                    CheckFAIntegration(GenJnlLine)
                else
                    AddError(
                      StrSubstNo(
                        Text031,
                        DeprBook.TableCaption(), "Depreciation Book Code"));
                if not FADeprBook.Get(FA."No.", "Depreciation Book Code") then
                    AddError(
                      StrSubstNo(
                        Text036,
                        FADeprBook.TableCaption(), FA."No.", "Depreciation Book Code"));
            end;
    end;

    local procedure CheckICPartner(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        with GenJnlLine do
            if not ICPartner.Get("Account No.") then
                AddError(
                  StrSubstNo(
                    Text031,
                    ICPartner.TableCaption(), "Account No."))
            else begin
                AccName := ICPartner.Name;
                if ICPartner.Blocked then
                    AddError(
                      StrSubstNo(
                        Text032,
                        ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), "Account No."));
            end;
    end;

    local procedure TestFixedAsset(var GenJnlLine: Record "Gen. Journal Line")
    var
        ShouldCheckFAPostingDate: Boolean;
    begin
        with GenJnlLine do begin
            if "Job No." <> '' then
                AddError(
                  StrSubstNo(
                    Text044, FieldCaption("Job No.")));
            if "FA Posting Type" = "FA Posting Type"::" " then
                AddError(
                  StrSubstNo(
                    Text045, FieldCaption("FA Posting Type")));
            if "Depreciation Book Code" = '' then
                AddError(
                  StrSubstNo(
                    Text045, FieldCaption("Depreciation Book Code")));
            if "Depreciation Book Code" = "Duplicate in Depreciation Book" then
                AddError(
                  StrSubstNo(
                    Text046,
                    FieldCaption("Depreciation Book Code"), FieldCaption("Duplicate in Depreciation Book")));
            CheckFADocNo(GenJnlLine);
            if "Account Type" = "Bal. Account Type" then
                AddError(
                  StrSubstNo(
                    Text047,
                    FieldCaption("Account Type"), FieldCaption("Bal. Account Type"), "Account Type"));
            if "Account Type" = "Account Type"::"Fixed Asset" then
                if IsAcquisitionCost() or ("FA Posting Type" in ["FA Posting Type"::Disposal, "FA Posting Type"::Maintenance]) then begin
                    if ("Gen. Bus. Posting Group" <> '') or ("Gen. Prod. Posting Group" <> '') then
                        if "Gen. Posting Type" = "Gen. Posting Type"::" " then
                            AddError(StrSubstNo(Text002, FieldCaption("Gen. Posting Type")));
                end else begin
                    if "Gen. Posting Type" <> "Gen. Posting Type"::" " then
                        AddError(
                          StrSubstNo(
                            Text049,
                            FieldCaption("Gen. Posting Type"), FieldCaption("FA Posting Type"), "FA Posting Type"));
                    if "Gen. Bus. Posting Group" <> '' then
                        AddError(
                          StrSubstNo(
                            Text049,
                            FieldCaption("Gen. Bus. Posting Group"), FieldCaption("FA Posting Type"), "FA Posting Type"));
                    if "Gen. Prod. Posting Group" <> '' then
                        AddError(
                          StrSubstNo(
                            Text049,
                            FieldCaption("Gen. Prod. Posting Group"), FieldCaption("FA Posting Type"), "FA Posting Type"));
                end;
            if "Bal. Account Type" = "Bal. Account Type"::"Fixed Asset" then
                if IsAcquisitionCost() or ("FA Posting Type" in ["FA Posting Type"::Disposal, "FA Posting Type"::Maintenance]) then begin
                    if ("Bal. Gen. Bus. Posting Group" <> '') or ("Bal. Gen. Prod. Posting Group" <> '') then
                        if "Bal. Gen. Posting Type" = "Bal. Gen. Posting Type"::" " then
                            AddError(StrSubstNo(Text002, FieldCaption("Bal. Gen. Posting Type")));
                end else begin
                    if "Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" " then
                        AddError(
                          StrSubstNo(
                            Text049,
                            FieldCaption("Bal. Gen. Posting Type"), FieldCaption("FA Posting Type"), "FA Posting Type"));
                    if "Bal. Gen. Bus. Posting Group" <> '' then
                        AddError(
                          StrSubstNo(
                            Text049,
                            FieldCaption("Bal. Gen. Bus. Posting Group"), FieldCaption("FA Posting Type"), "FA Posting Type"));
                    if "Bal. Gen. Prod. Posting Group" <> '' then
                        AddError(
                          StrSubstNo(
                            Text049,
                            FieldCaption("Bal. Gen. Prod. Posting Group"), FieldCaption("FA Posting Type"), "FA Posting Type"));
                end;
            TempErrorText :=
              '%1 ' +
              StrSubstNo(
                Text050,
                FieldCaption("FA Posting Type"), "FA Posting Type");
            if "FA Posting Type" <> "FA Posting Type"::"Acquisition Cost" then begin
                if "Depr. Acquisition Cost" then
                    AddError(StrSubstNo(TempErrorText, FieldCaption("Depr. Acquisition Cost")));
                if "Salvage Value" <> 0 then
                    AddError(StrSubstNo(TempErrorText, FieldCaption("Salvage Value")));
                if "FA Posting Type" <> "FA Posting Type"::Maintenance then
                    if Quantity <> 0 then
                        AddError(StrSubstNo(TempErrorText, FieldCaption(Quantity)));
                if "Insurance No." <> '' then
                    AddError(StrSubstNo(TempErrorText, FieldCaption("Insurance No.")));
            end;
            if ("FA Posting Type" = "FA Posting Type"::Maintenance) and "Depr. until FA Posting Date" then
                AddError(StrSubstNo(TempErrorText, FieldCaption("Depr. until FA Posting Date")));
            if ("FA Posting Type" <> "FA Posting Type"::Maintenance) and ("Maintenance Code" <> '') then
                AddError(StrSubstNo(TempErrorText, FieldCaption("Maintenance Code")));

            if ("FA Posting Type" <> "FA Posting Type"::Depreciation) and
               ("FA Posting Type" <> "FA Posting Type"::"Custom 1") and
               ("No. of Depreciation Days" <> 0)
            then
                AddError(StrSubstNo(TempErrorText, FieldCaption("No. of Depreciation Days")));

            if ("FA Posting Type" = "FA Posting Type"::Disposal) and "FA Reclassification Entry" then
                AddError(StrSubstNo(TempErrorText, FieldCaption("FA Reclassification Entry")));

            if ("FA Posting Type" = "FA Posting Type"::Disposal) and ("Budgeted FA No." <> '') then
                AddError(StrSubstNo(TempErrorText, FieldCaption("Budgeted FA No.")));

            if "FA Posting Date" = 0D then
                "FA Posting Date" := "Posting Date";
            if DeprBook.Get("Depreciation Book Code") then
                if DeprBook."Use Same FA+G/L Posting Dates" and ("Posting Date" <> "FA Posting Date") then
                    AddError(
                      StrSubstNo(
                        Text051,
                        FieldCaption("Posting Date"), FieldCaption("FA Posting Date")));
            ShouldCheckFAPostingDate := "FA Posting Date" <> 0D;
            OnTestFixedAssetOnAfterCalcShouldCheckFAPostingDate(GenJnlLine, ShouldCheckFAPostingDate);
            if ShouldCheckFAPostingDate then begin
                if "FA Posting Date" <> NormalDate("FA Posting Date") then
                    AddError(
                      StrSubstNo(
                        Text052,
                        FieldCaption("FA Posting Date")));
                if not ("FA Posting Date" in [DMY2Date(1, 1, 2) .. DMY2Date(31, 12, 9998)]) then
                    AddError(
                      StrSubstNo(
                        Text053,
                        FieldCaption("FA Posting Date")));
                if (AllowFAPostingFrom = 0D) and (AllowFAPostingTo = 0D) then begin
                    if UserId <> '' then
                        if UserSetup.Get(UserId) then begin
                            AllowFAPostingFrom := UserSetup."Allow FA Posting From";
                            AllowFAPostingTo := UserSetup."Allow FA Posting To";
                        end;
                    if (AllowFAPostingFrom = 0D) and (AllowFAPostingTo = 0D) then begin
                        FASetup.Get();
                        AllowFAPostingFrom := FASetup."Allow FA Posting From";
                        AllowFAPostingTo := FASetup."Allow FA Posting To";
                    end;
                    if AllowFAPostingTo = 0D then
                        AllowFAPostingTo := DMY2Date(31, 12, 9998);
                end;
                if ("FA Posting Date" < AllowFAPostingFrom) or
                   ("FA Posting Date" > AllowFAPostingTo)
                then
                    AddError(
                      StrSubstNo(
                        Text053,
                        FieldCaption("FA Posting Date")));
            end;
            FASetup.Get();
            if ("FA Posting Type" = "FA Posting Type"::"Acquisition Cost") and
               ("Insurance No." <> '') and ("Depreciation Book Code" <> FASetup."Insurance Depr. Book")
            then
                AddError(
                  StrSubstNo(
                    Text054,
                    FieldCaption("Depreciation Book Code"), "Depreciation Book Code"));

            if "FA Error Entry No." > 0 then begin
                TempErrorText :=
                  '%1 ' +
                  StrSubstNo(
                    Text055,
                    FieldCaption("FA Error Entry No."));
                if "Depr. until FA Posting Date" then
                    AddError(StrSubstNo(TempErrorText, FieldCaption("Depr. until FA Posting Date")));
                if "Depr. Acquisition Cost" then
                    AddError(StrSubstNo(TempErrorText, FieldCaption("Depr. Acquisition Cost")));
                if "Duplicate in Depreciation Book" <> '' then
                    AddError(StrSubstNo(TempErrorText, FieldCaption("Duplicate in Depreciation Book")));
                if "Use Duplication List" then
                    AddError(StrSubstNo(TempErrorText, FieldCaption("Use Duplication List")));
                if "Salvage Value" <> 0 then
                    AddError(StrSubstNo(TempErrorText, FieldCaption("Salvage Value")));
                if "Insurance No." <> '' then
                    AddError(StrSubstNo(TempErrorText, FieldCaption("Insurance No.")));
                if "Budgeted FA No." <> '' then
                    AddError(StrSubstNo(TempErrorText, FieldCaption("Budgeted FA No.")));
                if "Recurring Method" <> "Recurring Method"::" " then
                    AddError(StrSubstNo(TempErrorText, FieldCaption("Recurring Method")));
                if "FA Posting Type" = "FA Posting Type"::Maintenance then
                    AddError(StrSubstNo(TempErrorText, "FA Posting Type"));
            end;
        end;
    end;

    local procedure CheckFAIntegration(var GenJnlLine: Record "Gen. Journal Line")
    var
        GLIntegration: Boolean;
    begin
        with GenJnlLine do begin
            if "FA Posting Type" = "FA Posting Type"::" " then
                exit;
            case "FA Posting Type" of
                "FA Posting Type"::"Acquisition Cost":
                    GLIntegration := DeprBook."G/L Integration - Acq. Cost";
                "FA Posting Type"::Depreciation:
                    GLIntegration := DeprBook."G/L Integration - Depreciation";
                "FA Posting Type"::"Write-Down":
                    GLIntegration := DeprBook."G/L Integration - Write-Down";
                "FA Posting Type"::Appreciation:
                    GLIntegration := DeprBook."G/L Integration - Appreciation";
                "FA Posting Type"::"Custom 1":
                    GLIntegration := DeprBook."G/L Integration - Custom 1";
                "FA Posting Type"::"Custom 2":
                    GLIntegration := DeprBook."G/L Integration - Custom 2";
                "FA Posting Type"::Disposal:
                    GLIntegration := DeprBook."G/L Integration - Disposal";
                "FA Posting Type"::Maintenance:
                    GLIntegration := DeprBook."G/L Integration - Maintenance";
            end;
            if not GLIntegration then
                AddError(
                  StrSubstNo(
                    Text056,
                    "FA Posting Type"));

            if not DeprBook."G/L Integration - Depreciation" then begin
                if "Depr. until FA Posting Date" then
                    AddError(
                      StrSubstNo(
                        Text057,
                        FieldCaption("Depr. until FA Posting Date")));
                if "Depr. Acquisition Cost" then
                    AddError(
                      StrSubstNo(
                        Text057,
                        FieldCaption("Depr. Acquisition Cost")));
            end;
        end;
    end;

    local procedure TestFixedAssetFields(var GenJnlLine: Record "Gen. Journal Line")
    begin
        with GenJnlLine do begin
            if "FA Posting Type" <> "FA Posting Type"::" " then
                AddError(StrSubstNo(Text058, FieldCaption("FA Posting Type")));
            if "Depreciation Book Code" <> '' then
                AddError(StrSubstNo(Text058, FieldCaption("Depreciation Book Code")));
        end;
    end;

    procedure TestPostingType()
    begin
        case true of
            CustPosting and PurchPostingType:
                AddError(Text059);
            VendPosting and SalesPostingType:
                AddError(Text060);
        end;
    end;

    local procedure WarningIfNegativeAmt(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWarningIfNegativeAmt(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if (GenJnlLine.Amount < 0) and not AmountError then begin
            AmountError := true;
            AddError(StrSubstNo(Text007, GenJnlLine.FieldCaption(Amount)));
        end;
    end;

    local procedure WarningIfPositiveAmt(GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWarningIfPositiveAmt(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if (GenJnlLine.Amount > 0) and not AmountError then begin
            AmountError := true;
            AddError(StrSubstNo(Text006, GenJnlLine.FieldCaption(Amount)));
        end;
    end;

    local procedure WarningIfZeroAmt(GenJnlLine: Record "Gen. Journal Line")
    begin
        if (GenJnlLine.Amount = 0) and not AmountError then begin
            AmountError := true;
            AddError(StrSubstNo(Text002, GenJnlLine.FieldCaption(Amount)));
        end;
    end;

    local procedure WarningIfNonZeroAmt(GenJnlLine: Record "Gen. Journal Line")
    begin
        if (GenJnlLine.Amount <> 0) and not AmountError then begin
            AmountError := true;
            AddError(StrSubstNo(Text062, GenJnlLine.FieldCaption(Amount)));
        end;
    end;

    local procedure CheckAgainstPrevLines(GenJnlLine: Record "Gen. Journal Line")
    var
        i: Integer;
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
        ErrorFound: Boolean;
    begin
        if (GenJnlLine."External Document No." = '') or
           not (GenJnlLine."Account Type" in
                [GenJnlLine."Account Type"::Customer, GenJnlLine."Account Type"::Vendor]) and
           not (GenJnlLine."Bal. Account Type" in
                [GenJnlLine."Bal. Account Type"::Customer, GenJnlLine."Bal. Account Type"::Vendor])
        then
            exit;

        if GenJnlLine."Account Type" in [GenJnlLine."Account Type"::Customer, GenJnlLine."Account Type"::Vendor] then begin
            AccType := GenJnlLine."Account Type";
            AccNo := GenJnlLine."Account No.";
        end else begin
            AccType := GenJnlLine."Bal. Account Type";
            AccNo := GenJnlLine."Bal. Account No.";
        end;

        TempGenJnlLine.Reset();
        TempGenJnlLine.SetRange("External Document No.", GenJnlLine."External Document No.");

        while (i < 2) and not ErrorFound do begin
            i := i + 1;
            if i = 1 then begin
                TempGenJnlLine.SetRange("Account Type", AccType);
                TempGenJnlLine.SetRange("Account No.", AccNo);
                TempGenJnlLine.SetRange("Bal. Account Type");
                TempGenJnlLine.SetRange("Bal. Account No.");
            end else begin
                TempGenJnlLine.SetRange("Account Type");
                TempGenJnlLine.SetRange("Account No.");
                TempGenJnlLine.SetRange("Bal. Account Type", AccType);
                TempGenJnlLine.SetRange("Bal. Account No.", AccNo);
            end;
            if TempGenJnlLine.FindFirst() then begin
                ErrorFound := true;
                AddError(
                  StrSubstNo(
                    Text064, GenJnlLine.FieldCaption("External Document No."), GenJnlLine."External Document No.",
                    TempGenJnlLine."Line No.", GenJnlLine.FieldCaption("Document No."), TempGenJnlLine."Document No."));
            end;
        end;

        TempGenJnlLine.Reset();
        TempGenJnlLine := GenJnlLine;
        TempGenJnlLine.Insert();
    end;

    local procedure CheckICDocument()
    var
        GenJnlLine4: Record "Gen. Journal Line";
    begin
        with "Gen. Journal Line" do
            if GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany then begin
                if ("Posting Date" <> LastDate) or ("Document Type" <> LastDocType) or ("Document No." <> LastDocNo) then begin
                    GenJnlLine4.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
                    GenJnlLine4.SetRange("Journal Template Name", "Journal Template Name");
                    GenJnlLine4.SetRange("Journal Batch Name", "Journal Batch Name");
                    GenJnlLine4.SetRange("Posting Date", "Posting Date");
                    GenJnlLine4.SetRange("Document No.", "Document No.");
                    GenJnlLine4.SetFilter("IC Partner Code", '<>%1', '');
                    if GenJnlLine4.FindFirst() then
                        CurrentICPartner := GenJnlLine4."IC Partner Code"
                    else
                        CurrentICPartner := '';
                end;
                CheckICAccountNo();
            end;
    end;

    local procedure TestJobFields(var GenJnlLine: Record "Gen. Journal Line")
    var
        Job: Record Job;
        JT: Record "Job Task";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestJobFields(GenJnlLine, ErrorCounter, ErrorText, IsHandled);
        if IsHandled then
            exit;

        with GenJnlLine do begin
            if ("Job No." = '') or ("Account Type" <> "Account Type"::"G/L Account") then
                exit;
            if not Job.Get("Job No.") then
                AddError(StrSubstNo(Text071, Job.TableCaption(), "Job No."))
            else
                if Job.Blocked <> Job.Blocked::" " then
                    AddError(
                      StrSubstNo(
                        Text072, Job.FieldCaption(Blocked), Job.Blocked, Job.TableCaption(), "Job No."));

            if "Job Task No." = '' then
                AddError(StrSubstNo(Text002, FieldCaption("Job Task No.")))
            else
                if not JT.Get("Job No.", "Job Task No.") then
                    AddError(StrSubstNo(Text071, JT.TableCaption(), "Job Task No."))
        end;

        OnAfterTestJobFields(GenJnlLine, ErrorCounter, ErrorText);
    end;

    local procedure CheckFADocNo(GenJnlLine: Record "Gen. Journal Line")
    var
        DeprBook: Record "Depreciation Book";
        FAJnlLine: Record "FA Journal Line";
        OldFALedgEntry: Record "FA Ledger Entry";
        OldMaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
    begin
        with GenJnlLine do begin
            if "Account Type" = "Account Type"::"Fixed Asset" then
                FANo := "Account No.";
            if "Bal. Account Type" = "Bal. Account Type"::"Fixed Asset" then
                FANo := "Bal. Account No.";
            if (FANo = '') or
               ("FA Posting Type" = "FA Posting Type"::" ") or
               ("Depreciation Book Code" = '') or
               ("Document No." = '')
            then
                exit;
            if not DeprBook.Get("Depreciation Book Code") then
                exit;
            if DeprBook."Allow Identical Document No." then
                exit;

            FAJnlLine."FA Posting Type" := Enum::"FA Journal Line FA Posting Type".FromInteger("FA Posting Type".AsInteger() - 1);
            if "FA Posting Type" <> "FA Posting Type"::Maintenance then begin
                OldFALedgEntry.SetCurrentKey(
                  "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Document No.");
                OldFALedgEntry.SetRange("FA No.", FANo);
                OldFALedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                OldFALedgEntry.SetRange("FA Posting Category", OldFALedgEntry."FA Posting Category"::" ");
                OldFALedgEntry.SetRange("FA Posting Type", FAJnlLine.ConvertToLedgEntry(FAJnlLine));
                OldFALedgEntry.SetRange("Document No.", "Document No.");
                if OldFALedgEntry.FindFirst() then
                    AddError(
                      StrSubstNo(
                        Text073,
                        FieldCaption("Document No."), "Document No."));
            end else begin
                OldMaintenanceLedgEntry.SetCurrentKey(
                  "FA No.", "Depreciation Book Code", "Document No.");
                OldMaintenanceLedgEntry.SetRange("FA No.", FANo);
                OldMaintenanceLedgEntry.SetRange("Depreciation Book Code", "Depreciation Book Code");
                OldMaintenanceLedgEntry.SetRange("Document No.", "Document No.");
                if OldMaintenanceLedgEntry.FindFirst() then
                    AddError(
                      StrSubstNo(
                        Text073,
                        FieldCaption("Document No."), "Document No."));
            end;
        end;
    end;

    procedure InitializeRequest(NewShowDim: Boolean)
    begin
        ShowDim := NewShowDim;
    end;

    local procedure GetDimensionText(var DimensionSetEntry: Record "Dimension Set Entry"): Text[75]
    var
        DimensionText: Text[75];
        Separator: Code[10];
        DimValue: Text[45];
    begin
        Separator := '';
        DimValue := '';
        Continue := false;

        repeat
            DimValue := StrSubstNo('%1 - %2', DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code");
            if MaxStrLen(DimensionText) < StrLen(DimensionText + Separator + DimValue) then begin
                Continue := true;
                exit(DimensionText);
            end;
            DimensionText := DimensionText + Separator + DimValue;
            Separator := '; ';
        until DimSetEntry.Next() = 0;
        exit(DimensionText);
    end;

    local procedure CheckAccountTypes(AccountType: Enum "Gen. Journal Account Type"; var Name: Text[100])
    begin
        case AccountType of
            AccountType::"G/L Account":
                CheckGLAcc("Gen. Journal Line", Name);
            AccountType::Customer:
                CheckCust("Gen. Journal Line", Name);
            AccountType::Vendor:
                CheckVend("Gen. Journal Line", Name);
            AccountType::"Bank Account":
                CheckBankAcc("Gen. Journal Line", Name);
            AccountType::"Fixed Asset":
                CheckFixedAsset("Gen. Journal Line", Name);
            AccountType::"IC Partner":
                CheckICPartner("Gen. Journal Line", Name);
            AccountType::Employee:
                CheckEmployee("Gen. Journal Line", Name);
        end;
    end;

    local procedure GetLastEnteredDocumentNo(var FromGenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.CopyFilters(FromGenJournalLine);
        GenJournalLine.SetCurrentKey("Document No.");
        if GenJournalLine.FindLast() then;
        exit(GenJournalLine."Document No.");
    end;

    local procedure IsGapInNosForDocNo(var FromGenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if LastEnteredDocNo = '' then
            exit(false);
        if FromGenJournalLine."Document No." = LastEnteredDocNo then
            exit(false);

        GenJournalLine.CopyFilters(FromGenJournalLine);
        GenJournalLine.SetRange("Document No.", IncStr(FromGenJournalLine."Document No."));
        exit(GenJournalLine.IsEmpty);
    end;

    local procedure CheckICAccountNo()
    var
        ICGLAccount: Record "IC G/L Account";
        ICBankAccount: Record "IC Bank Account";
    begin
#if not CLEAN22
        with "Gen. Journal Line" do
            if (CurrentICPartner <> '') and ("IC Direction" = "IC Direction"::Outgoing) then begin
                if ("Account Type" in ["Account Type"::"G/L Account", "Account Type"::"Bank Account"]) and
                   ("Bal. Account Type" in ["Bal. Account Type"::"G/L Account", "Account Type"::"Bank Account"]) and
                   ("Account No." <> '') and
                   ("Bal. Account No." <> '')
                then
                    AddError(StrSubstNo(Text066, FieldCaption("Account No."), FieldCaption("Bal. Account No.")))
                else
                    if (("Account Type" in ["Account Type"::"G/L Account", "Account Type"::"Bank Account"]) and ("Account No." <> '')) xor
                       (("Bal. Account Type" in ["Bal. Account Type"::"G/L Account", "Account Type"::"Bank Account"]) and
                        ("Bal. Account No." <> ''))
                    then
                        if "IC Partner G/L Acc. No." = '' then
                            AddError(StrSubstNo(Text002, FieldCaption("IC Partner G/L Acc. No.")))
                        else begin
                            if ICGLAccount.Get("IC Partner G/L Acc. No.") then
                                if ICGLAccount.Blocked then
                                    AddError(StrSubstNo(Text032, ICGLAccount.FieldCaption(Blocked), false,
                                        FieldCaption("IC Partner G/L Acc. No."), "IC Partner G/L Acc. No."));

                            if "IC Account Type" = "IC Account Type"::"Bank Account" then
                                if ICBankAccount.Get("IC Account No.", CurrentICPartner) then
                                    if ICBankAccount.Blocked then
                                        AddError(StrSubstNo(Text032, ICGLAccount.FieldCaption(Blocked), false,
                                            FieldCaption("IC Account No."), "IC Account No."));
                        end
                    else
                        if "IC Partner G/L Acc. No." <> '' then
                            AddError(StrSubstNo(Text009, FieldCaption("IC Partner G/L Acc. No.")));
            end else
                if "IC Partner G/L Acc. No." <> '' then begin
                    if "IC Direction" = "IC Direction"::Incoming then
                        AddError(StrSubstNo(Text069, FieldCaption("IC Partner G/L Acc. No."), FieldCaption("IC Direction"), Format("IC Direction")));
                    if CurrentICPartner = '' then
                        AddError(StrSubstNo(Text070, FieldCaption("IC Partner G/L Acc. No.")));
                end;
#else
        with "Gen. Journal Line" do
            if (CurrentICPartner <> '') and ("IC Direction" = "IC Direction"::Outgoing) then begin
                if ("Account Type" in ["Account Type"::"G/L Account", "Account Type"::"Bank Account"]) and
                   ("Bal. Account Type" in ["Bal. Account Type"::"G/L Account", "Account Type"::"Bank Account"]) and
                   ("Account No." <> '') and
                   ("Bal. Account No." <> '')
                then
                    AddError(StrSubstNo(Text066, FieldCaption("Account No."), FieldCaption("Bal. Account No.")))
                else
                    if (("Account Type" in ["Account Type"::"G/L Account", "Account Type"::"Bank Account"]) and ("Account No." <> '')) xor
                       (("Bal. Account Type" in ["Bal. Account Type"::"G/L Account", "Account Type"::"Bank Account"]) and
                        ("Bal. Account No." <> ''))
                    then
                        if "IC Account No." = '' then
                            AddError(StrSubstNo(Text002, FieldCaption("IC Account No.")))
                        else begin
                            if "IC Account Type" = "IC Account Type"::"G/L Account" then
                                if ICGLAccount.Get("IC Account No.") then
                                    if ICGLAccount.Blocked then
                                        AddError(StrSubstNo(Text032, ICGLAccount.FieldCaption(Blocked), false,
                                            FieldCaption("IC Account No."), "IC Account No."));

                            if "IC Account Type" = "IC Account Type"::"Bank Account" then
                                if ICBankAccount.Get("IC Account No.", CurrentICPartner) then
                                    if ICBankAccount.Blocked then
                                        AddError(StrSubstNo(Text032, ICGLAccount.FieldCaption(Blocked), false,
                                            FieldCaption("IC Account No."), "IC Account No."));
                        end
                    else
                        if "IC Account No." <> '' then
                            AddError(StrSubstNo(Text009, FieldCaption("IC Account No.")));
            end else
                if "IC Account No." <> '' then begin
                    if "IC Direction" = "IC Direction"::Incoming then
                        AddError(StrSubstNo(Text069, FieldCaption("IC Account No."), FieldCaption("IC Direction"), Format("IC Direction")));
                    if CurrentICPartner = '' then
                        AddError(StrSubstNo(Text070, FieldCaption("IC Account No.")));
                end;
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignDimTableID(GenJournalLine: Record "Gen. Journal Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20]; var SkipCheck: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterCheckGLAcc(GenJournalLine: Record "Gen. Journal Line"; GLAccount: Record "G/L Account"; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterCheckGenJnlLine(GenJournalLine: Record "Gen. Journal Line"; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestJobFields(GenJournalLine: Record "Gen. Journal Line"; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestJobFields(var GenJournalLine: Record "Gen. Journal Line"; var ErrorCounter: Integer; var ErrorText: Array[50] of Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWarningIfNegativeAmt(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWarningIfPositiveAmt(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalLineOnAfterGetRecord(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalTemplate: Record "Gen. Journal Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordGenJournalLineOnAfterCheckBalAccTypeGLAccBalAccNo(GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordGenJournalLineOnAfterCheckAccTypeGLAccAccNo(GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestFixedAssetOnAfterCalcShouldCheckFAPostingDate(var GenJournalLine: Record "Gen. Journal Line"; var ShouldCheckFAPostingDate: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnReconcileGLAccNoOnBeforeGLAccNetChangeInsert(GLAccNo: Code[20]; ReconcileAmount: Decimal; var GLAccNetChange: Record "G/L Account Net Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReconcileGLAccNoOnBeforeGLAccNetChangeModify(GLAccNo: Code[20]; ReconcileAmount: Decimal; var GLAccNetChange: Record "G/L Account Net Change")
    begin
    end;
}

