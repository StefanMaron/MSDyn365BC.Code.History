report 11710 "Payment Order - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './PaymentOrderTest.rdlc';
    Caption = 'Payment Order - Test';

    dataset
    {
        dataitem("Payment Order Header"; "Payment Order Header")
        {
            RequestFilterFields = "No.", "Bank Account No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(Filters; Filters)
            {
            }
            column(Payment_Order_Header__No__; "No.")
            {
            }
            column(Payment_Order_Header__Bank_Account_No__; "Bank Account No.")
            {
            }
            column(Payment_Order_Header__Account_No__; "Account No.")
            {
            }
            column(Payment_Order_Header__Document_Date_; "Document Date")
            {
            }
            column(Payment_Order_Header__Currency_Code_; "Currency Code")
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Payment_OrderCaption; Payment_Order___testCaptionLbl)
            {
            }
            column(Payment_Order_Header__No__Caption; FieldCaption("No."))
            {
            }
            column(Payment_Order_Header__Bank_Account_No__Caption; FieldCaption("Bank Account No."))
            {
            }
            column(Payment_Order_Header__Account_No__Caption; FieldCaption("Account No."))
            {
            }
            column(Payment_Order_Header__Document_Date_Caption; FieldCaption("Document Date"))
            {
            }
            column(Payment_Order_Header__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            dataitem("Payment Order Line"; "Payment Order Line")
            {
                DataItemLink = "Payment Order No." = FIELD("No.");
                DataItemTableView = SORTING("Payment Order No.", "Line No.");
                column(Payment_Order_Line_Description; Description)
                {
                }
                column(Payment_Order_Line__Account_No__; "Account No.")
                {
                }
                column(Payment_Order_Line__Variable_Symbol_; "Variable Symbol")
                {
                }
                column(Payment_Order_Line__Constant_Symbol_; "Constant Symbol")
                {
                }
                column(Payment_Order_Line__Specific_Symbol_; "Specific Symbol")
                {
                }
                column(Payment_Order_Line_Amount_to_Pay_; "Amount to Pay")
                {
                }
                column(Payment_Order_Header__Amount; "Payment Order Header".Amount)
                {
                }
                column(Payment_Order_Line_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Payment_Order_Line__Account_No__Caption; FieldCaption("Account No."))
                {
                }
                column(Payment_Order_Line__Variable_Symbol_Caption; FieldCaption("Variable Symbol"))
                {
                }
                column(Payment_Order_Line__Constant_Symbol_Caption; FieldCaption("Constant Symbol"))
                {
                }
                column(Payment_Order_Line__Specific_Symbol_Caption; FieldCaption("Specific Symbol"))
                {
                }
                column(Payment_Order_Line_Amount_to_Pay_Caption; FieldCaption("Amount to Pay"))
                {
                }
                column(Total_AmountCaption; Total_AmountCaptionLbl)
                {
                }
                column(Payment_Order_Line_Payment_Order_No_; "Payment Order No.")
                {
                }
                column(Payment_Order_Line_Line_No_; "Line No.")
                {
                }
                column(TotalAmount; TotalAmount)
                {
                }
                dataitem("Error Message"; "Error Message")
                {
                    DataItemTableView = SORTING(ID);
                    UseTemporary = true;
                    column(ID_ErrorMessage; ID)
                    {
                    }
                    column(MessageType_ErrorMessage; "Message Type")
                    {
                    }
                    column(Description_ErrorMessage; Description)
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        SetRange("Record ID", "Payment Order Line".RecordId);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    PaymentOrderManagement.CheckPaymentOrderLineCustVendBlocked("Payment Order Line", false);
                    PaymentOrderManagement.CheckPaymentOrderLineApply("Payment Order Line", false);
                    PaymentOrderManagement.CheckPaymentOrderLineFormat("Payment Order Line", false);
                    PaymentOrderManagement.CopyErrorMessageToTemp("Error Message");

                    TotalAmount += "Amount to Pay";
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Skip Payment", false);
                    if PrintIncludingSkipPayments then
                        SetRange("Skip Payment");

                    AddToFilter(GetFilters);
                end;
            }

            trigger OnPreDataItem()
            begin
                AddToFilter(GetFilters);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(General)
                {
                    Caption = 'General';
                    field(PrintIncludingSkipPayments; PrintIncludingSkipPayments)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print including skip payments';
                        ToolTip = 'Specifies if the document will be print including skip payments';
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
        PageCaptionLbl: Label 'Page';
        Payment_Order___testCaptionLbl: Label 'Payment Order - test';
        Total_AmountCaptionLbl: Label 'Total Amount';
        PaymentOrderManagement: Codeunit "Payment Order Management";
        Filters: Text;
        PrintIncludingSkipPayments: Boolean;
        TotalAmount: Decimal;

    local procedure AddToFilter("Filter": Text)
    begin
        if Filters = '' then
            Filters := Filter
        else
            Filters += StrSubstNo(', %1', Filter);
    end;
}

