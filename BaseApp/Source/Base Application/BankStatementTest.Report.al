#if not CLEAN19
report 11707 "Bank Statement - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './BankStatementTest.rdlc';
    Caption = 'Bank Statement - Test (Obsolete)';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    dataset
    {
        dataitem("Bank Statement Header"; "Bank Statement Header")
        {
            CalcFields = Amount;
            RequestFilterFields = "No.", "Bank Account No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Filters; GetFilters)
            {
            }
            column(No_BankStatementHeader; "No.")
            {
                IncludeCaption = true;
            }
            column(DocumentDate_BankStatementHeader; "Document Date")
            {
                IncludeCaption = true;
            }
            column(Amount_BankStatementHeader; Amount)
            {
                IncludeCaption = true;
            }
            column(BeginingBalance; BankAcc.Balance)
            {
            }
            dataitem("Bank Statement Line"; "Bank Statement Line")
            {
                DataItemLink = "Bank Statement No." = FIELD("No.");
                DataItemTableView = SORTING("Bank Statement No.", "Line No.");
                column(BankStatementNo_BankStatementLine; "Bank Statement No.")
                {
                }
                column(LineNo_BankStatementLine; "Line No.")
                {
                }
                column(Type_BankStatementLine; Type)
                {
                    IncludeCaption = true;
                }
                column(No_BankStatementLine; "No.")
                {
                    IncludeCaption = true;
                }
                column(Description_BankStatementLine; Description)
                {
                    IncludeCaption = true;
                }
                column(AccountNo_BankStatementLine; "Account No.")
                {
                    IncludeCaption = true;
                }
                column(VariableSymbol_BankStatementLine; "Variable Symbol")
                {
                    IncludeCaption = true;
                }
                column(SpecificSymbol_BankStatementLine; "Specific Symbol")
                {
                    IncludeCaption = true;
                }
                column(Amount_BankStatementLine; Amount)
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
                var
                    IssuedBankStmtLn: Record "Issued Bank Statement Line";
                begin
                    IssuedBankStmtLn.TransferFields("Bank Statement Line");
                    Clear(IssueBankStatement);
                    if IssueBankStatement.CheckBankStatementLine(IssuedBankStmtLn, false, true) then;
                    TransferFields(IssuedBankStmtLn);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                NotFirst := true;

                BankAcc.Get("Bank Account No.");
                BankAcc.CalcFields(Balance);
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
        ReportNameLbl = 'Bank Statement - test';
        BeginingBalanceLbl = 'Begining Balance';
        EndingBalanceLbl = 'Ending Balance';
        ErrorTextLbl = 'Warning!';
        TotalLbl = 'Total';
    }

    var
        BankAcc: Record "Bank Account";
        IssueBankStatement: Codeunit "Issue Bank Statement";
        ErrorText: Text;
        NotFirst: Boolean;
}

#endif