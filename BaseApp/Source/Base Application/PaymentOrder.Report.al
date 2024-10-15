#if not CLEAN19
report 11709 "Payment Order"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PaymentOrder.rdlc';
    Caption = 'Payment Order (Obsolete)';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    dataset
    {
        dataitem("Issued Payment Order Header"; "Issued Payment Order Header")
        {
            CalcFields = Amount;
            RequestFilterFields = "No.", "Bank Account No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(gteFiltr; Filtr)
            {
            }
            column(Issued_Payment_Order_Header__No__; "No.")
            {
            }
            column(Issued_Payment_Order_Header__Bank_Account_No__; "Bank Account No.")
            {
            }
            column(Issued_Payment_Order_Header__Account_No__; "Account No.")
            {
            }
            column(Issued_Payment_Order_Header__Document_Date_; "Document Date")
            {
            }
            column(Issued_Payment_Order_Header__Currency_Code_; "Currency Code")
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Issued_Payment_OrderCaption; Issued_Payment_OrderCaptionLbl)
            {
            }
            column(Issued_Payment_Order_Header__No__Caption; FieldCaption("No."))
            {
            }
            column(Issued_Payment_Order_Header__Bank_Account_No__Caption; FieldCaption("Bank Account No."))
            {
            }
            column(Issued_Payment_Order_Header__Account_No__Caption; FieldCaption("Account No."))
            {
            }
            column(Issued_Payment_Order_Header__Document_Date_Caption; FieldCaption("Document Date"))
            {
            }
            column(Issued_Payment_Order_Header__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            dataitem("Issued Payment Order Line"; "Issued Payment Order Line")
            {
                DataItemLink = "Payment Order No." = FIELD("No.");
                DataItemTableView = SORTING("Payment Order No.", "Line No.") WHERE(Status = CONST(" "));
                column(Issued_Payment_Order_Line_Description; Description)
                {
                }
                column(Issued_Payment_Order_Line__Account_No__; "Account No.")
                {
                }
                column(Issued_Payment_Order_Line__Variable_Symbol_; "Variable Symbol")
                {
                }
                column(Issued_Payment_Order_Line__Constant_Symbol_; "Constant Symbol")
                {
                }
                column(Issued_Payment_Order_Line__Specific_Symbol_; "Specific Symbol")
                {
                }
                column(Issued_Payment_Order_Line_Amount; Amount)
                {
                }
                column(Issued_Payment_Order_Header__Amount; "Issued Payment Order Header".Amount)
                {
                }
                column(Issued_Payment_Order_Line_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Issued_Payment_Order_Line__Account_No__Caption; FieldCaption("Account No."))
                {
                }
                column(Issued_Payment_Order_Line__Variable_Symbol_Caption; FieldCaption("Variable Symbol"))
                {
                }
                column(Issued_Payment_Order_Line__Constant_Symbol_Caption; FieldCaption("Constant Symbol"))
                {
                }
                column(Issued_Payment_Order_Line__Specific_Symbol_Caption; FieldCaption("Specific Symbol"))
                {
                }
                column(Issued_Payment_Order_Line_AmountCaption; FieldCaption(Amount))
                {
                }
                column(Total_AmountCaption; Total_AmountCaptionLbl)
                {
                }
                column(Issued_Payment_Order_Line_Payment_Order_No_; "Payment Order No.")
                {
                }
                column(Issued_Payment_Order_Line_Line_No_; "Line No.")
                {
                }
            }

            trigger OnPreDataItem()
            begin
                Filtr := CopyStr(GetFilters, 1, MaxStrLen(Filtr))
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
        Filtr: Text[250];
        PageCaptionLbl: Label 'Page';
        Issued_Payment_OrderCaptionLbl: Label 'Issued Payment Order';
        Total_AmountCaptionLbl: Label 'Total Amount';
}


#endif