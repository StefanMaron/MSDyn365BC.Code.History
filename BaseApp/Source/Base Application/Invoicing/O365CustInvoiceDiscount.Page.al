#if not CLEAN21
page 2156 "O365 Cust. Invoice Discount"
{
    AutoSplitKey = true;
    Caption = 'Customer Invoice Discount';
    PageType = List;
    SourceTable = "O365 Cust. Invoice Discount";
    SourceTableTemporary = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Minimum Amount"; Rec."Minimum Amount")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    AutoFormatExpression = '1';
                    AutoFormatType = 10;
                    ToolTip = 'Specifies the minimum amount that the invoice must total for the discount to be granted or the service charge levied. For discounts, only sales lines where the Allow Invoice Disc. field is selected are included in the calculation.';
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    ToolTip = 'Specifies the discount percentage that the customer can receive by buying for at least the minimum amount.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        UpdateCustInvDiscount();
    end;

    procedure FillO365CustInvDiscount(CustomerCode: Code[20])
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvoiceDisc.SetRange(Code, CustomerCode);
        if CustInvoiceDisc.FindSet() then
            repeat
                Rec.Init();
                Rec.Code := CustInvoiceDisc.Code;
                Rec."Line No." += 10000;
                Rec."Minimum Amount" := CustInvoiceDisc."Minimum Amount";
                Rec."Discount %" := CustInvoiceDisc."Discount %";
                Rec.Insert();
            until CustInvoiceDisc.Next() = 0;
        Rec.FilterGroup(2);
        Rec.SetRange(Code, CustomerCode);
        Rec.FilterGroup(0);
    end;

    local procedure UpdateCustInvDiscount()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvoiceDisc.SetRange(Code, Rec.Code);
        CustInvoiceDisc.DeleteAll();

        Rec.Reset();
        if Rec.FindSet() then
            repeat
                CustInvoiceDisc.Code := Rec.Code;
                CustInvoiceDisc."Minimum Amount" := Rec."Minimum Amount";
                CustInvoiceDisc."Discount %" := Rec."Discount %";
                CustInvoiceDisc.Insert();
            until Rec.Next() = 0;
    end;
}
#endif
