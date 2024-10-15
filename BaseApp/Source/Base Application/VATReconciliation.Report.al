report 10630 "VAT Reconciliation"
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
            column(GLEntryGetFilters; "G/L Entry".TableCaption + ': ' + GetFilters)
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
            column(GLAccountName; GLAccount.Name)
            {
            }
            column(ShowDetails; ShowDetails)
            {
            }
            column(ShowTransWithoutVAT; ShowTransWithoutVAT)
            {
            }
            column(VATAmount_GLEntry; "G/L Entry"."VAT Amount")
            {
            }
            column(VATReconciliationCaption; VATReconciliationCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
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
            column(BaseAmountSalesVATCaption; BaseAmountSalesVATCaptionLbl)
            {
            }
            column(SalesVATCaption; SalesVATCaptionLbl)
            {
            }
            column(BaseAmountRevChargesCaption; BaseAmountRevChargesCaptionLbl)
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
            begin
                BaseAmountSalesVAT := 0;
                BaseAmountRevCharges := 0;
                BaseAmountPurchVAT := 0;
                SalesVAT := 0;
                PurchVAT := 0;
                SalesVATRevCharges := 0;

                if not ShowDetails and ("VAT Amount" = 0) and not ShowTransWithoutVAT then
                    CurrReport.Skip;

                VATEntry.Reset;
                VATEntry.SetRange("Transaction No.", "Transaction No.");
                VATEntry.SetRange(Amount, "VAT Amount");
                if VATEntry.FindFirst then begin
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
                end else begin
                    VATEntry.Reset;
                    VATEntry.SetRange("Transaction No.", "Transaction No.");
                    VATEntry.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                    VATEntry.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                    if VATEntry.FindSet then begin
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
                        until VATEntry.Next = 0;
                    end;
                end;
                GLAccount.Get("G/L Account No.");
            end;

            trigger OnPreDataItem()
            begin
                VATEntry.SetCurrentKey("Transaction No.");
                Clear(BaseAmountSalesVAT);
                Clear(BaseAmountRevCharges);
                Clear(BaseAmountPurchVAT);
                Clear(SalesVAT);
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
                        ToolTip = 'Specifies if you want to include individual transactions. If the check box is not selected, then only one accumulated total will be printed for each account.';
                    }
                    field(ShowTransWithoutVAT; ShowTransWithoutVAT)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Transactions without VAT';
                        ToolTip = 'Specifies if you want to have a list of all transactions without VAT amounts printed in the report.';
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
        VATReconciliationCaptionLbl: Label 'VAT Reconciliation';
        PageCaptionLbl: Label 'Page';
        PostingDateCaptionLbl: Label 'Posting Date';
        BaseAmountSalesVATCaptionLbl: Label 'Base Amount Sales VAT';
        SalesVATCaptionLbl: Label 'Sales VAT';
        BaseAmountRevChargesCaptionLbl: Label 'Base Amount Reverse Charges';
        SalesVATRevChargesCaptionLbl: Label 'Sales VAT Reverse Charges';
        BaseAmountPurchVATCaptionLbl: Label 'Base Amount Purchase VAT';
        PurchVATCaptionLbl: Label 'Purchase VAT';
        TotalCaptionLbl: Label 'Total';
}

