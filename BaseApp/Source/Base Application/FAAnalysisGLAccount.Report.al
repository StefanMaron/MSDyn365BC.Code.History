report 31041 "FA - Analysis G/L Account"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FAAnalysisGLAccount.rdlc';
    Caption = 'FA - Analysis G/L Account';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = SORTING("No.") WHERE("Account Type" = CONST(Posting));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(CurrReport_PAGENO; CurrReport.PageNo)
            {
            }
            column(USERID; UserId)
            {
            }
            column(gteFilterGLAcc; FilterGLAcc)
            {
            }
            column(G_L_Account__No__; "No.")
            {
            }
            column(G_L_Account_Name; Name)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(G_L_Account_NameCaption; FieldCaption(Name))
            {
            }
            column(G_L_Account__No__Caption; FieldCaption("No."))
            {
            }
            column(FA_Ledger_Entry_DescriptionCaption; "FA Ledger Entry".FieldCaption(Description))
            {
            }
            column(FA_Ledger_Entry__FA_Posting_Type_Caption; "FA Ledger Entry".FieldCaption("FA Posting Type"))
            {
            }
            column(FA_Ledger_Entry__Debit_Amount_Caption; "FA Ledger Entry".FieldCaption("Debit Amount"))
            {
            }
            column(FA_Ledger_Entry__Credit_Amount_Caption; "FA Ledger Entry".FieldCaption("Credit Amount"))
            {
            }
            column(FA_Ledger_Entry__FA_No__Caption; "FA Ledger Entry".FieldCaption("FA No."))
            {
            }
            column(FA_Ledger_Entry__Depreciation_Book_Code_Caption; "FA Ledger Entry".FieldCaption("Depreciation Book Code"))
            {
            }
            column(FA_Ledger_Entry__Document_No__Caption; "FA Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(FA_Ledger_Entry__Posting_Date_Caption; "FA Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(FA_Ledger_Entry__Global_Dimension_1_Code_Caption; "FA Ledger Entry".FieldCaption("Global Dimension 1 Code"))
            {
            }
            column(greIM_DescriptionCaption; FA_DescriptionCaptionLbl)
            {
            }
            column(FA_Ledger_Entry__Global_Dimension_2_Code_Caption; "FA Ledger Entry".FieldCaption("Global Dimension 2 Code"))
            {
            }
            column(FA___Analysis_G_L_AccountCaption; FA___Analysis_G_L_AccCaptionLbl)
            {
            }
            column(G_L_Account_Date_Filter; "Date Filter")
            {
            }
            column(G_L_Account_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemLink = "G/L Account No." = FIELD("No."), "Posting Date" = FIELD("Date Filter"), "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"), "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter");
                DataItemTableView = SORTING("G/L Account No.", "Posting Date");
                PrintOnlyIfDetail = true;
                column(gdeTotalCredit; TotalCredit)
                {
                }
                column(gdeTotalDebit; TotalDebit)
                {
                }
                column(G_L_Entry__G_L_Account_No__; "G/L Account No.")
                {
                }
                column(totalCaption; TotalCaptionLbl)
                {
                }
                column(G_L_Entry_Entry_No_; "Entry No.")
                {
                }
                column(G_L_Entry_Posting_Date; "Posting Date")
                {
                }
                column(G_L_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(G_L_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }
                dataitem("FA Ledger Entry"; "FA Ledger Entry")
                {
                    DataItemLink = "G/L Entry No." = FIELD("Entry No."), "Posting Date" = FIELD("Posting Date");
                    DataItemTableView = SORTING("G/L Entry No.");
                    RequestFilterFields = "FA Posting Type";
                    column(FA_Ledger_Entry__Posting_Date_; "Posting Date")
                    {
                    }
                    column(FA_Ledger_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(FA_Ledger_Entry__Depreciation_Book_Code_; "Depreciation Book Code")
                    {
                    }
                    column(FA_Ledger_Entry__FA_No__; "FA No.")
                    {
                    }
                    column(FA_Ledger_Entry_Description; Description)
                    {
                    }
                    column(FA_Ledger_Entry__FA_Posting_Type_; "FA Posting Type")
                    {
                    }
                    column(FA_Ledger_Entry__Debit_Amount_; "Debit Amount")
                    {
                    }
                    column(FA_Ledger_Entry__Credit_Amount_; "Credit Amount")
                    {
                    }
                    column(FA_Ledger_Entry__Global_Dimension_1_Code_; "Global Dimension 1 Code")
                    {
                    }
                    column(greIM_Description; FA.Description)
                    {
                    }
                    column(FA_Ledger_Entry__Global_Dimension_2_Code_; "Global Dimension 2 Code")
                    {
                    }
                    column(FA_Ledger_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(FA_Ledger_Entry_G_L_Entry_No_; "G/L Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not FA.Get("FA No.") then
                            FA.Init;

                        TotalDebit += "Debit Amount";
                        TotalCredit += "Credit Amount";
                    end;
                }

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", 1, LastGLEntry);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TotalDebit := 0;
                TotalCredit := 0;
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("No.") = '' then
                    Error(Text001Err, TableCaption);

                if "G/L Entry".FindLast then
                    LastGLEntry := "G/L Entry"."Entry No.";
            end;
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

    trigger OnPreReport()
    begin
        FilterGLAcc := "G/L Account".GetFilters;
    end;

    var
        FA: Record "Fixed Asset";
        FilterGLAcc: Text;
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        LastGLEntry: Integer;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        FA_DescriptionCaptionLbl: Label 'FA Description';
        FA___Analysis_G_L_AccCaptionLbl: Label 'FA - Analysis G/L Account';
        TotalCaptionLbl: Label 'total';
        Text001Err: Label 'Enter %1.';
}

