report 11742 "Cash Desk Book"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CashDeskBook.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Desk Book (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            DataItemTableView = SORTING("No.") WHERE("Account Type" = CONST("Cash Desk"));
            column(Bank_Account_No; "No.")
            {
                IncludeCaption = true;
            }
            column(Bank_Account_Name; Name)
            {
                IncludeCaption = true;
            }
            column(Bank_Account_Currency_Code; "Currency Code")
            {
                IncludeCaption = true;
            }
            column(Variables_CompanyAddrCA_3; CompanyAddrCA[3])
            {
            }
            column(Variables_CompanyAddrCA_2; CompanyAddrCA[2])
            {
            }
            column(Variables_CompanyAddrCA_1; CompanyAddrCA[1])
            {
            }
            column(System_Report_Id; CurrReport.ObjectId(false))
            {
            }
            column(Variables_CashDeskFilter; CashDeskFilter)
            {
            }
            column(Variables_BalanceToDate; BalanceToDate)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(Integer_Number; Number)
                {
                }
                column(TmpCashDocHeader_Payment_Purpose; TempCashDocHeader."Payment Purpose")
                {
                }
                column(TmpCashDocHeader_External_Document_No; TempCashDocHeader."External Document No.")
                {
                }
                column(TmpCashDocHeader_Posting_Date; TempCashDocHeader."Posting Date")
                {
                }
                column(TmpCashDocHeader_No; TempCashDocHeader."No.")
                {
                }
                column(Variables_Balance; Balance)
                {
                }
                column(Variables_Payment; Payment)
                {
                }
                column(Variables_Receipt; Receipt)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempCashDocHeader.FindSet
                    else
                        TempCashDocHeader.Next;

                    Receipt := 0;
                    Payment := 0;

                    case TempCashDocHeader."Cash Document Type" of
                        TempCashDocHeader."Cash Document Type"::Receipt:
                            Receipt := TempCashDocHeader."Released Amount";
                        TempCashDocHeader."Cash Document Type"::Withdrawal:
                            Payment := TempCashDocHeader."Released Amount";
                    end;

                    Balance += Receipt - Payment;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, TempCashDocHeader.Count);

                    case Sorting of
                        Sorting::PostingDate:
                            TempCashDocHeader.SetCurrentKey("Cash Desk No.", "Posting Date");
                        Sorting::CashDeskNo:
                            TempCashDocHeader.SetCurrentKey("Cash Desk No.", "No.");
                    end;

                    Balance := BalanceToDate;
                end;
            }

            trigger OnAfterGetRecord()
            var
                GLSetup: Record "General Ledger Setup";
            begin
                if "Currency Code" = '' then
                    "Currency Code" := GLSetup."LCY Code";

                CashDocHeader.SetRange("Cash Desk No.", "No.");
                CashDocHeader.SetRange(Status, CashDocHeader.Status::Released);
                CashDocHeader.SetFilter("Posting Date", '..%1', CalcDate('<-1D>', GetRangeMin("Date Filter")));

                PostedCashDocHeader.SetRange("Cash Desk No.", "No.");
                PostedCashDocHeader.SetFilter("Posting Date", '..%1', CalcDate('<-1D>', GetRangeMin("Date Filter")));

                BankAccount.Get("No.");
                BankAccount.SetFilter("Date Filter", '..%1', CalcDate('<-1D>', GetRangeMin("Date Filter")));
                BalanceToDate := BankAccount.CalcBalance;

                TempCashDocHeader.DeleteAll();
                CopyFilter("Date Filter", CashDocHeader."Posting Date");
                if CashDocHeader.FindSet then
                    repeat
                        TempCashDocHeader.Init();
                        TempCashDocHeader.TransferFields(CashDocHeader);
                        TempCashDocHeader."Released Amount" := CashDocHeader."Released Amount";
                        TempCashDocHeader.Insert();
                    until CashDocHeader.Next() = 0;

                CopyFilter("Date Filter", PostedCashDocHeader."Posting Date");
                if PostedCashDocHeader.FindSet then
                    repeat
                        TempCashDocHeader.Init();
                        TempCashDocHeader.TransferFields(PostedCashDocHeader);
                        PostedCashDocHeader.CalcFields("Amount Including VAT");
                        TempCashDocHeader."Released Amount" := PostedCashDocHeader."Amount Including VAT";
                        TempCashDocHeader.Insert();
                    until PostedCashDocHeader.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                if (StartDate <> 0D) or (EndDate <> 0D) then
                    SetFilter("Date Filter", '%1..%2', StartDate, EndDate)
                else
                    Error(EmptyMandatoryFieldsErr);

                if CashDeskNo <> '' then
                    SetRange("No.", CashDeskNo);

                if GetFilters <> '' then
                    CashDeskFilter := StrSubstNo('%1: %2', TableCaption, GetFilters);
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
                    field(CashDeskNo; CashDeskNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Desk No.';
                        TableRelation = "Bank Account" WHERE("Account Type" = CONST("Cash Desk"));
                        ToolTip = 'Specifies the cash desk that the printed book will be drawn from.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            BankAcc: Record "Bank Account";
                        begin
                            if PAGE.RunModal(PAGE::"Cash Desk List", BankAcc) = ACTION::LookupOK then
                                CashDeskNo := BankAcc."No.";
                        end;

                        trigger OnValidate()
                        begin
                            CheckCashDeskNo(CashDeskNo);
                        end;
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the start date of cash desk book.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closing Date';
                        ToolTip = 'Specifies the end date of cash desk book.';
                    }
                    field(Sorting; Sorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorting';
                        OptionCaption = 'Posting Date,Cash Desk No.';
                        ToolTip = 'Specifies the method by which the entries are sorted on the report.';
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
        Label_Report_Name = 'Cash Desk Book';
        Label_Report_Description = '(Released Documents - Posted and Unposted)';
        Label_Page = 'Page';
        Label_Initial_Condition = 'Initial Condition:';
        Label_Document_No = 'Document No.';
        Label_Posting_Date = 'Posting Date';
        Label_External_Document_No = 'External Document No.';
        Label_Description = 'Description';
        Label_Payment = 'Payment';
        Label_Receipt = 'Receipt';
        Label_Balance = 'Balance';
        Label_Total = 'Total';
        Label_Date = 'Date';
        Label_Cashier_Sign = 'Cashier Sign';
    }

    trigger OnPreReport()
    begin
        if CashDeskNo = '' then
            Error(CashDeskCannotBeEmptyErr);

        GLSetup.Get();

        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddrCA, CompanyInfo);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CashDocHeader: Record "Cash Document Header";
        PostedCashDocHeader: Record "Posted Cash Document Header";
        CompanyInfo: Record "Company Information";
        BankAccount: Record "Bank Account";
        TempCashDocHeader: Record "Cash Document Header" temporary;
        FormatAddr: Codeunit "Format Address";
        BalanceToDate: Decimal;
        Balance: Decimal;
        Receipt: Decimal;
        Payment: Decimal;
        CashDeskFilter: Text[250];
        Sorting: Option PostingDate,CashDeskNo;
        CompanyAddrCA: array[8] of Text[150];
        StartDate: Date;
        EndDate: Date;
        CashDeskNo: Code[20];
        EmptyMandatoryFieldsErr: Label 'Set up mandatory fields Start Date and End Date.';
        CashDeskCannotBeEmptyErr: Label 'Cash Desk No. cannot be empty.';

    [Scope('OnPrem')]
    procedure InitializeRequest(NewCashDeskNo: Code[20]; NewStartDate: Date; NewEndDate: Date; NewSorting: Option PostingDate,CashDeskNo)
    begin
        CashDeskNo := NewCashDeskNo;
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        Sorting := NewSorting;
    end;

    local procedure CheckCashDeskNo(CashDeskNo: Code[20])
    var
        CashDeskManagement: Codeunit CashDeskManagement;
    begin
        CashDeskManagement.CheckCashDesk(CashDeskNo);
    end;
}

