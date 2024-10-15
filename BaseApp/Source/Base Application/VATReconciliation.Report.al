report 13620 "VAT Reconciliation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VATReconciliation.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Reconciliation';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = SORTING("G/L Account No.", "Posting Date");
            RequestFilterFields = "G/L Account No.", "Posting Date";
            column(CompanyName; COMPANYPROPERTY.DisplayName)
            {
            }
            column(GLEntryTableFilters; TableCaption + ': ' + GetFilters)
            {
            }
            column(ShowDetails; ShowDetails)
            {
            }
            column(VATAmount_GLEntry; "VAT Amount")
            {
            }
            column(GLAccountNo_GLEntry; "G/L Account No.")
            {
            }
            column(PostingDate_GLEntry; Format("Posting Date"))
            {
            }
            column(DocumentNo_GLEntry; "Document No.")
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
            column(IsClosingPostingDate; IsClosingPostingDate)
            {
            }
            column(GLAccountName; GLAccount.Name)
            {
            }
            column(VATReconciliationCaption; VATReconciliationCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(GLAccountNoCaption_GLEntry; FieldCaption("G/L Account No."))
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(DocumentNoCaption_GLEntry; FieldCaption("Document No."))
            {
            }
            column(BaseAmtSalesVATCaption; BaseAmtSalesVATCaptionLbl)
            {
            }
            column(SalesVATCaption; SalesVATCaptionLbl)
            {
            }
            column(BaseAmtRevChargesCaption; BaseAmtRevChargesCaptionLbl)
            {
            }
            column(SalesVATRevChargesCaption; SalesVATRevChargesCaptionLbl)
            {
            }
            column(BaseAmountPurchVATCaption; BaseAmountPurchVATCaptionLbl)
            {
            }
            column(PurchVATCaption; PurchVATCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                ClosingDate: Date;
            begin
                BaseAmountSalesVAT := 0;
                BaseAmountRevCharges := 0;
                BaseAmountPurchVAT := 0;
                SalesVAT := 0;
                PurchVAT := 0;
                SalesVATRevCharges := 0;

                if not ShowDetails and ("VAT Amount" = 0) and not ShowTransWithoutVAT then
                    CurrReport.Skip();

                if "VAT Amount" <> 0 then begin
                    VATEntry.SetRange("Transaction No.", "Transaction No.");
                    VATEntry.SetRange(Amount, "VAT Amount");
                    VATEntry.FindFirst();
                    if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Reverse Charge VAT" then begin
                        BaseAmountRevCharges := VATEntry.Base;
                        SalesVATRevCharges := VATEntry.Amount;
                    end else
                        if "Gen. Posting Type" = "Gen. Posting Type"::Sale then begin
                            BaseAmountSalesVAT := -VATEntry.Base;
                            SalesVAT := -VATEntry.Amount;
                        end else begin
                            BaseAmountPurchVAT := VATEntry.Base;
                            PurchVAT := VATEntry.Amount;
                        end;
                end;

                if ((not ShowDetails) or (ShowDetails and (not ("VAT Amount" = 0) or ShowTransWithoutVAT))) and
                   (GLAccount."No." <> "G/L Account No.")
                then
                    GLAccount.Get("G/L Account No.");

                // new client
                ClosingDate := SYSTEM.ClosingDate("Posting Date");
                IsClosingPostingDate := (ClosingDate = "Posting Date");
            end;

            trigger OnPreDataItem()
            begin
                VATEntry.SetCurrentKey("Transaction No.");
                Clear(PurchVAT);
                Clear(SalesVATRevCharges);
                if not ShowTransWithoutVAT then
                    SetFilter("VAT Amount", '<>0');
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
                    field(ShowDetails; ShowDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Details';
                        ToolTip = 'Specifies if you want to print all transaction amounts in the report. Otherwise, a single cumulative line is printed for each general ledger account.';
                    }
                    field(ShowTransWithoutVAT; ShowTransWithoutVAT)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Transactions without VAT';
                        ToolTip = 'Specifies if you want to print a line for each general ledger account that transactions are posted to. You can use this option for both single accounts and multiple accounts.';
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
        GLAccount: Record "G/L Account";
        VATEntry: Record "VAT Entry";
        ShowDetails: Boolean;
        ShowTransWithoutVAT: Boolean;
        BaseAmountSalesVAT: Decimal;
        BaseAmountRevCharges: Decimal;
        BaseAmountPurchVAT: Decimal;
        SalesVAT: Decimal;
        PurchVAT: Decimal;
        SalesVATRevCharges: Decimal;
        IsClosingPostingDate: Boolean;
        VATReconciliationCaptionLbl: Label 'VAT Reconciliation';
        PageNoCaptionLbl: Label 'Page';
        PostingDateCaptionLbl: Label 'Posting Date';
        BaseAmtSalesVATCaptionLbl: Label 'Base Amount Sales VAT';
        SalesVATCaptionLbl: Label 'Sales VAT';
        BaseAmtRevChargesCaptionLbl: Label 'Base Amount Reverse Charges';
        SalesVATRevChargesCaptionLbl: Label 'Sales VAT Reverse Charges';
        BaseAmountPurchVATCaptionLbl: Label 'Base Amount Purchase VAT';
        PurchVATCaptionLbl: Label 'Purchase VAT';
        TotalCaptionLbl: Label 'Total';
}

