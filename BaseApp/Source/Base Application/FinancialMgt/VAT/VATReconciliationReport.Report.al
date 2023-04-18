report 743 "VAT Reconciliation Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FinancialMgt/VAT/VATReconciliationReport.rdlc';
    ApplicationArea = VAT;
    Caption = 'VAT Reconciliation Report';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(GLEntry; "G/L Entry")
        {
            DataItemTableView = SORTING("G/L Account No.", "Posting Date");
            RequestFilterFields = "G/L Account No.", "Posting Date";

            column(CompanyName; CompanyProperty.DisplayName())
            {
            }
            column(GLEntryFilters; TableCaption() + ': ' + GetFilters())
            {
            }
            column(ShowDetails; ShowIndividualTransaction)
            {
            }
            column(VATAmount_GLEntry; "VAT Amount")
            {
            }
            column(GLAccountNo_GLEntry; "G/L Account No.")
            {
            }
            column(GLAccountNoCaption_GLEntry; FieldCaption("G/L Account No."))
            {
            }
            column(PostingDate_GLEntry; Format("Posting Date"))
            {
            }
            column(DocumentNo_GLEntry; "Document No.")
            {
            }
            column(DocumentNoCaption_GLEntry; FieldCaption("Document No."))
            {
            }
            column(BaseAmountSalesVAT; BaseAmountSalesVAT)
            {
            }
            column(SalesVAT; SalesVAT)
            {
            }
            column(BaseAmountRevCharges; BaseAmountRevCharges)
            {
            }
            column(SalesVATRevCharges; SalesVATRevCharges)
            {
            }
            column(BaseAmountPurchVAT; BaseAmountPurchVAT)
            {
            }
            column(PurchVAT; PurchVAT)
            {
            }
            column(GLAccountName; GLAccount.Name)
            {
            }
            column(ShowTransWithoutVAT; ShowTransactionWithoutVAT)
            {
            }

            trigger OnAfterGetRecord()
            var
                VATEntry: Record "VAT Entry";
            begin
                VATEntry.SetCurrentKey("Transaction No.");
                VATEntry.SetLoadFields(Amount, "VAT Calculation Type", Base, "Transaction No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group");

                VATEntry.SetRange("Transaction No.", "Transaction No.");
                VATEntry.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                VATEntry.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");

                ResetGlobalVariables();

                if VATEntry.FindSet() then
                    repeat
                        if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Reverse Charge VAT" then begin
                            BaseAmountRevCharges += VATEntry.Base;
                            SalesVATRevCharges += VATEntry.Amount;
                        end else
                            if "Gen. Posting Type" = "Gen. Posting Type"::Sale then begin
                                BaseAmountSalesVAT -= VATEntry.Base;
                                SalesVAT -= VATEntry.Amount;
                            end else begin
                                BaseAmountPurchVAT += VATEntry.Base;
                                PurchVAT += VATEntry.Amount;
                            end;
                    until VATEntry.Next() = 0;

                GLAccount.Get("G/L Account No.");
            end;

            trigger OnPreDataItem()
            begin
                GLEntry.SetLoadFields("VAT Amount", "G/L Account No.", "Posting Date", "Document No.", "Transaction No.",
                    "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Gen. Posting Type");

                GLAccount.SetLoadFields("No.", Name);

                if not ShowTransactionWithoutVAT then
                    GLEntry.SetFilter("VAT Amount", '<>0');
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(ShowDetails; ShowIndividualTransaction)
                    {
                        ApplicationArea = VAT;
                        Caption = 'Show Details';
                        ToolTip = 'Specifies if you want to include individual transactions. If the check box is not selected, then only one accumulated total will be printed for each account.';
                    }
                    field(ShowTransWithoutVAT; ShowTransactionWithoutVAT)
                    {
                        ApplicationArea = VAT;
                        Caption = 'Show Transactions without VAT';
                        ToolTip = 'Specifies if you want to have transactions without VAT amounts printed in the report.';
                    }
                }
            }
        }
    }

    labels
    {
        VATReconciliationCaption = 'VAT Reconciliation';
        PageCaption = 'Page';
        PostingDateCaption = 'Posting Date';
        BaseAmountSalesVATCaption = 'Base Amount Sales VAT';
        SalesVATCaption = 'Sales VAT';
        BaseAmountRevChargesCaption = 'Base Amount Reverse Charges';
        SalesVATRevChargesCaption = 'Sales VAT Reverse Charges';
        BaseAmountPurchVATCaption = 'Base Amount Purchase VAT';
        PurchVATCaption = 'Purchase VAT';
        TotalCaption = 'Total';
    }

    local procedure ResetGlobalVariables()
    begin
        BaseAmountRevCharges := 0;
        SalesVATRevCharges := 0;
        BaseAmountSalesVAT := 0;
        SalesVAT := 0;
        BaseAmountPurchVAT := 0;
        PurchVAT := 0;
    end;

    var
        GLAccount: Record "G/L Account";
        ShowIndividualTransaction: Boolean;
        ShowTransactionWithoutVAT: Boolean;
        BaseAmountRevCharges: Decimal;
        SalesVATRevCharges: Decimal;
        BaseAmountSalesVAT: Decimal;
        SalesVAT: Decimal;
        BaseAmountPurchVAT: Decimal;
        PurchVAT: Decimal;
}