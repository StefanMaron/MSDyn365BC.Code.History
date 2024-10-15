report 10861 "GL/Cust. Ledger Reconciliation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './GLCustLedgerReconciliation.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'GL/Cust. Ledger Reconciliation';
    Permissions = TableData "Invoice Post. Buffer" = rimd;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter";
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(LastNo; LastNo)
            {
            }
            column(FirstNo; FirstNo)
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(Customer_Name; Name)
            {
            }
            column(TotalDebit; TotalDebit)
            {
            }
            column(TotalCredit; TotalCredit)
            {
            }
            column(TotalDebit_TotalCredit; TotalDebit - TotalCredit)
            {
            }
            column(General_Customer_ledger_reconciliationCaption; General_Customer_ledger_reconciliationCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(G_L_Entry__Debit_Amount_Caption; "G/L Entry".FieldCaption("Debit Amount"))
            {
            }
            column(G_L_Entry__Credit_Amount_Caption; "G/L Entry".FieldCaption("Credit Amount"))
            {
            }
            column(G_L_Entry_AmountCaption; "G/L Entry".FieldCaption(Amount))
            {
            }
            column(G_L_Entry_DescriptionCaption; "G/L Entry".FieldCaption(Description))
            {
            }
            column(G_L_Entry__Document_No__Caption; "G/L Entry".FieldCaption("Document No."))
            {
            }
            column(G_L_Entry__Document_Type_Caption; "G/L Entry".FieldCaption("Document Type"))
            {
            }
            column(G_L_Entry__G_L_Account_No__Caption; "G/L Entry".FieldCaption("G/L Account No."))
            {
            }
            column(G_L_Entry__Posting_Date_Caption; G_L_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(General_AmountCaption; General_AmountCaptionLbl)
            {
            }
            dataitem("Customer Posting Group"; "Customer Posting Group")
            {
                DataItemTableView = SORTING(Code);
                PrintOnlyIfDetail = true;
                column(TotalDebit_TotalCredit_Control1120015; TotalDebit - TotalCredit)
                {
                }
                column(TotalCredit_Control1120014; TotalCredit)
                {
                }
                column(TotalDebit_Control1120013; TotalDebit)
                {
                }
                column(Customer_Posting_Group_Code; Code)
                {
                }
                column(Customer_Posting_Group_Receivables_Account; "Receivables Account")
                {
                }
                column(Total_amount_for_the_customerCaption; Total_amount_for_the_customerCaptionLbl)
                {
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "G/L Account No." = FIELD("Receivables Account");
                    DataItemTableView = SORTING("G/L Account No.", "Source Type", "Source No.") WHERE(Amount = FILTER(<> 0));
                    column(G_L_Entry__Debit_Amount_; "Debit Amount")
                    {
                    }
                    column(G_L_Entry__Credit_Amount_; "Credit Amount")
                    {
                    }
                    column(G_L_Entry_Amount; Amount)
                    {
                    }
                    column(G_L_Entry__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(G_L_Entry_Description; Description)
                    {
                    }
                    column(G_L_Entry__Document_Type_; "Document Type")
                    {
                    }
                    column(G_L_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(G_L_Entry__G_L_Account_No__; "G/L Account No.")
                    {
                    }
                    column(G_L_Entry__Debit_Amount__Control1120036; "Debit Amount")
                    {
                    }
                    column(G_L_Entry__Credit_Amount__Control1120037; "Credit Amount")
                    {
                    }
                    column(G_L_Entry_Amount_Control1120038; Amount)
                    {
                    }
                    column(G_L_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Total_amount_for_the_general_ledgerCaption; Total_amount_for_the_general_ledgerCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if ("Bal. Account Type" = "Bal. Account Type"::Customer) and ("Bal. Account No." = Customer."No.") then
                            CurrReport.Skip();
                        TotalDebit := TotalDebit + "Debit Amount";
                        TotalCredit := TotalCredit + "Credit Amount";
                        InvPostBuf.Get(InvPostBuf.Type::"G/L Account", "G/L Account No.");
                        InvPostBuf.Amount := InvPostBuf.Amount + Amount;
                        InvPostBuf.Modify();
                        HavingNoDetail := false;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Source Type", "Source Type"::Customer);
                        SetRange("Source No.", Customer."No.");
                        SetRange("Posting Date", Customer.GetRangeMin("Date Filter"), Customer.GetRangeMax("Date Filter"));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(PostingBuffer);
                    PostingBuffer."Account Type" := PostingBuffer."Account Type"::"G/L Account";
                    PostingBuffer."Account No." := "Receivables Account";
                    if not PostingBuffer.Insert() then
                        CurrReport.Skip();
                    Clear(InvPostBuf);
                    InvPostBuf.Type := InvPostBuf.Type::"G/L Account";
                    InvPostBuf."G/L Account" := "Receivables Account";
                    if not InvPostBuf.Insert() then;
                end;

                trigger OnPostDataItem()
                begin
                    PostingBuffer.DeleteAll();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TotalDebit := 0;
                TotalCredit := 0;
                HavingNoDetail := true;
            end;

            trigger OnPreDataItem()
            begin
                Clear(TotalDebit);
                Clear(TotalCredit);
                Customer.FindFirst();
                FirstNo := "No.";
                Customer.FindLast();
                LastNo := "No.";
            end;
        }
        dataitem("Invoice Post. Buffer"; "Invoice Post. Buffer")
        {
            DataItemTableView = SORTING(Type, "G/L Account", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Area Code", "Tax Group Code", "Tax Liable", "Use Tax", "Dimension Set ID", "Job No.", "Fixed Asset Line No.") WHERE(Amount = FILTER(<> 0));
            column(HavingNoDetail; HavingNoDetail)
            {
            }
            column(Invoice_Post__Buffer_Amount; Amount)
            {
            }
            column(Invoice_Post__Buffer__G_L_Account_; "G/L Account")
            {
            }
            column(Invoice_Post__Buffer_Type; Type)
            {
            }
            column(Invoice_Post__Buffer_Gen__Bus__Posting_Group; "Gen. Bus. Posting Group")
            {
            }
            column(Invoice_Post__Buffer_Gen__Prod__Posting_Group; "Gen. Prod. Posting Group")
            {
            }
            column(Invoice_Post__Buffer_VAT_Bus__Posting_Group; "VAT Bus. Posting Group")
            {
            }
            column(Invoice_Post__Buffer_VAT_Prod__Posting_Group; "VAT Prod. Posting Group")
            {
            }
            column(Invoice_Post__Buffer_Tax_Area_Code; "Tax Area Code")
            {
            }
            column(Invoice_Post__Buffer_Tax_Group_Code; "Tax Group Code")
            {
            }
            column(Invoice_Post__Buffer_Tax_Liable; "Tax Liable")
            {
            }
            column(Invoice_Post__Buffer_Use_Tax; "Use Tax")
            {
            }
            column(Invoice_Post__Buffer_Dimension_Set_ID; "Dimension Set ID")
            {
            }
            column(Invoice_Post__Buffer_Job_No_; "Job No.")
            {
            }
            column(Invoice_Post__Buffer_Fixed_Asset_Line_No_; "Fixed Asset Line No.")
            {
            }
            column(General_amount_for_the_general_ledgerCaption; General_amount_for_the_general_ledgerCaptionLbl)
            {
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        InvPostBuf.DeleteAll();
    end;

    var
        PostingBuffer: Record "Payment Post. Buffer" temporary;
        InvPostBuf: Record "Invoice Post. Buffer";
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        FirstNo: Code[20];
        LastNo: Code[20];
        HavingNoDetail: Boolean;
        General_Customer_ledger_reconciliationCaptionLbl: Label 'General/Customer ledger reconciliation';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        G_L_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        General_AmountCaptionLbl: Label 'General Amount';
        Total_amount_for_the_customerCaptionLbl: Label 'Total amount for the customer';
        Total_amount_for_the_general_ledgerCaptionLbl: Label 'Total amount for the general ledger';
        General_amount_for_the_general_ledgerCaptionLbl: Label 'General amount for the general ledger';
}

