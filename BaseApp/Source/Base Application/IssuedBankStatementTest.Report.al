#if not CLEAN19
report 11708 "Issued Bank Statement - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './IssuedBankStatementTest.rdlc';
    Caption = 'Issued Bank Statement - Test (Obsolete)';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    dataset
    {
        dataitem("Issued Bank Statement Header"; "Issued Bank Statement Header")
        {
            CalcFields = Amount;
            RequestFilterFields = "No.", "Bank Account No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(Filters; GetFilters)
            {
            }
            column(No_IssuedBankStatementHeader; "No.")
            {
                IncludeCaption = true;
            }
            column(DocumentDate_IssuedBankStatementHeader; "Document Date")
            {
                IncludeCaption = true;
            }
            column(Amount_IssuedBankStatementHeader; Amount)
            {
                IncludeCaption = true;
            }
            dataitem("Issued Bank Statement Line"; "Issued Bank Statement Line")
            {
                DataItemLink = "Bank Statement No." = FIELD("No.");
                DataItemTableView = SORTING("Bank Statement No.", "Line No.");
                column(BankStatementNo_IssuedBankStatementLine; "Bank Statement No.")
                {
                }
                column(LineNo_IssuedBankStatementLine; "Line No.")
                {
                }
                column(Type_IssuedBankStatementLine; Type)
                {
                    IncludeCaption = true;
                }
                column(No_IssuedBankStatementLine; "No.")
                {
                    IncludeCaption = true;
                }
                column(Description_IssuedBankStatementLine; Description)
                {
                    IncludeCaption = true;
                }
                column(AccountNo_IssuedBankStatementLine; "Account No.")
                {
                    IncludeCaption = true;
                }
                column(VariableSymbol_IssuedBankStatementLine; "Variable Symbol")
                {
                    IncludeCaption = true;
                }
                column(SpecificSymbol_IssuedBankStatementLine; "Specific Symbol")
                {
                    IncludeCaption = true;
                }
                column(Amount_IssuedBankStatementLine; Amount)
                {
                    IncludeCaption = true;
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = SORTING(Number) WHERE(Number = FILTER(1 ..));
                    column(ErrorText; ErrorText)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        IssueBankStatement.ReturnError(ErrorText, Number);
                        if ErrorText = '' then
                            CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(IssueBankStatement);
                    if IssueBankStatement.CheckBankStatementLine("Issued Bank Statement Line", false, true) then;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                NotFirst := true;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
        PageLbl = 'Page';
        ReportNameLbl = 'Issued Bank Statement - test';
        ErrorTextLbl = 'Warning!';
        TotalLbl = 'Total';
    }

    var
        IssueBankStatement: Codeunit "Issue Bank Statement";
        ErrorText: Text;
        NotFirst: Boolean;
}

#endif