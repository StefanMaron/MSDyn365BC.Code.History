page 9084 "Customer Details FactBox"
{
    Caption = 'Customer Details';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = All;
                Caption = 'Customer No.';
                ToolTip = 'Specifies the number of the customer. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';
                Visible = ShowCustomerNo;

                trigger OnDrillDown()
                begin
                    ShowDetails;
                end;
            }
            field(Name; Name)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer''s name.';
            }
            field("Phone No."; "Phone No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer''s telephone number.';
            }
            field("E-Mail"; "E-Mail")
            {
                ApplicationArea = Basic, Suite;
                ExtendedDatatype = EMail;
                ToolTip = 'Specifies the customer''s email address.';
            }
            field("Fax No."; "Fax No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer''s fax number.';
            }
            field("Credit Limit (LCY)"; "Credit Limit (LCY)")
            {
                ApplicationArea = Basic, Suite;
                StyleExpr = StyleTxt;
                ToolTip = 'Specifies the maximum amount you allow the customer to exceed the payment balance before warnings are issued.';
            }
            field(AvailableCreditLCY; CalcAvailableCreditUI)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Available Credit (LCY)';
                ToolTip = 'Specifies a customer''s available credit. If the available credit is 0 and the customer''s credit limit is also 0, then the customer has unlimited credit because no credit limit has been defined.';

                trigger OnDrillDown()
                begin
                    PAGE.Run(PAGE::"Available Credit", Rec);
                end;
            }
            field("Payment Terms Code"; "Payment Terms Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
            }
            field(Contact; Contact)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the name of the person you regularly contact when you do business with this customer.';
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Actions")
            {
                Caption = 'Actions';
                Image = "Action";
                action("Ship-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ship-to Address';
                    RunObject = Page "Ship-to Address List";
                    RunPageLink = "Customer No." = FIELD("No.");
                    ToolTip = 'View the ship-to address that is specified for the customer.';
                }
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Customer),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleTxt := SetStyle;
    end;

    trigger OnInit()
    begin
        ShowCustomerNo := true;
    end;

    var
        StyleTxt: Text;
        ShowCustomerNo: Boolean;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Customer Card", Rec);
    end;

    procedure SetCustomerNoVisibility(Visible: Boolean)
    begin
        ShowCustomerNo := Visible;
    end;
}

