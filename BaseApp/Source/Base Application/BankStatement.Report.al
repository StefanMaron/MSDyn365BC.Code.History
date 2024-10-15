#if not CLEAN19
report 11706 "Bank Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './BankStatement.rdlc';
    Caption = 'Bank Statement (Obsolete)';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    dataset
    {
        dataitem("Issued Bank Statement Header"; "Issued Bank Statement Header")
        {
            CalcFields = Amount;
            RequestFilterFields = "No.", "Bank Account No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(gteFiltr; Filter)
            {
            }
            column(Issued_Bank_Statement_Header__No__; "No.")
            {
            }
            column(Issued_Bank_Statement_Header__Bank_Account_No__; "Bank Account No.")
            {
            }
            column(Issued_Bank_Statement_Header__Account_No__; "Account No.")
            {
            }
            column(Issued_Bank_Statement_Header__Document_Date_; "Document Date")
            {
            }
            column(Issued_Bank_Statement_Header__Currency_Code_; "Currency Code")
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Issued_Bank_Statement_LineCaption; Issued_Bank_Statement_LineCaptionLbl)
            {
            }
            column(Issued_Bank_Statement_Header__No__Caption; FieldCaption("No."))
            {
            }
            column(Issued_Bank_Statement_Header__Bank_Account_No__Caption; FieldCaption("Bank Account No."))
            {
            }
            column(Issued_Bank_Statement_Header__Account_No__Caption; FieldCaption("Account No."))
            {
            }
            column(Issued_Bank_Statement_Header__Document_Date_Caption; FieldCaption("Document Date"))
            {
            }
            column(Issued_Bank_Statement_Header__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            dataitem("Issued Bank Statement Line"; "Issued Bank Statement Line")
            {
                DataItemLink = "Bank Statement No." = FIELD("No.");
                DataItemTableView = SORTING("Bank Statement No.", "Line No.");
                column(Issued_Bank_Statement_Line_Description; Description)
                {
                }
                column(Issued_Bank_Statement_Line__Account_No__; "Account No.")
                {
                }
                column(Issued_Bank_Statement_Line__Variable_Symbol_; "Variable Symbol")
                {
                }
                column(Issued_Bank_Statement_Line__Constant_Symbol_; "Constant Symbol")
                {
                }
                column(Issued_Bank_Statement_Line__Specific_Symbol_; "Specific Symbol")
                {
                }
                column(Issued_Bank_Statement_Line_Amount; Amount)
                {
                }
                column(Issued_Bank_Statement_Header__Amount; "Issued Bank Statement Header".Amount)
                {
                }
                column(Issued_Bank_Statement_Line_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Issued_Bank_Statement_Line__Account_No__Caption; FieldCaption("Account No."))
                {
                }
                column(Issued_Bank_Statement_Line__Variable_Symbol_Caption; FieldCaption("Variable Symbol"))
                {
                }
                column(Issued_Bank_Statement_Line__Constant_Symbol_Caption; FieldCaption("Constant Symbol"))
                {
                }
                column(Issued_Bank_Statement_Line__Specific_Symbol_Caption; FieldCaption("Specific Symbol"))
                {
                }
                column(Issued_Bank_Statement_Line_AmountCaption; FieldCaption(Amount))
                {
                }
                column(Total_AmountCaption; Total_AmountCaptionLbl)
                {
                }
                column(Issued_Bank_Statement_Line_Bank_Statement_No_; "Bank Statement No.")
                {
                }
                column(Issued_Bank_Statement_Line_Line_No_; "Line No.")
                {
                }
            }

            trigger OnPreDataItem()
            begin
                Filter := CopyStr(GetFilters, 1, MaxStrLen(Filter))
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

    var
        PageCaptionLbl: Label 'Page';
        Issued_Bank_Statement_LineCaptionLbl: Label 'Issued Bank Statement Line';
        Total_AmountCaptionLbl: Label 'Total Amount';
        "Filter": Text[250];
}

#endif