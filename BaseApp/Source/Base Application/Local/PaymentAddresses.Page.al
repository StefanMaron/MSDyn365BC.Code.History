page 10875 "Payment Addresses"
{
    Caption = 'Payment Address';
    DataCaptionExpression = Legend;
    PageType = List;
    SourceTable = "Payment Address";

    layout
    {
        area(content)
        {
            repeater(Control1120000)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a payment address code.';
                }
                field("Default Value"; Rec."Default Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this address is the default payment address.';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name associated with the payment address.';
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a search name.';
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the name associated with the payment address.';
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment address.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the payment address.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payer''s post code.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the payment address.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you contact about payments to this address.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payer''s country/region code.';
                }
                field(County; County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payer''s county name.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord();
    end;

    var
        Text001: Label 'Customer';
        Text002: Label 'Vendor';
        Cust: Record Customer;
        Vend: Record Vendor;
        Legend: Text[250];

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        if "Account Type" = "Account Type"::Customer then begin
            Cust.Get("Account No.");
            Legend := Text001 + ' ' + Format("Account No.") + ' ' + Cust.Name;
        end else begin
            Vend.Get("Account No.");
            Legend := Text002 + ' ' + Format("Account No.") + ' ' + Vend.Name;
        end;
    end;
}

